// android/settings.gradle.kts
import java.util.Properties
import org.gradle.api.initialization.resolve.RepositoriesMode

/* ── find Flutter ─────────────────────────────────────────── */
val local = Properties().apply {
    val lp = File(settingsDir, "local.properties")
    if (lp.exists()) lp.reader().use { load(it) }
}

val flutterSdk = (
    System.getenv("FLUTTER_ROOT")      // GitHub Actions & many local installs
 ?: System.getenv("FLUTTER_HOME")
 ?: System.getenv("FLUTTER_SDK")
 ?: local["flutter.sdk"]              // fallback to local.properties
) ?: throw GradleException("""
    Flutter SDK not found.
    • Locally: add  flutter.sdk=C:\path\to\flutter  to android/local.properties
    • CI: FLUTTER_ROOT is set automatically by subosito/flutter-action
""".trimIndent())

/* ── plugin management ────────────────────────────────────── */
pluginManagement {
    includeBuild("$flutterSdk/packages/flutter_tools/gradle")
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application")           version "8.7.3" apply false
    id("org.jetbrains.kotlin.android")      version "1.9.22" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories { google(); mavenCentral() }
}

rootProject.name = "genesisos_app"
include(":app")
