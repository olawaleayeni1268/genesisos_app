pluginManagement {
    repositories {
        google()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

include(":app")
rootProject.name = "genesisos_app"
