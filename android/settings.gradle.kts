pluginManagement {
    // Tell Gradle where Flutter is (CI sets FLUTTER_HOME; locally the wrapper does).
    val flutterHome = System.getenv("FLUTTER_HOME") ?: error("FLUTTER_HOME not set")

    // Include the Flutter tools build so the 'dev.flutter.flutter-gradle-plugin' is resolvable
    includeBuild("$flutterHome/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // Flutter engine/artifacts repo
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

dependencyResolutionManagement {
    // Let plugins add project repos without failing (Flutter plugin adds one)
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        // Flutter engine/artifacts repo
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "genesisos_app"
include(":app")
