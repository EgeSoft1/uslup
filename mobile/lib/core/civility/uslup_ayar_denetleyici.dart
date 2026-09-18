// =============================================================================
// Üslup Ayar Denetleyicisi
// Dosya: mobile/lib/core/civility/uslup_ayar_denetleyici.dart
//
// Kullanıcının katman tercihlerini (açık/kapalı, hassasiyet, susturulan
// kategoriler) tutar. Politika mantığı burada DEĞİLDİR; `civility_core`
// içindeki `MudahalePolitikasi`dır ve orada test edilir. Bu sınıf yalnızca
// değeri tutar, dinleyicileri uyarır ve kalıcılığı dener.
//
// ── KALICILIK ─────────────────────────────────────────────────────────────
// Android'de ayar, uygulama ve klavye servisinin ortak kullandığı yerel
// `SharedPreferences` dosyasına yazılır (`MainActivity.kt`, kanal
// `uslup/ayarlar`). Klavye başka bir Flutter motorunda çalıştığı için Dart
// tarafındaki bellek paylaşılamaz; ortak dosya tek yoldur ve ağ gerektirmez.
//
// Web ve masaüstünde kanal yoktur: ayar oturum boyunca geçerlidir ve
// arayüz bunu açıkça yazar. Kalıcılık için yeni bir paket eklenmedi —
// çekirdeğin "harici bağımlılık yok" ilkesi istemcide de korunur.
//
// ── NE YAZILIR ────────────────────────────────────────────────────────────
// Yalnızca `UslupAyarlari.toMap()`: bir bool, bir ad ve kategori adları.
// Metin, geçmiş ya da kullanım kaydı yazılmaz.
// =============================================================================

import 'dart:convert';

import 'package:civility_core/civility_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UslupAyarDenetleyici extends ValueNotifier<UslupAyarlari> {
  UslupAyarDenetleyici._() : super(UslupAyarlari.varsayilan);

  static final UslupAyarDenetleyici instance = UslupAyarDenetleyici._();

  static const MethodChannel _kanal = MethodChannel('uslup/ayarlar');

  bool _kalici = false;

  /// Ayar cihazda kalıcı olarak saklanıyor mu? (Android: evet.)
  bool get kalici => _kalici;

  /// Kayıtlı ayarı okur. Kanal yoksa ya da veri bozuksa varsayılanda kalır;
  /// hiçbir durumda hata fırlatmaz.
  Future<void> yukle() async {
    try {
      final ham = await _kanal.invokeMethod<String>('oku');
      _kalici = true;
      if (ham == null || ham.isEmpty) return;
      value = UslupAyarlari.fromMap(jsonDecode(ham));
    } on MissingPluginException {
      _kalici = false;
    } catch (e) {
      debugPrint('Üslup ayarı okunamadı, varsayılan kullanılıyor: $e');
    }
  }

  /// Ayarı değiştirir ve kalıcı yere yazmayı dener.
  Future<void> guncelle(UslupAyarlari yeni) async {
    if (yeni == value) return;
    value = yeni;
    try {
      await _kanal.invokeMethod<void>('yaz', jsonEncode(yeni.toMap()));
      _kalici = true;
    } on MissingPluginException {
      _kalici = false;
    } catch (e) {
      debugPrint('Üslup ayarı yazılamadı: $e');
    }
  }

  /// Motor çözümlemesinin kullanıcıya gösterilecek hâli.
  CivilityAnalysis yansit(CivilityAnalysis analiz) =>
      MudahalePolitikasi.uygula(analiz, value);

  @visibleForTesting
  void sifirla() {
    value = UslupAyarlari.varsayilan;
  }
}
