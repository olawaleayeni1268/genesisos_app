pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }

    // Make Flutter’s Gradle plugin visible from the installed Flutter SDK on CI
    val flutterHome = System.getenv("FLUTTER_HOME")
    if (!flutterHome.isNullOrEmpty()) {
        includeBuild("$flutterHome/packages/flutter_tools/gradle")
    }

    // Pin plugin versions here (projects can omit versions)
    plugins {
        id("com.android.application") version "8.7.3"
        id("org.jetbrains.kotlin.android") version "1.9.22"
        id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    }
}

dependencyResolutionManagement {
    // Don't hard-fail if a plugin (Flutter) adds a project repo
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "genesisos_app"
include(":app")
