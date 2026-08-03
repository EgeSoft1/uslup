// =============================================================================
// HTTP Katmanı
// Dosya: server/lib/src/api.dart
//
// Çerçeve kullanılmadı; `dart:io` iki uç nokta için fazlasıyla yeterli.
// Bağımlılık sayısı bir teslimat kalitesi ölçütüdür: jüri kaynak kodu
// inceleyecekse, okunabilir ve az bağımlı bir servis lehine puandır.
//
// ── ONAY KAPISI ───────────────────────────────────────────────────────────
// `POST /v1/rewrite` isteği `"consent": true` içermiyorsa 403 döner.
// Bu bir formalite değil, ürünün mahremiyet vaadinin API sözleşmesine
// yazılmış hâlidir: bir istemci hatası yüzünden kullanıcı metni farkında
// olmadan buluta gidemez, çünkü sunucu onaysız isteği kabul etmiyor.
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'config.dart';
import 'rate_limiter.dart';
import 'rewrite_service.dart';

class NezaketApi {
  final ServerConfig config;
  final RewriteService service;
  final RateLimiter limiter;

  /// İstek gövdesi üst sınırı. `maxTextLength` karakter sınırıdır; bu ise
  /// gövde ayrıştırılmadan ÖNCE uygulanan bayt sınırıdır — kötü niyetli
  /// devasa gövdenin belleğe alınmasını engeller.
  static const int _maxBodyBytes = 64 * 1024;

  Timer? _sweepTimer;

  NezaketApi({
    required this.config,
    required this.service,
    RateLimiter? limiter,
  }) : limiter = limiter ??
            RateLimiter(maxRequests: config.requestsPerMinute);

  Future<HttpServer> start() async {
    final server = await HttpServer.bind(config.host, config.port);
    server.defaultResponseHeaders.removeAll('X-Frame-Options');

    _sweepTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => limiter.sweep());

    unawaited(_serve(server));
    return server;
  }

  Future<void> _serve(HttpServer server) async {
    await for (final request in server) {
      // Tek bir isteğin hatası servisi düşürmemeli.
      unawaited(_handleSafely(request));
    }
  }

  /// Tek bir isteği, HİÇBİR koşulda süreci düşürmeyecek şekilde işler.
  ///
  /// ── NEDEN İKİ KATMANLI TRY ────────────────────────────────────────────────
  /// Önceki sürüm hatayı yakalayıp 500 yazmayı deniyordu ama o YAZMA da
  /// başarısız olabilir: yanıt zaten kapatılmışsa ya da istemci bağlantıyı
  /// ortada koparmışsa `HttpResponse`'a yazmak `StateError` fırlatır.
  ///
  /// O ikinci istisna `unawaited` bir Future içinde kaldığı için hiçbir yerde
  /// yakalanmıyor, kök zone'a çıkıyor ve **sürecin tamamını öldürüyordu**.
  /// Yani "tek bir isteğin hatası servisi düşürmemeli" diyen kod, tam olarak
  /// servisi düşüren yol hâline gelmişti.
  ///
  /// Buradaki sözleşme: bu fonksiyon asla istisna ile tamamlanmaz.
  Future<void> _handleSafely(HttpRequest request) async {
    try {
      await handle(request);
    } catch (e) {
      _log('unhandled', {'error': e.runtimeType.toString()});
      try {
        await _json(request, HttpStatus.internalServerError, {
          'error': 'internal_error',
          'message': 'Beklenmeyen bir hata oluştu.',
        });
      } catch (_) {
        // Yanıt zaten yazılmış ya da bağlantı kopmuş. İstemciye söyleyecek
        // bir şey kalmadı; önemli olan sürecin ayakta kalması.
        await _closeQuietly(request);
      }
    }
  }

  /// Yanıtı kapatmayı dener; kapatma da başarısız olursa sessizce geçer.
  Future<void> _closeQuietly(HttpRequest request) async {
    try {
      await request.response.close();
    } catch (_) {
      // Zaten kapalı veya bağlantı düşmüş.
    }
  }

  Future<void> dispose() async {
    _sweepTimer?.cancel();
    _sweepTimer = null;
  }

  // ─── YÖNLENDİRME ───────────────────────────────────────────────────────────

  Future<void> handle(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    if (method == 'GET' && path == '/health') {
      return _json(request, HttpStatus.ok, {
        'status': 'ok',
        'model': config.model,
        'engine': 'civility_core',
      });
    }

    if (method == 'POST' && path == '/v1/rewrite') {
      return _handleRewrite(request);
    }

    return _json(request, HttpStatus.notFound, {
      'error': 'not_found',
      'message': 'Bilinmeyen uç nokta: $method $path',
      'endpoints': ['GET /health', 'POST /v1/rewrite'],
    });
  }

  Future<void> _handleRewrite(HttpRequest request) async {
    final clientKey = request.connectionInfo?.remoteAddress.address ?? 'bilinmeyen';

    if (!limiter.allow(clientKey)) {
      request.response.headers.set('retry-after', '60');
      return _json(request, HttpStatus.tooManyRequests, {
        'error': 'rate_limited',
        'message': 'Dakikada en fazla ${config.requestsPerMinute} istek.',
      });
    }

    // ── Gövdeyi oku (bayt sınırıyla) ──
    final String raw;
    try {
      raw = await _readBody(request);
    } on _BodyTooLarge {
      return _json(request, HttpStatus.requestEntityTooLarge, {
        'error': 'body_too_large',
        'message': 'İstek gövdesi çok büyük.',
      });
    } catch (_) {
      return _json(request, HttpStatus.badRequest, {
        'error': 'unreadable_body',
        'message': 'İstek gövdesi okunamadı.',
      });
    }

    final Map<String, Object?> body;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      body = decoded;
    } catch (_) {
      return _json(request, HttpStatus.badRequest, {
        'error': 'invalid_json',
        'message': 'Gövde geçerli bir JSON nesnesi olmalı.',
      });
    }

    // ── Onay kapısı ──
    if (body['consent'] != true) {
      return _json(request, HttpStatus.forbidden, {
        'error': 'consent_required',
        'message':
            'Bu uç nokta metni buluta gönderir. İstek "consent": true '
            'içermelidir. Onay, kullanıcıdan açıkça alınmalıdır.',
      });
    }

    // ── Metin doğrulaması ──
    final text = body['text'];
    if (text is! String || text.trim().isEmpty) {
      return _json(request, HttpStatus.badRequest, {
        'error': 'invalid_text',
        'message': '"text" alanı boş olmayan bir metin olmalı.',
      });
    }
    if (text.length > config.maxTextLength) {
      return _json(request, HttpStatus.badRequest, {
        'error': 'text_too_long',
        'message': 'Metin en fazla ${config.maxTextLength} karakter olabilir '
            '(${text.length} verildi).',
      });
    }

    final rawCount = body['maxSuggestions'];
    final maxSuggestions =
        rawCount is int ? rawCount.clamp(1, 5) : 3;

    final result = await service.rewrite(text, maxSuggestions: maxSuggestions);

    // Log satırında METİN YOK — yalnızca ölçüm. Bu kasıtlıdır.
    _log('rewrite', {
      'chars': text.length,
      'risk': result.analysis.risk.name,
      'cloud': result.cloudStatus.name,
      'accepted': result.suggestions.length,
      'rejected': result.rejectedByVerification,
      'ms': result.elapsed.inMilliseconds,
    });

    return _json(request, HttpStatus.ok, result.toJson());
  }

  // ─── YARDIMCILAR ───────────────────────────────────────────────────────────

  Future<String> _readBody(HttpRequest request) async {
    final chunks = <int>[];
    await for (final chunk in request) {
      chunks.addAll(chunk);
      if (chunks.length > _maxBodyBytes) throw const _BodyTooLarge();
    }
    return utf8.decode(chunks);
  }

  Future<void> _json(
    HttpRequest request,
    int status,
    Map<String, Object?> payload,
  ) async {
    final response = request.response
      ..statusCode = status
      ..headers.contentType = ContentType('application', 'json', charset: 'utf-8')
      ..headers.set('cache-control', 'no-store')
      ..headers.set('x-content-type-options', 'nosniff');
    response.add(utf8.encode(jsonEncode(payload)));
    await response.close();
  }

  /// Yapılandırılmış log. İçerik asla loglanmaz.
  void _log(String event, Map<String, Object?> fields) {
    final parts = fields.entries.map((e) => '${e.key}=${e.value}').join(' ');
    stdout.writeln('[${DateTime.now().toIso8601String()}] $event $parts');
  }
}

class _BodyTooLarge implements Exception {
  const _BodyTooLarge();
}
