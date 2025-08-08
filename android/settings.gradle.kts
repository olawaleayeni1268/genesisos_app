// android/settings.gradle.kts

pluginManagement {
    repositories {
        google()
        gradlePluginPortal()
        mavenCentral()
    }

    // Locate the Flutter SDK (CI sets FLUTTER_HOME; we also provide a safe fallback path on GitHub runners)
    val flutterHome = System.getenv("FLUTTER_HOME") ?: "/opt/hostedtoolcache/flutter/3.32.8-stable/x64"
    val flutterTools = java.io.File("$flutterHome/packages/flutter_tools/gradle")

    if (flutterTools.exists()) {
        includeBuild(flutterTools)
    } else {
        throw GradleException("Flutter tools not found at: $flutterTools. Ensure FLUTTER_HOME is set in CI.")
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "genesisos_app"
include(":app")
