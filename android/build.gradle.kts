// ---- android/build.gradle.kts ------------------------------------------
buildscript {
    val kotlin_version = "1.9.22"

    repositories {
        google()
        mavenCentral()
        maven { setUrl("https://maven.aliyun.com/repository/gradle-plugin") } // mirror
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.3.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { setUrl("https://maven.aliyun.com/repository/public") }        // mirror
    }
}

configurations.all {
    resolutionStrategy.eachDependency {
        if (requested.group == "org.jetbrains.kotlin") {
            useVersion("1.9.22")     // pin Kotlin
        }
    }
}
