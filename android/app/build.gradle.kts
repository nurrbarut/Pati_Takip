plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pet_takip"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        // 👇 Kotlin DSL'de 'is' eki ve '=' işareti gereklidir
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8" // Genelde 1.8 olması daha güvenlidir, ama 17 de kalabilir.
    }

    defaultConfig {
        applicationId = "com.example.pet_takip"
        minSdk = flutter.minSdkVersion // Bildirim kütüphanesi için en az 21-23 iyidir
        targetSdk = 35 // compileSdk 36 iken target 35 kalabilir veya 36 yapabilirsin
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Bu kütüphane olmadan desugaring çalışmaz ve hata verir!
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

// Bazı çakışmaları önlemek için eklediğin strateji (Aynen korudum)
configurations.all {
    resolutionStrategy {
        force("androidx.activity:activity:1.10.1")
    }
}
