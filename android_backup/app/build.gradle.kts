// android/app/build.gradle.kts
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

/* Read versions written by Flutter from local.properties (generated from pubspec.yaml) */
val localProps = Properties().apply {
    val lp = rootProject.file("local.properties")
    if (lp.exists()) lp.reader(Charsets.UTF_8).use { load(it) }
}
val flutterVersionCode = (localProps.getProperty("flutter.versionCode") ?: "1").toInt()
val flutterVersionName = localProps.getProperty("flutter.versionName") ?: "1.0.0"

android {
    namespace = "com.example.genesisos_app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.genesisos_app"
        minSdk = 21
        targetSdk = 34
        versionCode = flutterVersionCode
        versionName = flutterVersionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    buildTypes {
        getByName("release") {
            // debug signing so the APK installs easily
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
        getByName("debug")
    }
}

flutter { source = "../.." }

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.22")
}
