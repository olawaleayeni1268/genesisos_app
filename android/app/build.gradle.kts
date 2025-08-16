// android/app/build.gradle.kts — uses release keystore if present, else falls back to debug
import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties().apply {
    val propsFile = rootProject.file("android/key.properties")
    if (propsFile.exists()) propsFile.reader().use { load(it) }
}

android {
    namespace = "com.example.genesisos_app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.genesisos_app"
        minSdk = 21
        targetSdk = 34

        // Pull version from Flutter's local.properties (from pubspec.yaml)
        val localProps = Properties().apply {
            val lp = rootProject.file("local.properties")
            if (lp.exists()) lp.reader().use { load(it) }
        }
        versionCode = (localProps.getProperty("flutter.versionCode") ?: "1").toInt()
        versionName = localProps.getProperty("flutter.versionName") ?: "1.0.0"
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.isNotEmpty()) {
                storeFile = file(keystoreProperties["storeFile"] ?: "app/upload-keystore.jks")
                storePassword = (keystoreProperties["storePassword"] ?: "").toString()
                keyAlias = (keystoreProperties["keyAlias"] ?: "upload").toString()
                keyPassword = (keystoreProperties["keyPassword"] ?: "").toString()
            }
        }
    }

    buildTypes {
        getByName("release") {
            // If CI restored key.properties, use proper release signing.
            // If not, fall back to debug signing so builds never block.
            signingConfig = if (keystoreProperties.isNotEmpty())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")

            isMinifyEnabled = false
        }
        getByName("debug")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

flutter { source = "../.." }

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.22")
}
