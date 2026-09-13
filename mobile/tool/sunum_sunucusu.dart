// =============================================================================
// Sunum sunucusu — derlenmiş web sürümünü İNTERNETSİZ çalıştırır
// Dosya: mobile/tool/sunum_sunucusu.dart
//
// Kullanım (depo kökünde `SUNUMU_BASLAT.bat` bunu kendisi yapar):
//   cd mobile
//   flutter build web --release --no-web-resources-cdn
//   dart tool/sunum_sunucusu.dart            → http://127.0.0.1:8123
//
// ── NEDEN GEREKLİ ─────────────────────────────────────────────────────────
// Flutter web çıktısı `file://` ile açılamaz; tarayıcı modülleri ve yazı
// tiplerini güvenlik gereği yüklemez. Bir HTTP sunucusu şarttır ama bu
// makinede Python yok ve sunum bilgisayarında olacağı da garanti değil.
// Bu dosya yalnızca `dart:io` kullanır — Flutter kuruluysa çalışır.
//
// Sunucu YALNIZCA bu bilgisayara (127.0.0.1) açılır; ağdaki başka hiçbir
// cihaz bağlanamaz. Uçak modunda da çalışır.
// =============================================================================

import 'dart:io';

const _turler = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.ico': 'image/x-icon',
  '.frag': 'application/octet-stream',
  '.bin': 'application/octet-stream',
  '.onnx': 'application/octet-stream',
};

Future<void> main(List<String> args) async {
  final betikDizini = File.fromUri(Platform.script).parent;
  final kok = Directory(
      args.isNotEmpty ? args[0] : '${betikDizini.parent.path}/build/web');
  final kapi = args.length > 1 ? int.parse(args[1]) : 8123;

  if (!File('${kok.path}/index.html').existsSync()) {
    stderr.writeln('build/web bulunamadı. Önce şunu çalıştırın:\n'
        '  cd mobile\n'
        '  flutter build web --release --no-web-resources-cdn');
    exit(1);
  }

  final HttpServer sunucu;
  try {
    sunucu = await HttpServer.bind(InternetAddress.loopbackIPv4, kapi);
  } on SocketException {
    stderr.writeln('$kapi numaralı kapı kullanımda — sunucu zaten açık olabilir.');
    exit(2);
  }

  stdout.writeln('Üslup sunum sunucusu çalışıyor: http://127.0.0.1:$kapi');
  stdout.writeln('Kapatmak için bu pencereyi kapatın ya da Ctrl+C.');

  await for (final istek in sunucu) {
    var yol = Uri.decodeComponent(istek.uri.path);
    if (yol == '/' || yol.isEmpty) yol = '/index.html';
    if (yol.contains('..')) {
      istek.response.statusCode = HttpStatus.forbidden;
      await istek.response.close();
      continue;
    }

    var dosya = File('${kok.path}$yol');
    if (!dosya.existsSync()) dosya = File('${kok.path}/index.html');

    final nokta = dosya.path.lastIndexOf('.');
    final uzanti = nokta < 0 ? '' : dosya.path.substring(nokta);
    istek.response.headers
      ..set('Content-Type', _turler[uzanti] ?? 'application/octet-stream')
      ..set('Cache-Control', 'no-store');
    await istek.response.addStream(dosya.openRead());
    await istek.response.close();
  }
}
