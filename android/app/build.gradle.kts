plugins {
    id("com.android.application")
    id("kotlin-android")
    // must come after the Android/Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.genesisos_app"

    // Use the values exported by the Flutter plugin
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.genesisos_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Your NDK pin
    ndkVersion = "27.0.12077973"

    // AGP 8.x needs Java 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // Keep debug signing for now so CI can produce a release APK
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ********************************************************************
// Explicitly add the Flutter Android embedding so Kotlin sees FlutterActivity
// ********************************************************************
val engineRev = "ef0cd000916d64fa0c5d09cc809fa7ad244a5767"
dependencies {
    implementation("io.flutter:flutter_embedding_release:1.0.0-$engineRev")
}
