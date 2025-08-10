// android/settings.gradle.kts
import org.gradle.api.initialization.resolve.RepositoriesMode

pluginManagement {
    repositories {
        // Order matters
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // Flutter Gradle integration
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Pin plugin versions so Gradle can resolve them
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "genesisos_app"
include(":app")
