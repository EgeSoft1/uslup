package com.example.turkiye_mesajlasma

import android.inputmethodservice.InputMethodService
import android.inputmethodservice.Keyboard
import android.inputmethodservice.KeyboardView
import android.text.InputType
import android.view.HapticFeedbackConstants
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.ExtractedTextRequest
import android.widget.TextView
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

// =============================================================================
// Üslup klavyesi — katmanın uygulama DIŞINDA çalıştığı yüzey
//
// Metin çözümlemesi aynı süreçteki Flutter motorunda (`main.dart`,
// `_bindKeyboardService`) yapılır. Bu sınıf yalnızca tuşları işler, metni
// motora verir ve dönen öneriyi şeritte gösterir.
//
// ── KALDIRILANLAR (13 Eylül 2026) ─────────────────────────────────────────
// Bu dosyada üç ağ yolu vardı ve üçü de ürünün temel iddiasıyla ("metin
// cihazdan çıkmaz", "çalışma zamanında tek bir ağ çağrısı yok") çelişiyordu:
//
//   llmRewrite          yazılan metni şifresiz HTTP ile bir sunucuya POST ediyordu
//   syncToVDS           "fed-avg" uç noktasına veri gönderiyordu
//   downloadLatestModel kimlik doğrulaması olmayan HTTP'den bir ONNX modeli
//                       indirip uygulama dizinine yazıyordu
//
// Dart tarafından çağrılmıyorlardı; ama bir klavyede, çağrılmayı bekleyen
// bir metin ihracı yolu durmamalı. Onları çalıştırmak için manifestte
// INTERNET izni ve düz metin trafiği de geri eklenmişti; o da kaldırıldı ve
// `mobile/test/kapsam_degismezi_test.dart` artık bu dosyayı ve manifesti de
// tarıyor.
//
// Ayrıca "davranışsal biyometri" (tuş aralığı ve silme oranı toplayıp skora
// öfke cezası ekleyen adım) kaldırıldı — gerekçe `civility_engine.dart`.
// =============================================================================
class CivilityInputMethodService : InputMethodService(), KeyboardView.OnKeyboardActionListener {

    private lateinit var keyboardView: KeyboardView
    private lateinit var keyboard: Keyboard

    // NULLABLE, `lateinit` DEĞİL. `onStartInput` ve Flutter'dan gelen
    // `updateSuggestion` çağrıları, `onCreateInputView` çalışmadan ÖNCE de
    // gelebilir; `lateinit` bir alana o anda dokunmak
    // UninitializedPropertyAccessException ile klavyeyi düşürüyordu.
    private var suggestionStrip: TextView? = null
    private var isCaps = false

    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null
    private var currentCleanText: String? = null

    /// Şeritteki önerinin üretildiği metin. Alan bundan farklıysa öneri eskidir.
    private var currentSourceText: String? = null

    /// Bu alanda çözümleme yapılabilir mi? Parola ve gizli kip alanlarında
    /// hayır: klavye o metni motora vermez ve şeritte hiçbir şey göstermez.
    private var analysisEnabled = true

    override fun onCreate() {
        super.onCreate()

        flutterEngine = FlutterEngine(this)
        // Varsayılan `main()` değil, yalnızca motoru ve kanalı kuran `imeMain`
        // çalıştırılır (docs/24 · madde 27; gerekçe main.dart'ta).
        flutterEngine?.dartExecutor?.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "imeMain",
            )
        )

        methodChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "uslup/ime")
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "updateSuggestion") {
                showSuggestion(
                    risk = call.argument<String>("risk") ?: "temiz",
                    message = call.argument<String>("message") ?: "",
                    cleanText = call.argument<String>("cleanText"),
                    sourceText = call.argument<String>("sourceText"),
                )
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    /// Alandaki güncel metin; okunamazsa null.
    private fun currentFieldText(): String? =
        currentInputConnection
            ?.getExtractedText(ExtractedTextRequest(), 0)
            ?.text
            ?.toString()

    /// Şerit, uygulamadaki kutuyla aynı basamakta açılır: `riskli` ve üstü.
    private fun showSuggestion(
        risk: String,
        message: String,
        cleanText: String?,
        sourceText: String?,
    ) {
        val strip = suggestionStrip ?: return // görünüm henüz kurulmadı

        // Çözümleme sonucu eşzamansız gelir. Kullanıcı bu arada yazmaya devam
        // ettiyse bu sonuç ESKİ metne aittir: gösterilmez. Gösterilseydi
        // dokunmak, alanın tamamını eski metnin önerisiyle değiştirip yeni
        // yazılanları silerdi (denetim · docs/23).
        if (sourceText != null && sourceText != currentFieldText()) return

        // Kullanıcı bu arada bir parola alanına geçtiyse eski sonuç orada
        // GÖSTERİLMEZ.
        val shown = risk == "riskli" || risk == "yuksek" || risk == "destek"
        if (!analysisEnabled || !shown || message.isEmpty()) {
            currentCleanText = null
            strip.visibility = View.GONE
            return
        }

        val bg = strip.background as? android.graphics.drawable.GradientDrawable

        // Kendine zarar ifadesi: uyarı değil destek. Titreşim yok, dokunulacak
        // öneri yok, sakin renk (docs/20, D4).
        if (risk == "destek") {
            currentCleanText = null
            strip.text = "💙 $message"
            bg?.setColor(android.graphics.Color.parseColor("#E3F2FD"))
            strip.setTextColor(android.graphics.Color.parseColor("#0D47A1"))
            strip.visibility = View.VISIBLE
            return
        }

        currentCleanText = cleanText
        currentSourceText = sourceText
        strip.text = "⚠️ $message"

        if (risk == "yuksek") {
            bg?.setColor(android.graphics.Color.parseColor("#B71C1C"))
            strip.setTextColor(android.graphics.Color.WHITE)
            strip.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
        } else {
            bg?.setColor(android.graphics.Color.parseColor("#FB8C00"))
            strip.setTextColor(android.graphics.Color.BLACK)
        }
        strip.visibility = View.VISIBLE
    }

    override fun onCreateInputView(): View {
        val root = layoutInflater.inflate(R.layout.keyboard_view, null)
        keyboardView = root.findViewById(R.id.keyboard)
        val strip = root.findViewById<TextView>(R.id.civility_suggestion_strip)
        suggestionStrip = strip

        // Öneriye dokununca metin yerel olarak değiştirilir. Öneri yoksa
        // (yalnızca gerekçe gösteriliyorsa) dokunmak hiçbir şey yapmaz.
        strip.setOnClickListener {
            val textToCommit = currentCleanText
            if (!textToCommit.isNullOrEmpty()) {
                val ic = currentInputConnection
                val extracted = ic?.getExtractedText(ExtractedTextRequest(), 0)
                val fieldText = extracted?.text?.toString()

                // Öneri başka bir metin için üretildiyse alana dokunulmaz.
                val source = currentSourceText
                if (source != null && source != fieldText) {
                    strip.visibility = View.GONE
                    currentCleanText = null
                    currentSourceText = null
                    return@setOnClickListener
                }

                if (fieldText != null) {
                    ic?.deleteSurroundingText(fieldText.length, fieldText.length)
                }
                ic?.commitText(textToCommit, 1)

                strip.visibility = View.GONE
                currentCleanText = null
                currentSourceText = null
            }
        }

        keyboard = Keyboard(this, R.xml.qwerty)
        keyboardView.keyboard = keyboard
        keyboardView.setOnKeyboardActionListener(this)

        return root
    }

    override fun onStartInput(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInput(attribute, restarting)
        analysisEnabled = !isSensitiveField(attribute)
        // Yeni bir alana girildiğinde uyarıyı temizle. Bu geri çağrı,
        // `onCreateInputView`den ÖNCE de gelebilir — o yüzden null geçilir.
        suggestionStrip?.visibility = View.GONE
        currentCleanText = null
        currentSourceText = null
    }

    /// Parola alanları ve uygulamanın "kişiselleştirilmiş öğrenme yok"
    /// (gizli sekme vb.) istediği alanlar.
    private fun isSensitiveField(info: EditorInfo?): Boolean {
        if (info == null) return false
        if ((info.imeOptions and EditorInfo.IME_FLAG_NO_PERSONALIZED_LEARNING) != 0) return true

        val inputClass = info.inputType and InputType.TYPE_MASK_CLASS
        val variation = info.inputType and InputType.TYPE_MASK_VARIATION
        return when (inputClass) {
            InputType.TYPE_CLASS_TEXT ->
                variation == InputType.TYPE_TEXT_VARIATION_PASSWORD ||
                    variation == InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
                    variation == InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD
            InputType.TYPE_CLASS_NUMBER ->
                variation == InputType.TYPE_NUMBER_VARIATION_PASSWORD
            else -> false
        }
    }

    private fun checkTextWithCivilityEngine() {
        if (!analysisEnabled) return
        val ic = currentInputConnection
        val extr = ic?.getExtractedText(ExtractedTextRequest(), 0)
        val text = extr?.text?.toString() ?: return

        // Kullanıcının uygulamada seçtiği ayar (açık/kapalı, hassasiyet) her
        // çözümlemede taşınır; klavye ile uygulama aynı kuralı izler (docs/27).
        val ayarlar = getSharedPreferences(MainActivity.AYAR_DOSYASI, MODE_PRIVATE)
            .getString(MainActivity.AYAR_ANAHTARI, null)

        methodChannel?.invokeMethod("analyze", mapOf("text" to text, "ayarlar" to ayarlar))
    }

    // --- OnKeyboardActionListener methods ---
    override fun onKey(primaryCode: Int, keyCodes: IntArray?) {
        val ic = currentInputConnection ?: return

        when (primaryCode) {
            Keyboard.KEYCODE_DELETE -> {
                val selectedText = ic.getSelectedText(0)
                if (selectedText.isNullOrEmpty()) {
                    ic.deleteSurroundingText(1, 0)
                } else {
                    ic.commitText("", 1)
                }
            }
            Keyboard.KEYCODE_SHIFT -> {
                isCaps = !isCaps
                keyboard.isShifted = isCaps
                keyboardView.invalidateAllKeys()
            }
            Keyboard.KEYCODE_DONE -> {
                ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER))
            }
            else -> {
                // Tanımsız özel tuş kodları (negatif) karakter olarak YAZILMAZ;
                // `toChar()` onları anlamsız bir Unicode karakterine çevirirdi.
                if (primaryCode <= 0) return
                val code = primaryCode.toChar()
                // Türkçe büyük harf: i → İ, ı → I. `uppercaseChar()` yerel
                // ayardan bağımsızdır ve "i"yi noktasız "I" yapıyordu.
                val output = if (!isCaps) code.toString() else when (code) {
                    'i' -> "İ"
                    'ı' -> "I"
                    else -> code.uppercaseChar().toString()
                }
                ic.commitText(output, 1)

                // Tek seferlik büyük harf (docs/24 · madde 26): Shift bir harf
                // için geçerlidir. Önceki davranış kalıcı kilitti ve cümle
                // başındaki büyük harften sonra bütün metin büyük yazılıyordu.
                if (isCaps && code.isLetter()) {
                    isCaps = false
                    keyboard.isShifted = false
                    keyboardView.invalidateAllKeys()
                }
            }
        }

        // Her tuş basımında metni analiz et
        checkTextWithCivilityEngine()
    }

    override fun onPress(primaryCode: Int) {}
    override fun onRelease(primaryCode: Int) {}
    override fun onText(text: CharSequence?) {}
    override fun swipeLeft() {}
    override fun swipeRight() {}
    override fun swipeDown() {}
    override fun swipeUp() {}

    override fun onDestroy() {
        flutterEngine?.destroy()
        super.onDestroy()
    }
}
