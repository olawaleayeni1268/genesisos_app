// android/settings.gradle.kts

pluginManagement {
    repositories {
        google()
        gradlePluginPortal()
        mavenCentral()
    }

    // Require FLUTTER_HOME to be set by CI (workflow will export it)
    val flutterHome = System.getenv("FLUTTER_HOME")
        ?: throw GradleException(
            "FLUTTER_HOME is not set. CI must export it after installing Flutter."
        )

    val flutterTools = java.io.File("$flutterHome/packages/flutter_tools/gradle")
    if (!flutterTools.exists()) {
        throw GradleException("Flutter tools not found at: $flutterTools")
    }
    includeBuild(flutterTools)
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
