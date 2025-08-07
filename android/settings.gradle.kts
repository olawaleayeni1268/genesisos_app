// android/settings.gradle.kts  – full content
pluginManagement {
    // make Flutter’s own plugin visible
    // Use the Flutter SDK path provided by the action
val flutterHome = System.getenv("FLUTTER_HOME") ?: error("FLUTTER_HOME not set")
includeBuild("$flutterHome/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()

        // —— mirrors that bypass plugins.gradle.org ——
        maven { setUrl("https://maven.aliyun.com/repository/gradle-plugin") } // full plugin-portal mirror
        maven { setUrl("https://maven.aliyun.com/repository/central") }       // extra fallback
        // ------------------------------------------------

        gradlePluginPortal()   // keep last
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { setUrl("https://maven.aliyun.com/repository/public") }        // mirror for normal Maven
    }
}

rootProject.name = "genesisos_app"
include(":app")
