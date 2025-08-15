// android/settings.gradle.kts — compatible with local builds & GitHub Actions
import java.util.Properties
import kotlin.text.Charsets
import org.gradle.api.initialization.resolve.RepositoriesMode

// 1) Find Flutter SDK path (CI first, then local.properties, finally a safe default)
val localProps = Properties().apply {
    val lp = File(settingsDir, "local.properties")
    if (lp.exists()) lp.reader(Charsets.UTF_8).use { load(it) }
}

val flutterSdk: String =
    System.getenv("FLUTTER_ROOT")
        ?: System.getenv("FLUTTER_HOME")
        ?: System.getenv("FLUTTER_SDK")
        ?: (localProps.getProperty("flutter.sdk") ?: "C:/src/flutter") // adjust if your path differs

require(File(flutterSdk).exists()) {
    "Flutter SDK not found at: $flutterSdk\n" +
    "• Set FLUTTER_ROOT env var (CI does this automatically), or\n" +
    "• Put flutter.sdk=C:\\path\\to\\flutter in android/local.properties, or\n" +
    "• Update the fallback path in settings.gradle.kts."
}

// 2) Make Flutter’s Gradle plugin available
pluginManagement {
    includeBuild("$flutterSdk/packages/flutter_tools/gradle")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application")           version "8.7.3" apply false
    id("org.jetbrains.kotlin.android")      version "1.9.22" apply false
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
