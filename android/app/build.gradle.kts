import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ----------------------------------------------------------------------------
// Release signing configuration.
//
// The actual keystore is NOT committed to the repository for security reasons.
// Create a `key.properties` file in the `android/` directory (git-ignored) OR
// copy `key.properties.example` and fill in your real keystore details.
//
// Example `android/key.properties`:
//   storePassword=YOUR_STORE_PASSWORD
//   keyPassword=YOUR_KEY_PASSWORD
//   keyAlias=YOUR_KEY_ALIAS
//   storeFile=/absolute/or/relative/path/to/your/release.keystore.jks
//
// If `key.properties` is absent, the release build falls back to the debug
// signing config so `flutter run --release` still works during development.
// THIS MUST BE REPLACED with a real release keystore before publishing.
// ----------------------------------------------------------------------------
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.mamahealth.admin"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Unique application ID used for the Play Store and device identity.
        applicationId = "com.mamahealth.admin"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = file(keystoreProperties["storeFile"] as String?)
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // R8/ProGuard code shrinking reduces APK size and removes unused
            // code. See proguard-rules.pro for keep rules.
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Sign with the release keystore if configured; otherwise fall
            // back to debug signing so local `--release` builds still work.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
