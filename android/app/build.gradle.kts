plugins {
    // Pin explicit versions so CI can resolve them
    id("com.android.application") version "8.7.3"
    id("org.jetbrains.kotlin.android") version "1.9.22"

    // The Flutter Gradle Plugin must be applied after the Android/Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.genesisos_app"

    // Use versions provided by the Flutter plugin for SDK levels
    compileSdk = flutter.compileSdkVersion

    // Force the NDK version your plugins require
    ndkVersion = "27.0.12077973"

    compileOptions {
        // AGP 8.x uses Java 17
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.genesisos_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Keep debug signing for now so CI can build a release APK without a keystore
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
