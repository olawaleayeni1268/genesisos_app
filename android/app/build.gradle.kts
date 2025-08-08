plugins {
    // No versions here — let Flutter/Gradle resolve them
    id("com.android.application")
    id("org.jetbrains.kotlin.android")

    // Must be applied after the Android/Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.genesisos_app"

    // Provided by the Flutter Gradle plugin
    compileSdk = flutter.compileSdkVersion

    // Pin the NDK version you need
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
            // Keep debug signing so CI can produce a release APK without a keystore
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
