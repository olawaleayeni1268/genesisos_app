// android/settings.gradle.kts

import java.util.Properties
import java.io.File

pluginManagement {
    // Locate the Flutter SDK from local.properties or FLUTTER_HOME (works in CI)
    val flutterSdkPath: String by lazy {
        val props = Properties()
        val localProps = File(rootDir, "local.properties")
        if (localProps.exists()) {
            localProps.inputStream().use { props.load(it) }
        }
        val fromLocal = props.getProperty("flutter.sdk")
        val fromEnv = System.getenv("FLUTTER_HOME")
        (fromLocal ?: fromEnv)
            ?: error("Flutter SDK not found. Set flutter.sdk in local.properties or FLUTTER_HOME env var.")
    }

    // This exposes the Flutter Gradle plugins (including dev.flutter.flutter-gradle-plugin)
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // Flutter artifacts repo
        maven(url = "https://storage.googleapis.com/download.flutter.io")
    }
}

// Required for the plugin above to be discoverable
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

dependencyResolutionManagement {
    // Allow project-level repos (Flutter plugin may add one)
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        maven(url = "https://storage.googleapis.com/download.flutter.io")
    }
}

rootProject.name = "genesisos_app"
include(":app")
