import java.util.Properties
import org.gradle.api.initialization.resolve.RepositoriesMode

val localProps = Properties()
val lp = File(rootDir, "local.properties")
if (lp.exists()) lp.reader(Charsets.UTF_8).use { localProps.load(it) }

val flutterSdkPath: String? =
    localProps.getProperty("flutter.sdk")
        ?: System.getenv("FLUTTER_ROOT")
        ?: System.getenv("FLUTTER_HOME")
        ?: System.getenv("FLUTTER_SDK")

require(!flutterSdkPath.isNullOrBlank()) {
    "Flutter SDK path not found. Ensure android/local.properties has flutter.sdk, or set FLUTTER_ROOT/FLUTTER_HOME/FLUTTER_SDK."
}

includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories { google(); mavenCentral() }
}

rootProject.name = "genesisos_app"
include(":app")
