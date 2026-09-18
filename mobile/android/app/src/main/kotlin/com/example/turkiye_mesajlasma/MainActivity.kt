package com.example.turkiye_mesajlasma

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// =============================================================================
// Ana etkinlik
//
// Tek ek görevi: kullanıcının Üslup ayarını (açık/kapalı, hassasiyet,
// susturulan kategoriler) uygulamayla klavye servisinin ORTAK kullandığı
// yerel dosyaya yazmak ve oradan okumak (docs/27).
//
// Klavye servisi kendi Flutter motorunda çalışır; Dart tarafındaki bellek
// paylaşılamaz. Aynı süreçteki `SharedPreferences` dosyası ağsız ve izinsiz
// tek ortak yoldur. Yazılan şey yalnızca ayarın JSON biçimidir — metin,
// geçmiş ya da kullanım kaydı değil.
// =============================================================================
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AYAR_KANALI)
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(AYAR_DOSYASI, Context.MODE_PRIVATE)
                when (call.method) {
                    "oku" -> result.success(prefs.getString(AYAR_ANAHTARI, null))
                    "yaz" -> {
                        prefs.edit().putString(AYAR_ANAHTARI, call.arguments as? String).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        const val AYAR_KANALI = "uslup/ayarlar"
        const val AYAR_DOSYASI = "uslup"
        const val AYAR_ANAHTARI = "ayarlar"
    }
}
