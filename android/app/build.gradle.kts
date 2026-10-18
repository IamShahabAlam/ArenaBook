plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// One flavor per client, named by its ClientConfig id (lib/app/config/clients). A test keeps the two lists in sync.
val clients = listOf("demo")

android {
    namespace = "com.devcatstudios.arenabook"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Each client's flavor appends ".<client>", e.g. com.devcatstudios.arenabook.demo. Never change it after a store upload.
        applicationId = "com.devcatstudios.arenabook"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    flavorDimensions += "client"
    productFlavors {
        clients.forEach { client ->
            create(client) {
                dimension = "client"
                applicationIdSuffix = ".$client"
            }
        }
    }
}

flutter {
    source = "../.."
}
