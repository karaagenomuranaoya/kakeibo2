plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.atsumeru_kakeibo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.atsumeru_kakeibo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // ▼▼▼ リリース版の名前設定 (KTS版) ▼▼▼
            manifestPlaceholders["appName"] = "ガチャと家計簿"
        }
        debug {
            // ▼▼▼ デバッグ版の設定 (KTS版) ▼▼▼
            // IDを変えて、本番アプリと共存できるようにする
            applicationIdSuffix = ".dev"
            // 名前を変えて、画面上で見分けられるようにする
            manifestPlaceholders["appName"] = "ガチャと家計簿(Dev)"
        }
    }
}

flutter {
    source = "../.."
}