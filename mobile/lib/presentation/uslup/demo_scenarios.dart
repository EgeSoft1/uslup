// =============================================================================
// Jüri demo senaryoları — tek kaynak
// Dosya: mobile/lib/presentation/uslup/demo_scenarios.dart
//
// ── NEDEN AYRI DOSYA ──────────────────────────────────────────────────────
// Aynı liste iki yerde kullanılıyor: yazım kutusundaki senaryo çipleri ve
// Üslup panelindeki bağlam karnesi. Liste bir yerde elle kopyalansaydı iki
// ekran er ya da geç farklı cümleler gösterirdi.
//
// ── NEDEN BEKLENTİ DE YAZILI ──────────────────────────────────────────────
// Her senaryonun BEKLENEN kararı (`expectFlag`) motor çalışmadan önce
// yazılmıştır. Ekran, motorun gerçek sonucunu bu beklentiyle yan yana
// koyar. Jüri "doğru çıktı" sözüne güvenmek zorunda kalmaz; beklentiyi ve
// sonucu aynı satırda görür.
// =============================================================================

import 'package:flutter/foundation.dart';

@immutable
class DemoScenario {
  const DemoScenario({
    required this.label,
    required this.text,
    required this.expectation,
    required this.expectFlag,
  });

  /// Çipte görünen kısa ad.
  final String label;

  /// Kutuya yüklenen cümle.
  final String text;

  /// Beklenen davranışın insan-okunur açıklaması.
  final String expectation;

  /// Motorun bu cümleyi işaretlemesi bekleniyor mu?
  final bool expectFlag;
}

/// Sıra kasıtlıdır: ilk dördü AYNI kelimeyi dört bağlamda gösterir; sunumun
/// ayrıştığı an budur.
const List<DemoScenario> demoScenarios = [
  DemoScenario(
    label: 'Doğrudan saldırı',
    text: 'Sen tam bir aptalsın',
    expectation: 'saldırı sayılır',
    expectFlag: true,
  ),
  DemoScenario(
    label: 'Olumsuzlama',
    text: 'Sen hiç aptal değilsin',
    expectation: 'iltifat — işaretlenmez',
    expectFlag: false,
  ),
  DemoScenario(
    label: 'Mağdur anlatısı',
    text: 'Bana "aptal" dedi, çok üzüldüm',
    expectation: 'şikâyet eden susturulmaz',
    expectFlag: false,
  ),
  DemoScenario(
    label: 'Öz-ifade',
    text: 'Kendimi çok aptal hissettim',
    expectation: 'kişinin kendisi — işaretlenmez',
    expectFlag: false,
  ),
  DemoScenario(
    label: 'Küfürsüz düşmanlık',
    text: 'Senin gibilerden zaten bu beklenirdi',
    expectation: 'örüntü katmanı yakalar',
    expectFlag: true,
  ),
  DemoScenario(
    label: 'Gizleme denemesi',
    text: r'sen $3r3fsizsin',
    expectation: 'normalizasyon çözer',
    expectFlag: true,
  ),
  DemoScenario(
    label: 'Deyimle aşağılama',
    text: 'Takke düştü kel göründü',
    expectation: 'deyim katmanı yakalar',
    expectFlag: true,
  ),
  DemoScenario(
    label: 'Kimlik beyanı',
    text: 'Ben Kürtüm ve bununla gurur duyuyorum',
    expectation: 'kimlik adı tetikleyici değil',
    expectFlag: false,
  ),
  DemoScenario(
    label: 'Nefret söylemi',
    text: 'Bütün Suriyeliler hırsızdır',
    expectation: 'yuva + düşmanca kuruluş',
    expectFlag: true,
  ),
  DemoScenario(
    label: 'Sert ama meşru',
    text: 'Bu karar bence tamamen hatalı ve geri alınmalı',
    expectation: 'eleştiri sansürlenmez',
    expectFlag: false,
  ),
  DemoScenario(
    label: 'Tehdit',
    text: 'Seni gebertirim',
    expectation: 'gönderim öncesi onay istenir',
    expectFlag: true,
  ),
  DemoScenario(
    label: 'Masum tuzak',
    text: 'Şikayet dilekçemi götürdüm, dayanışma ağı büyüyor',
    expectation: '"şik", "göt", "ak" geçer — işaretlenmez',
    expectFlag: false,
  ),
];
