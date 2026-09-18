import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Sürüm imzası (docs/24 · madde 41) ──────────────────────────────────────
// Sürüm derlemesi debug anahtarıyla imzalanıyordu: böyle bir APK mağazaya
// yüklenemez, güncellemesi başka bir makinede derlenen sürümle çakışır ve
// herkesin elindeki ortak debug anahtarıyla taklit edilebilir.
//
// Gerçek anahtar `android/key.properties` dosyasından okunur (depoya GİRMEZ,
// .gitignore). Örnek içerik:
//
//   storeFile=../uslup-release.jks
//   storePassword=…
//   keyAlias=uslup
//   keyPassword=…
//
// Anahtar üretmek için:
//   keytool -genkey -v -keystore uslup-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias uslup
//
// Dosya yoksa derleme yine çalışır ama debug anahtarıyla ve açık bir uyarıyla.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) keyPropertiesFile.inputStream().use { load(it) }
}
val hasReleaseKey = keyPropertiesFile.exists()

android {
    namespace = "com.example.turkiye_mesajlasma"
    compileSdk = 34

    // ── ndkVersion GERİ EKLENDİ (Eylül 2026) ────────────────
    // ONNX Runtime Android entegrasyonu için NDK gereklidir.
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Paket adı, sahipliği doğrulanabilir bir ad alanından seçildi
        // (depo: github.com/EgeSoft1/uslup). Şablonun `com.example.*`
        // varsayılanı hiç kimseye ait değildir ve mağazaya kabul edilmez.
        //
        // `namespace` KASITLI olarak değiştirilmedi: manifestteki
        // `.MainActivity` ona göre çözülür ve Kotlin kaynağının paket
        // yolu onunla eşleşmek zorundadır. applicationId ise yalnızca
        // kurulan paketin kimliğidir; ikisi bağımsızdır.
        applicationId = "io.github.egesoft1.uslup"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "UYARI: android/key.properties yok — sürüm derlemesi DEBUG " +
                        "anahtarıyla imzalanıyor. Mağazaya yüklenemez. " +
                        "Ayrıntı: android/app/build.gradle.kts başındaki not."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
