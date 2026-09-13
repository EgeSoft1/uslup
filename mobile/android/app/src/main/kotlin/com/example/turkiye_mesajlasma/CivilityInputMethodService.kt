package com.example.turkiye_mesajlasma

import android.inputmethodservice.InputMethodService
import android.inputmethodservice.Keyboard
import android.inputmethodservice.KeyboardView
import android.text.InputType
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.TextView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

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

    override fun onCreate() {
        super.onCreate()
        
        // Flutter motorunu arka planda başlat
        flutterEngine = FlutterEngine(this)
        flutterEngine?.dartExecutor?.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        
        methodChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "uslup/ime")
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "updateSuggestion") {
                val toxicity = call.argument<Double>("toxicity") ?: 0.0
                val message = call.argument<String>("message") ?: ""
                val cleanText = call.argument<String>("cleanText")
                
                val strip = suggestionStrip
                if (strip == null) {
                    // Klavye görünümü henüz kurulmadı; gösterilecek yer yok.
                    result.success(null)
                    return@setMethodCallHandler
                }

                if (toxicity > 0.5 && message.isNotEmpty()) {
                    currentCleanText = cleanText
                    strip.text = "⚠️ $message"

                    val bg = strip.background as? android.graphics.drawable.GradientDrawable
                    if (bg != null) {
                        if (toxicity > 0.85) {
                            bg.setColor(android.graphics.Color.parseColor("#B71C1C"))
                            strip.setTextColor(android.graphics.Color.WHITE)
                            // Haptic Feedback: Yüksek Riskte Kuvvetli Titreşim
                            strip.performHapticFeedback(android.view.HapticFeedbackConstants.LONG_PRESS)
                        } else if (toxicity > 0.65) {
                            bg.setColor(android.graphics.Color.parseColor("#E53935"))
                            strip.setTextColor(android.graphics.Color.WHITE)
                            // Haptic Feedback: Orta Riskte Normal Titreşim
                            strip.performHapticFeedback(android.view.HapticFeedbackConstants.KEYBOARD_TAP)
                        } else {
                            bg.setColor(android.graphics.Color.parseColor("#FB8C00"))
                            strip.setTextColor(android.graphics.Color.BLACK)
                        }
                    }

                    strip.visibility = View.VISIBLE
                } else {
                    currentCleanText = null
                    strip.visibility = View.GONE
                }
                result.success(null)
            } else if (call.method == "syncToVDS") {
                // Ağ çağrısı native katmanda durur çünkü indirilen OTA model
                // dosyası zaten buraya, uygulamanın özel dizinine yazılıyor.
                // Dart tarafında ikinci bir HTTP yığını taşımak aynı işi iki
                // yerde yapmak olurdu.
                val payload = call.argument<String>("payload") ?: ""
                val ip = call.argument<String>("ip") ?: "127.0.0.1"
                val port = call.argument<Int>("port") ?: 5050

                Thread {
                    try {
                        val url = java.net.URL("http://$ip:$port/api/v1/fed-avg/sync")
                        val conn = url.openConnection() as java.net.HttpURLConnection
                        conn.connectTimeout = 5000
                        conn.readTimeout = 5000
                        conn.requestMethod = "POST"
                        conn.setRequestProperty("Content-Type", "application/json")
                        conn.doOutput = true
                        conn.outputStream.use { os ->
                            os.write(payload.toByteArray())
                        }
                        val responseCode = conn.responseCode
                        android.util.Log.d("VDS_SYNC", "VDS Response: $responseCode")
                    } catch (e: Exception) {
                        android.util.Log.e("VDS_SYNC", "VDS Error: ${e.message}")
                    }
                }.start()
                result.success(null)
            } else if (call.method == "downloadLatestModel") {
                val ip = call.argument<String>("ip") ?: "127.0.0.1"
                val port = call.argument<Int>("port") ?: 5050

                Thread {
                    try {
                        val url = java.net.URL("http://$ip:$port/api/v1/model/latest")
                        val conn = url.openConnection() as java.net.HttpURLConnection
                        conn.connectTimeout = 8000
                        conn.readTimeout = 15000
                        conn.requestMethod = "GET"
                        if (conn.responseCode == 200) {
                            val file = java.io.File(filesDir, "uslup_model_ota.onnx")
                            conn.inputStream.use { input ->
                                file.outputStream().use { output ->
                                    input.copyTo(output)
                                }
                            }
                            android.util.Log.d("VDS_SYNC", "OTA Model İndirildi: ${file.absolutePath}")
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("VDS_SYNC", "OTA İndirme Hatası: ${e.message}")
                    }
                }.start()
                result.success(null)
            } else if (call.method == "llmRewrite") {
                val ip = call.argument<String>("ip") ?: "127.0.0.1"
                val text = call.argument<String>("text") ?: ""
                
                Thread {
                    try {
                        val url = java.net.URL("http://$ip:5050/api/v1/llm/rewrite")
                        val conn = url.openConnection() as java.net.HttpURLConnection
                        conn.connectTimeout = 8000
                        conn.readTimeout = 8000
                        conn.requestMethod = "POST"
                        conn.setRequestProperty("Content-Type", "application/json")
                        conn.doOutput = true
                        
                        val payload = "{\"text\": \"${text.replace("\"", "\\\"")}\"}"
                        conn.outputStream.use { os ->
                            os.write(payload.toByteArray())
                        }
                        
                        val responseCode = conn.responseCode
                        if (responseCode == 200) {
                            val response = conn.inputStream.bufferedReader().readText()
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(response)
                            }
                        } else {
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.error("ERROR", "VDS error", null)
                            }
                        }
                    } catch (e: Exception) {
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            result.error("ERROR", e.message, null)
                        }
                    }
                }.start()
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreateInputView(): View {
        val root = layoutInflater.inflate(R.layout.keyboard_view, null)
        keyboardView = root.findViewById(R.id.keyboard)
        val strip = root.findViewById<TextView>(R.id.civility_suggestion_strip)
        suggestionStrip = strip

        // Öneriye tıklanınca metni yerel olarak değiştirir (Cihaz üstü Rewrite)
        strip.setOnClickListener {
            val textToCommit = currentCleanText
            if (!textToCommit.isNullOrEmpty()) {
                val ic = currentInputConnection
                // Metnin tamamını seçip yeni metinle değiştir
                val extracted = ic?.getExtractedText(android.view.inputmethod.ExtractedTextRequest(), 0)
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
        // Yeni bir alana girildiğinde uyarıyı temizle. Bu geri çağrı,
        // `onCreateInputView`den ÖNCE de gelebilir — o yüzden null geçilir.
        suggestionStrip?.visibility = View.GONE
        currentCleanText = null
    }

    // --- DAVRANIŞSAL BİYOMETRİ (Madde 60) ---
    private var lastKeyTime: Long = 0
    private var keyPressIntervals = mutableListOf<Long>()
    private var backspaceCount = 0
    private var totalKeystrokes = 0

    private fun checkTextWithCivilityEngine() {
        val ic = currentInputConnection
        val extr = ic?.getExtractedText(android.view.inputmethod.ExtractedTextRequest(), 0)
        val text = extr?.text?.toString() ?: return

        // Biyometrik Veri Hesaplama
        var avgInterval = 250.0 // Default 250ms
        if (keyPressIntervals.isNotEmpty()) {
            avgInterval = keyPressIntervals.average()
        }
        val backspaceRatio = if (totalKeystrokes > 0) backspaceCount.toDouble() / totalKeystrokes else 0.0

        // Yazılan metni ve biyometrik veriyi Dart tarafına analiz için gönder
        methodChannel?.invokeMethod("analyze", mapOf(
            "text" to text,
            "typing_speed_ms" to avgInterval,
            "backspace_ratio" to backspaceRatio
        ))
    }

    // --- OnKeyboardActionListener methods ---
    override fun onKey(primaryCode: Int, keyCodes: IntArray?) {
        val ic = currentInputConnection ?: return

        // Biyometrik Takip
        val currentTime = System.currentTimeMillis()
        if (lastKeyTime > 0) {
            val interval = currentTime - lastKeyTime
            if (interval < 2000) { // 2 saniyeden uzun beklemeleri (düşünme) sayma
                keyPressIntervals.add(interval)
                if (keyPressIntervals.size > 20) {
                    keyPressIntervals.removeAt(0) // Sadece son 20 vuruşun hızını tut (kayan pencere)
                }
            }
        }
        lastKeyTime = currentTime
        totalKeystrokes++

        when (primaryCode) {
            Keyboard.KEYCODE_DELETE -> {
                backspaceCount++ // Agresif silme (Öfke belirtisi)
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
                // Mesaj gönderildiğinde biyometriyi sıfırla
                keyPressIntervals.clear()
                backspaceCount = 0
                totalKeystrokes = 0
            }
            else -> {
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
