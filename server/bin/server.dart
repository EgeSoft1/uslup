// =============================================================================
// Giriş Noktası
// Dosya: server/bin/server.dart
//
// Çalıştırma:
//   $env:ANTHROPIC_API_KEY = "sk-ant-..."
//   dart run bin/server.dart
// =============================================================================

import 'dart:io';

import 'package:civility_core/civility_core.dart';
import 'package:nezaket_server/src/api.dart';
import 'package:nezaket_server/src/claude_client.dart';
import 'package:nezaket_server/src/config.dart';
import 'package:nezaket_server/src/rewrite_service.dart';

Future<void> main(List<String> args) async {
  final ServerConfig config;
  try {
    config = ServerConfig.fromEnvironment(Platform.environment);
  } on ConfigError catch (e) {
    stderr.writeln(e.message);
    exitCode = 78; // EX_CONFIG
    return;
  }

  final model = ClaudeRewriteModel(
    apiKey: config.apiKey,
    model: config.model,
  );

  final api = NezaketApi(
    config: config,
    service: RewriteService(
      engine: LexicalTurkishClassifier(),
      cloud: model,
    ),
  );

  final server = await api.start();

  stdout
    ..writeln('NSosyal — Nezaket yeniden yazma servisi')
    ..writeln('  adres  : http://${server.address.host}:${server.port}')
    ..writeln('  model  : ${config.model}')
    ..writeln('  motor  : ${LexicalTurkishClassifier().modelName}')
    ..writeln('  sınır  : ${config.requestsPerMinute} istek/dk/IP')
    ..writeln('')
    ..writeln('  GET  /health')
    ..writeln('  POST /v1/rewrite   {"text": "...", "consent": true}')
    ..writeln('')
    ..writeln('Metin diske yazılmaz ve loglanmaz.');

  // Konteyner/terminal kapanışında düzgün sonlanma.
  ProcessSignal.sigint.watch().listen((_) async {
    stdout.writeln('\nKapatılıyor...');
    await api.dispose();
    await server.close(force: true);
    model.close();
    exit(0);
  });
}
