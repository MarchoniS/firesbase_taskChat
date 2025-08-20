import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")

    // Firebase
    id("com.google.gms.google-services")
    id("com.google.firebase.firebase-perf")
}

// 🔑 Load & update version.properties
val versionPropsFile = rootProject.file("version.properties")
val versionProps = Properties()

if (versionPropsFile.exists()) {
    versionProps.load(versionPropsFile.inputStream())
}

var versionCode: Int = versionProps.getProperty("versionCode", "1").toInt()
var versionName: String = versionProps.getProperty("versionName", "1.0.0")


// Increment versionCode automatically
versionCode += 1

// Update versionName automatically (patch bump, e.g. 1.0.1 → 1.0.2)
val versionParts = versionName.split(".").toMutableList()
if (versionParts.size == 3) {
    versionParts[2] = (versionParts[2].toInt() + 1).toString()
}
versionName = versionParts.joinToString(".")

versionProps["versionCode"] = versionCode.toString()
versionProps["versionName"] = versionName
versionProps.store(versionPropsFile.outputStream(), null)

android {
    namespace = "com.example.task"
    ndkVersion = "27.0.12077973"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.task"
        minSdk = 29
        targetSdk = 35

        // ✅ Use auto-incremented values
        this.versionCode = versionCode
        this.versionName = versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

androidComponents {
    onVariants { variant ->
        variant.outputs.forEach { output ->

            val apkName = "ChatTask-${variant.name}-${versionName}.apk"

            // Rename output APK
            (output as com.android.build.api.variant.impl.VariantOutputImpl)
                .outputFileName.set(apkName)
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
