// android/settings.gradle.kts

pluginManagement {
    // Find the Flutter SDK: prefer CI env var, otherwise read local.properties
    val flutterHome: String by lazy {
        System.getenv("FLUTTER_HOME") ?: run {
            val props = java.util.Properties()
            val f = java.io.File(rootDir, "local.properties")
            if (f.exists()) {
                f.inputStream().use { props.load(it) }
                props.getProperty("flutter.sdk")
            } else null
        } ?: error("Flutter SDK not found. Set FLUTTER_HOME in CI or flutter.sdk in local.properties.")
    }

    // Expose Flutter's Gradle plugins (dev.flutter.flutter-gradle-plugin)
    includeBuild("$flutterHome/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // Flutter artifacts
        maven(url = "https://storage.googleapis.com/download.flutter.io")
    }
}

// Required for the Flutter plugin to be applied later
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

dependencyResolutionManagement {
    // The Flutter plugin may add a project-level repo; allow it.
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        maven(url = "https://storage.googleapis.com/download.flutter.io")
    }
}

rootProject.name = "genesisos_app"
include(":app")
