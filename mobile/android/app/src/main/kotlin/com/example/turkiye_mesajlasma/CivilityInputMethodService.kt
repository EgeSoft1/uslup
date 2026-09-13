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

    /// Bu alanda çözümleme yapılabilir mi? Parola ve gizli kip alanlarında
    /// hayır: klavye o metni motora vermez ve şeritte hiçbir şey göstermez.
    private var analysisEnabled = true

    override fun onCreate() {
        super.onCreate()

        flutterEngine = FlutterEngine(this)
        flutterEngine?.dartExecutor?.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        methodChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "uslup/ime")
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "updateSuggestion") {
                showSuggestion(
                    risk = call.argument<String>("risk") ?: "temiz",
                    message = call.argument<String>("message") ?: "",
                    cleanText = call.argument<String>("cleanText"),
                )
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    /// Şerit, uygulamadaki kutuyla aynı basamakta açılır: `riskli` ve üstü.
    private fun showSuggestion(risk: String, message: String, cleanText: String?) {
        val strip = suggestionStrip ?: return // görünüm henüz kurulmadı

        // Çözümleme sonucu eşzamansız gelir. Kullanıcı bu arada bir parola
        // alanına geçtiyse eski sonuç orada GÖSTERİLMEZ.
        if (!analysisEnabled || (risk != "riskli" && risk != "yuksek") || message.isEmpty()) {
            currentCleanText = null
            strip.visibility = View.GONE
            return
        }

        currentCleanText = cleanText
        strip.text = "⚠️ $message"

        val bg = strip.background as? android.graphics.drawable.GradientDrawable
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
                if (extracted != null && extracted.text != null) {
                    ic?.deleteSurroundingText(extracted.text.length, extracted.text.length)
                }
                ic?.commitText(textToCommit, 1)

                strip.visibility = View.GONE
                currentCleanText = null
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

        methodChannel?.invokeMethod("analyze", mapOf("text" to text))
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
                var code = primaryCode.toChar()
                if (isCaps) {
                    code = code.uppercaseChar()
                }
                ic.commitText(code.toString(), 1)
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
