plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bobo.liuyao_app"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.bobo.liuyao_app"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = 19
        versionName = "1.2.0"

        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    signingConfigs {
        create("release") {
            val propsFile = rootProject.file("key.properties")
            if (propsFile.exists()) {
                val lines = propsFile.readLines()
                fun getProp(name: String): String? {
                    for (line in lines) {
                        val trimmed = line.trim()
                        if (trimmed.startsWith("$name=")) {
                            return trimmed.substring(name.length + 1)
                        }
                    }
                    return null
                }
                keyAlias = getProp("keyAlias") ?: ""
                keyPassword = getProp("keyPassword") ?: ""
                storeFile = getProp("storeFile")?.let { rootProject.file(it) }
                storePassword = getProp("storePassword") ?: ""
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
}
