// =============================================================================
// Bulut Kademesi İstemcisi — `POST /v1/rewrite`
// Dosya: mobile/lib/core/network/rewrite_api_client.dart
//
// Ürünün üç kademeli yeniden yazma akışının SON halkası. İlk iki kademe
// (tespit ve yerel öneri) cihazda çalışır ve ağ gerektirmez; bu istemci
// yalnızca kullanıcı AÇIKÇA istediğinde devreye girer.
//
// ── TASARIM KARARI: HATA YOK, SONUÇ VAR ───────────────────────────────────
// Bu sınıf istisna FIRLATMAZ. Ağ kopukluğu, zaman aşımı, bozuk yanıt,
// sunucunun kapalı olması — hepsi `CloudStatus.kullanilamadi` olarak döner.
//
// Gerekçe ürünün kendisidir: bulut kademesi bir EKLENTİDİR, bağımlılık
// değil. Sunucu kapalıyken kullanıcı yerel öneriyi görmeye devam etmeli ve
// arayüzde hiçbir şey kırılmamalı. Çağıran tarafta `try/catch` unutulması
// diye bir hata sınıfı bırakmıyoruz.
//
// ── ONAY ───────────────────────────────────────────────────────────────────
// Sunucu `consent: true` içermeyen isteği 403 ile reddeder. Bu istemci de
// onayı parametre olarak ZORUNLU tutar; varsayılanı yoktur. Böylece "onay
// almayı unutmak" derleme hatası olur, çalışma zamanı sürprizi değil.
// =============================================================================

import 'package:dio/dio.dart';

/// Bulut kademesinin sonucu — sunucunun `cloud.status` alanıyla birebir.
enum CloudStatus {
  /// Bulut çağrıldı ve doğrulanmış öneri üretti.
  basarili,

  /// Metin zaten temizdi; sunucu buluta hiç gitmedi.
  gereksiz,

  /// Model güvenlik nedeniyle isteği reddetti.
  reddedildi,

  /// Sunucuya veya modele ulaşılamadı.
  kullanilamadi,

  /// Model yanıt verdi ama hiçbir öneri doğrulama kapısını geçemedi.
  dogrulamadaElendi,
}

extension CloudStatusInfo on CloudStatus {
  /// Kullanıcıya gösterilecek kısa etiket.
  String get label => switch (this) {
        CloudStatus.basarili => 'Bulut önerisi hazır',
        CloudStatus.gereksiz => 'Metin zaten temiz',
        CloudStatus.reddedildi => 'Model yanıt vermedi',
        CloudStatus.kullanilamadi => 'Sunucuya ulaşılamadı',
        CloudStatus.dogrulamadaElendi => 'Öneriler doğrulamayı geçemedi',
      };

  /// Bu durumda yeniden denemek anlamlı mı?
  bool get retryable =>
      this == CloudStatus.kullanilamadi || this == CloudStatus.reddedildi;
}

/// Sunucudan dönen, motordan geçmiş tek bir öneri.
class CloudSuggestion {
  final String text;

  /// `cihaz` veya `bulut` — kullanıcı önerinin nereden geldiğini görür.
  final String source;

  final String rationale;

  /// Motorun öneri ÜZERİNDE ölçtüğü nezaket puanı. Tahmin değil, ölçüm.
  final int civilityScore;

  const CloudSuggestion({
    required this.text,
    required this.source,
    required this.rationale,
    required this.civilityScore,
  });

  bool get isFromCloud => source == 'bulut';

  /// Şemaya uymayan öğe için `null` döner; çağıran taraf onu atar.
  static CloudSuggestion? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['text'];
    if (text is! String || text.trim().isEmpty) return null;

    final score = raw['civilityScore'];
    return CloudSuggestion(
      text: text.trim(),
      source: raw['source'] is String ? raw['source'] as String : 'bulut',
      rationale: raw['rationale'] is String ? raw['rationale'] as String : '',
      civilityScore: score is int ? score.clamp(0, 100) : 0,
    );
  }
}

/// `POST /v1/rewrite` çağrısının tam sonucu.
class CloudRewriteResult {
  final List<CloudSuggestion> suggestions;
  final CloudStatus status;

  /// İnsan-okunur açıklama — arayüzde olduğu gibi gösterilebilir.
  final String? detail;

  /// Yanıtı fiilen üreten model. Geri düşme devreye girdiyse istenenden
  /// farklıdır; şeffaflık panelinde gösterilir.
  final String? servedBy;

  /// Doğrulama kapısından dönen öneri sayısı — ölçülebilir kalite metriği.
  final int rejectedByVerification;

  const CloudRewriteResult({
    required this.suggestions,
    required this.status,
    this.detail,
    this.servedBy,
    this.rejectedByVerification = 0,
  });

  /// Yalnızca bulut kaynaklı öneriler. Yerel öneriyi arayüz zaten
  /// cihaz üzerinde üretiyor; onu ikinci kez göstermek kafa karıştırır.
  List<CloudSuggestion> get cloudOnly =>
      suggestions.where((s) => s.isFromCloud).toList();

  /// Ağ/sunucu erişilemediğinde üretilen sonuç.
  factory CloudRewriteResult.unavailable(String reason) => CloudRewriteResult(
        suggestions: const [],
        status: CloudStatus.kullanilamadi,
        detail: reason,
      );

  /// Sunucu yanıtını çözümler. Saf fonksiyon — ağ olmadan test edilebilir.
  ///
  /// Savunmacı davranır: `cloud` bloğu eksikse veya `status` tanınmıyorsa
  /// `kullanilamadi` varsayılır. Sunucu sürümü ilerlerse istemci çökmez.
  factory CloudRewriteResult.fromJson(Map<Object?, Object?> json) {
    final cloud = json['cloud'];
    final cloudMap = cloud is Map ? cloud : const {};

    final statusName = cloudMap['status'];
    final status = CloudStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => CloudStatus.kullanilamadi,
    );

    final rawSuggestions = json['suggestions'];
    final suggestions = <CloudSuggestion>[];
    if (rawSuggestions is List) {
      for (final item in rawSuggestions) {
        final parsed = CloudSuggestion.tryParse(item);
        if (parsed != null) suggestions.add(parsed);
      }
    }

    final rejected = cloudMap['rejectedByVerification'];

    return CloudRewriteResult(
      suggestions: suggestions,
      status: status,
      detail: cloudMap['detail'] is String ? cloudMap['detail'] as String : null,
      servedBy:
          cloudMap['servedBy'] is String ? cloudMap['servedBy'] as String : null,
      rejectedByVerification: rejected is int ? rejected : 0,
    );
  }
}

// ─── İSTEMCİ ─────────────────────────────────────────────────────────────────

class RewriteApiClient {
  /// Derleme zamanında verilir:
  ///   flutter run --dart-define=NEZAKET_API=http://192.168.1.20:8080
  ///
  /// Varsayılan `10.0.2.2`, Android emülatöründe ana makinenin localhost'udur.
  /// Gerçek cihazda demo yapılacaksa makinenin LAN adresi verilmelidir.
  static const String defaultBaseUrl = String.fromEnvironment(
    'NEZAKET_API',
    defaultValue: 'http://10.0.2.2:8080',
  );

  final Dio _dio;

  RewriteApiClient({String? baseUrl, Dio? dio, Duration? timeout})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? defaultBaseUrl,
              connectTimeout: timeout ?? const Duration(seconds: 5),
              receiveTimeout: timeout ?? const Duration(seconds: 20),
              // Hata durumlarını da yanıt olarak alıp kendimiz eşleyelim;
              // Dio'nun istisna fırlatmasına gerek yok.
              validateStatus: (_) => true,
              contentType: 'application/json',
            )),
        _timeout = timeout ?? const Duration(seconds: 20);

  final Duration _timeout;

  /// Sunucu ayakta mı? Demo öncesi hızlı kontrol için.
  Future<bool> healthy() async {
    try {
      final res = await _dio.get<Object?>('/health').timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Metni bulut kademesine gönderir.
  ///
  /// [consent] kullanıcıdan AÇIKÇA alınmış olmalıdır. `false` verilirse istek
  /// hiç yapılmaz — sunucuyu 403 döndürmeye zorlamak yerine burada duruyoruz,
  /// çünkü metnin cihazdan çıkmaması gereken durum tam olarak budur.
  Future<CloudRewriteResult> rewrite({
    required String text,
    required bool consent,
    int maxSuggestions = 3,
  }) async {
    if (!consent) {
      return CloudRewriteResult.unavailable(
        'Onay verilmedi; metin cihazdan çıkmadı.',
      );
    }
    if (text.trim().isEmpty) {
      return CloudRewriteResult.unavailable('Gönderilecek metin yok.');
    }

    try {
      final res = await _dio
          .post<Object?>(
            '/v1/rewrite',
            data: {
              'text': text,
              'consent': true,
              'maxSuggestions': maxSuggestions,
            },
          )
          .timeout(_timeout);

      final code = res.statusCode ?? 0;
      if (code == 200) {
        final data = res.data;
        if (data is Map<Object?, Object?>) {
          return CloudRewriteResult.fromJson(data);
        }
        return CloudRewriteResult.unavailable('Sunucu yanıtı çözümlenemedi.');
      }
      return CloudRewriteResult.unavailable(_describeError(code, res.data));
    } catch (_) {
      // Ağ yok, DNS hatası, zaman aşımı, TLS sorunu — kullanıcı için hepsi
      // aynı şey: bulut kademesi şu an yok. Yerel öneri geçerliliğini korur.
      return CloudRewriteResult.unavailable(
        'Sunucuya ulaşılamadı. Cihaz üzerindeki öneri geçerliliğini koruyor.',
      );
    }
  }

  /// HTTP hata kodunu kullanıcı diline çevirir.
  String _describeError(int code, Object? body) {
    final message = body is Map && body['message'] is String
        ? body['message'] as String
        : null;

    return switch (code) {
      400 => message ?? 'İstek geçersiz.',
      403 => 'Sunucu onay olmadan istek kabul etmiyor.',
      413 => 'Metin çok uzun.',
      429 => 'Çok fazla istek gönderildi; biraz bekleyin.',
      >= 500 => 'Sunucu geçici olarak hizmet veremiyor ($code).',
      _ => message ?? 'Beklenmeyen yanıt ($code).',
    };
  }

  void close() => _dio.close(force: true);
}
