pluginManagement {
    repositories {
        google()
        gradlePluginPortal()
        mavenCentral()
        // Flutter artifacts
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

dependencyResolutionManagement {
    // Allow project-level repositories (the Flutter plugin adds one)
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        // Also list Flutter artifacts here just in case
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "genesisos_app"
include(":app")
