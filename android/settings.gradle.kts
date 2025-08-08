pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // Flutter engine / artifacts (needed for io.flutter:* deps)
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

dependencyResolutionManagement {
    // Keep this strict so only the repos above are used
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        // Same Flutter repo for runtime dependencies
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "genesisos_app"
include(":app")
