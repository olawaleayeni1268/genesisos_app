plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.genesisos_app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.genesisos_app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1    // CI will override
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug") // installable test builds
            isMinifyEnabled = false
        }
        getByName("debug")
    }
}

flutter { source = "../.." }

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.22")
}
