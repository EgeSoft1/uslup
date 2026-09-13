plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

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

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
