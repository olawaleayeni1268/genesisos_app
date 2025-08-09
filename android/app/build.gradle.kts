plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.genesisos_app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.genesisos_app"
        minSdk = 21
        targetSdk = 34

        // Bump these so the new APK installs
        versionCode = 5
        versionName = "1.0.5"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("release") {
            // Sign with debug keys so you can install the release APK easily while testing
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") { }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.22")
}
