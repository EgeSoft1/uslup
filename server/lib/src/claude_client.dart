// =============================================================================
// Anthropic Messages API İstemcisi
// Dosya: server/lib/src/claude_client.dart
//
// Dart için resmî Anthropic SDK'sı bulunmadığından REST uç noktası doğrudan
// çağrılır: POST https://api.anthropic.com/v1/messages
//
// ── ÜÇ TASARIM KARARI ─────────────────────────────────────────────────────
//
// 1. YAPILANDIRILMIŞ ÇIKTI (`output_config.format`)
//    Model serbest metin değil, şemaya UYMAK ZORUNDA olduğu JSON döndürür.
//    Böylece "İşte önerileriniz:" gibi giriş cümlelerini ayıklamaya,
//    kırılgan metin ayrıştırmaya gerek kalmaz. Şemaya uymayan çıktı
//    üretilemez — ayrıştırma hatası sınıfı tamamen ortadan kalkar.
//
// 2. DÜŞÜNME KAPALI + DÜŞÜK EFOR
//    Bu bir muhakeme görevi değil, kısıtlı bir yeniden yazma görevidir.
//    Kullanıcı gönder tuşuna basmadan önce bekliyor; gecikme ürünün
//    kendisidir. Şema kısıtı, düşünmenin kapalı olmasının bilinen yan
//    etkisini (yanıta iç etiket sızması) zaten engelliyor.
//
// 3. GERİ DÜŞME (`fallbacks: "default"`)
//    Bu servise TANIMI GEREĞİ saldırgan metin gider. Güvenlik
//    sınıflandırıcısının böyle bir isteği reddetmesi olasıdır ve reddedilen
//    istek HTTP 200 + `stop_reason: "refusal"` olarak döner — hata olarak
//    değil. Geri düşme açık olduğunda API isteği aynı çağrı içinde başka bir
//    modele yönlendirir; olmadığında istek sessizce boş döner.
// =============================================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

// ─── SONUÇ TİPLERİ ───────────────────────────────────────────────────────────

/// Modelin ürettiği tek bir yeniden yazma önerisi.
class LlmSuggestion {
  /// Önerilen yeni metin.
  final String text;

  /// Neden bu öneri — kullanıcıya şeffaflık için gösterilir.
  final String rationale;

  const LlmSuggestion({required this.text, required this.rationale});
}

/// Model çağrısının sonucu. Sealed: çağıran taraf her durumu ele almak
/// ZORUNDA — sessizce yutulan bir hata durumu bırakılamaz.
sealed class LlmOutcome {
  const LlmOutcome();
}

/// Başarılı. [servedBy] gerçekten yanıtı üreten model — geri düşme
/// devreye girdiyse istenen modelden farklı olabilir.
class LlmProposed extends LlmOutcome {
  final List<LlmSuggestion> suggestions;
  final String servedBy;
  const LlmProposed({required this.suggestions, required this.servedBy});
}

/// Güvenlik sınıflandırıcısı isteği reddetti. Hata DEĞİLDİR — beklenen bir
/// sonuçtur ve kullanıcıya "bulut önerisi üretilemedi" olarak yansır;
/// cihaz üzerindeki yerel öneri yine de sunulur.
class LlmRefused extends LlmOutcome {
  final String? category;
  const LlmRefused(this.category);
}

/// Servis geçici veya kalıcı olarak kullanılamadı.
class LlmUnavailable extends LlmOutcome {
  final String reason;

  /// Aynı isteğin sonradan tekrar denenmesi anlamlı mı?
  final bool retryable;
  const LlmUnavailable(this.reason, {required this.retryable});
}

// ─── SÖZLEŞME ────────────────────────────────────────────────────────────────

/// Yeniden yazma sağlayıcısı sözleşmesi.
///
/// Soyut olması testler içindir: `RewriteService` testleri ağ olmadan,
/// API anahtarı olmadan ve deterministik biçimde çalışır.
abstract class RewriteModel {
  Future<LlmOutcome> propose(String text, {required int maxSuggestions});
  String get modelName;
}

// ─── SİSTEM İSTEMİ ───────────────────────────────────────────────────────────

/// Ürünün asıl fikrî değeri burada.
///
/// Kritik nokta: model bir SANSÜRCÜ değildir. Kullanıcının eleştirisi,
/// öfkesi ve niyeti korunur; yalnızca SALDIRI çıkarılır. "Sakin ol" diyen
/// veya kullanıcıya ahlak dersi veren bir çıktı ürünün başarısızlığıdır —
/// kullanıcı böyle bir aracı ikinci kez kullanmaz.
const String _systemPrompt = '''
Türkçe bir sosyal medya uygulamasının nezaket asistanısın. Kullanıcı öfkeli
bir gönderi yazdı ve göndermeden önce senden daha iyi bir ifade istedi.

GÖREVİN: Aynı ELEŞTİRİYİ, aynı ŞİDDETTE, ama SALDIRMADAN söyleyen
alternatifler üret.

MUTLAKA KORU:
- Kullanıcının asıl iddiası ve eleştirisi. İçeriği yumuşatma, sadece
  saldırıyı çıkar.
- Duygunun şiddeti. Öfkeli bir cümle öfkeli kalabilir; hakaret olmadan da
  sert olunur.
- Hitap biçimi (sen/siz) ve kullanıcının genel üslubu.
- Uzunluk. Öneri, orijinalden belirgin biçimde uzun olmasın.

ASLA YAPMA:
- Kullanıcıya ahlak dersi verme, "sakin ol" deme, davranışını yorumlama.
- Kullanıcının söylemediği bir iddiayı ekleme.
- Eleştiriyi övgüye veya nötr bir gözleme çevirme. "Katılmıyorum" demek
  yeterli değildir; NEDEN katılmadığı korunmalıdır.
- Özür diletme. Kullanıcı özür dilemek istemiyor, derdini anlatmak istiyor.
- Yanıtına iç veya sistem XML etiketi koyma.

ÜRETİM KURALI: İstenen sayıda öneri üret ve her biri FARKLI bir tonda olsun
(örneğin: doğrudan/sert, açıklayıcı/gerekçeli, kısa/soğuk).

ÖRNEKLER:

Girdi: "bu ne biçim aptalca bir karar, salaklar"
İyi öneri: "Bu karar bence yanlış ve nedenini anlamıyorum."
İyi öneri: "Bu kararın arkasındaki mantığı göremiyorum, açıklanmasını
istiyorum."
Kötü öneri: "Bu karara katılmıyorum." (eleştiri buharlaştı, neden yok)
Kötü öneri: "Karar hakkında farklı düşünenler olabilir." (kullanıcı bunu
demedi)

Girdi: "gerizekalı mısın sen, kaç kere anlattım"
İyi öneri: "Bunu birkaç kez anlattım ve hâlâ anlaşılmamış olması beni
yordu."
Kötü öneri: "Sanırım bir yanlış anlaşılma var." (öfke silindi)

Girdi: "yıllardır aynı hatayı yapıyorsunuz, beceriksizsiniz"
İyi öneri: "Bu hata yıllardır tekrarlanıyor ve düzeltilmemesi kabul
edilebilir değil."
''';

// ─── ÇIKTI ŞEMASI ────────────────────────────────────────────────────────────

/// Modelin uymak zorunda olduğu JSON şeması.
///
/// Not: `minItems` / `maxItems` yapılandırılmış çıktı tarafından
/// desteklenmez; öneri sayısı istem içinde belirtilir ve servis tarafında
/// kırpılır.
const Map<String, Object?> _outputSchema = {
  'type': 'object',
  'properties': {
    'suggestions': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'text': {
            'type': 'string',
            'description': 'Önerilen yeni metin, Türkçe.',
          },
          'rationale': {
            'type': 'string',
            'description':
                'Bu önerinin neyi değiştirdiği, tek cümle, Türkçe.',
          },
        },
        'required': ['text', 'rationale'],
        'additionalProperties': false,
      },
    },
  },
  'required': ['suggestions'],
  'additionalProperties': false,
};

// ─── İSTEMCİ ─────────────────────────────────────────────────────────────────

class ClaudeRewriteModel implements RewriteModel {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _apiVersion = '2023-06-01';

  /// Geri düşme parametresinin `"default"` biçimini açan beta bayrağı.
  static const _fallbackBeta = 'server-side-fallback-2026-07-01';

  final String _apiKey;
  final String _model;
  final http.Client _http;
  final Duration _timeout;

  ClaudeRewriteModel({
    required String apiKey,
    required String model,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 30),
  })  : _apiKey = apiKey,
        _model = model,
        _http = httpClient ?? http.Client(),
        _timeout = timeout;

  @override
  String get modelName => _model;

  void close() => _http.close();

  @override
  Future<LlmOutcome> propose(
    String text, {
    required int maxSuggestions,
  }) async {
    final body = jsonEncode({
      'model': _model,
      'max_tokens': 1024,

      // Muhakeme değil, kısıtlı yeniden yazma görevi — gecikme önemli.
      'thinking': {'type': 'disabled'},

      'output_config': {
        'effort': 'low',
        'format': {'type': 'json_schema', 'schema': _outputSchema},
      },

      // Reddedilen istek başka bir modele yönlendirilsin.
      'fallbacks': 'default',

      // Sistem istemi her istekte aynıdır → önbelleğe alınır. İlk istekten
      // sonra bu bölüm ~%90 daha ucuza işlenir.
      'system': [
        {
          'type': 'text',
          'text': _systemPrompt,
          'cache_control': {'type': 'ephemeral'},
        }
      ],

      'messages': [
        {
          'role': 'user',
          'content': 'Tam olarak $maxSuggestions öneri üret.\n\n'
              'Girdi: $text',
        }
      ],
    });

    late http.Response response;
    try {
      response = await _http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'content-type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': _apiVersion,
              'anthropic-beta': _fallbackBeta,
            },
            body: utf8.encode(body),
          )
          .timeout(_timeout);
    } catch (e) {
      // Ağ hatası / zaman aşımı. Metin loglanmaz — yalnızca hata tipi.
      return LlmUnavailable(
        'Modele ulaşılamadı: ${e.runtimeType}',
        retryable: true,
      );
    }

    return _interpret(response);
  }

  /// HTTP yanıtını sonuç tipine çevirir.
  LlmOutcome _interpret(http.Response response) {
    if (response.statusCode != 200) {
      return _mapError(response);
    }

    final Map<String, Object?> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
    } catch (_) {
      return const LlmUnavailable(
        'Model yanıtı çözümlenemedi.',
        retryable: false,
      );
    }

    // ÖNCE stop_reason. `content` doğrudan okunursa reddedilen istekte
    // dizi boş olduğu için kod patlar — bu, atlanması çok kolay bir tuzak.
    final stopReason = json['stop_reason'] as String?;
    if (stopReason == 'refusal') {
      final details = json['stop_details'] as Map<String, Object?>?;
      return LlmRefused(details?['category'] as String?);
    }
    if (stopReason == 'max_tokens') {
      return const LlmUnavailable(
        'Model yanıtı sınıra takıldı, çıktı eksik.',
        retryable: false,
      );
    }

    final content = json['content'] as List<Object?>? ?? const [];
    final textBlock = content
        .whereType<Map<String, Object?>>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String?)
        .firstWhere((t) => t != null && t.trim().isNotEmpty, orElse: () => null);

    if (textBlock == null) {
      return const LlmUnavailable(
        'Model boş yanıt döndürdü.',
        retryable: true,
      );
    }

    final parsed = _parseSuggestions(textBlock);
    if (parsed == null) {
      return const LlmUnavailable(
        'Model yanıtı beklenen şemaya uymuyor.',
        retryable: false,
      );
    }

    return LlmProposed(
      suggestions: parsed,
      // Geri düşme devreye girmişse bu, istenen modelden farklıdır.
      servedBy: json['model'] as String? ?? _model,
    );
  }

  /// Şema garantili JSON'u ayrıştırır. Garantiye rağmen savunmacı
  /// davranılır: `null` dönüşü çağıranda düzgün ele alınır.
  List<LlmSuggestion>? _parseSuggestions(String raw) {
    try {
      final decoded = jsonDecode(raw) as Map<String, Object?>;
      final items = decoded['suggestions'] as List<Object?>?;
      if (items == null) return null;

      final result = <LlmSuggestion>[];
      for (final item in items.whereType<Map<String, Object?>>()) {
        final text = (item['text'] as String?)?.trim();
        if (text == null || text.isEmpty) continue;
        result.add(LlmSuggestion(
          text: text,
          rationale: (item['rationale'] as String?)?.trim() ?? '',
        ));
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  LlmOutcome _mapError(http.Response response) {
    final code = response.statusCode;

    // API hata gövdesinden tipi çıkarmaya çalış; başarısız olursa koda düş.
    String? apiType;
    try {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
      apiType = (json['error'] as Map<String, Object?>?)?['type'] as String?;
    } catch (_) {
      // Gövde JSON değil — kod tek başına yeterli.
    }

    return switch (code) {
      400 => LlmUnavailable(
          'İstek reddedildi (${apiType ?? 'invalid_request_error'}).',
          retryable: false,
        ),
      401 || 403 => const LlmUnavailable(
          'API anahtarı geçersiz veya yetkisiz.',
          retryable: false,
        ),
      404 => LlmUnavailable(
          'Model bulunamadı: $_model',
          retryable: false,
        ),
      413 => const LlmUnavailable('İstek çok büyük.', retryable: false),
      429 => const LlmUnavailable(
          'Hız sınırı aşıldı.',
          retryable: true,
        ),
      _ => LlmUnavailable(
          code >= 500
              ? 'Model servisi geçici olarak kullanılamıyor ($code).'
              : 'Beklenmeyen yanıt ($code).',
          retryable: code >= 500,
        ),
    };
  }
}
