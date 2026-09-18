// =============================================================================
// Sürüm tutarlılığı
// Dosya: packages/civility_core/test/surum_test.dart
//
// Sürüm üç yerde yazılıdır: pubspec.yaml, lib/src/surum.dart ve CHANGELOG.md.
// Biri güncellenip diğeri unutulursa jüriye ya da bir entegratöre yanlış
// sürüm söylenir. Bu test üçünü karşılaştırır ve her sürümün bir ölçüm
// bölümü taşıdığını denetler.
// =============================================================================

import 'dart:io';

import 'package:civility_core/civility_core.dart';
import 'package:test/test.dart';

void main() {
  final semver = RegExp(r'^\d+\.\d+\.\d+$');

  test('sürüm anlamsal sürüm biçimindedir', () {
    expect(semver.hasMatch(CivilityCoreSurum.surum), isTrue);
  });

  test('pubspec.yaml sürümü sabitle aynı', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final m = RegExp(r'^version:\s*([0-9.]+)', multiLine: true).firstMatch(pubspec);
    expect(m, isNotNull);
    expect(m!.group(1), CivilityCoreSurum.surum);
  });

  test('CHANGELOG ilk sürüm başlığı sabitle aynı', () {
    final changelog = File('CHANGELOG.md').readAsStringSync();
    final ilk = RegExp(r'^## (\d+\.\d+\.\d+)', multiLine: true).firstMatch(changelog);
    expect(ilk, isNotNull, reason: 'CHANGELOG.md sürüm başlığı içermiyor.');
    expect(ilk!.group(1), CivilityCoreSurum.surum);
  });

  test('her sürüm bir ölçüm bölümü taşır (en yenisi için zorunlu)', () {
    final changelog = File('CHANGELOG.md').readAsStringSync();
    final bolumler = changelog.split(RegExp(r'^## ', multiLine: true)).skip(1);
    final enYeni = bolumler.first;
    expect(enYeni.contains('### Ölçüm'), isTrue,
        reason: 'Bir sınıflandırıcı sürümünün davranış farkı yazılmalı.');
  });
}
