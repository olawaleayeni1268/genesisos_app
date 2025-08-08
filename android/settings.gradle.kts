// android/settings.gradle.kts

pluginManagement {
    repositories {
        google()
        gradlePluginPortal()
        mavenCentral()
    }
}

import org.gradle.api.initialization.resolve.RepositoriesMode

dependencyResolutionManagement {
    // Prefer settings-defined repos, but DO NOT fail if a plugin adds one.
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        // Needed by the Flutter Gradle plugin for engine artifacts
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "genesisos_app"
include(":app")
