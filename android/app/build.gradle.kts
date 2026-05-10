import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing credentials from key.properties (preferred) or environment variables.
// Generate the keystore with:
//   keytool -genkey -v -keystore release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
val keystorePropertiesFile = rootProject.file("app/key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val localPropertiesFile = rootProject.file("local.properties")
val localProperties = Properties()
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

fun configValue(name: String): String =
    project.findProperty(name)?.toString()
        ?: localProperties.getProperty(name)
        ?: System.getenv(name)
        ?: ""

val googleMapsApiKey = configValue("GOOGLE_MAPS_API_KEY")
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (releaseTaskRequested && googleMapsApiKey.isBlank()) {
    throw GradleException(
        "GOOGLE_MAPS_API_KEY is required for Android release builds. " +
            "Set it in android/local.properties, pass -PGOOGLE_MAPS_API_KEY, " +
            "or export GOOGLE_MAPS_API_KEY."
    )
}

android {
    namespace = "com.the360ghar.flatmates"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            // key.properties file takes precedence; fall back to environment variables.
            keyAlias = keystoreProperties.getProperty("keyAlias")
                ?: System.getenv("KEY_ALIAS") ?: ""
            keyPassword = keystoreProperties.getProperty("keyPassword")
                ?: System.getenv("KEY_PASSWORD") ?: ""
            storePassword = keystoreProperties.getProperty("storePassword")
                ?: System.getenv("KEYSTORE_PASSWORD") ?: ""
            val storeFilePath = keystoreProperties.getProperty("storeFile")
                ?: System.getenv("KEYSTORE_FILE")
            storeFile = if (storeFilePath != null) file(storeFilePath) else null

            // Fail fast if any required keystore property is missing or empty.
            if (keyAlias.isNullOrEmpty() || keyPassword.isNullOrEmpty() ||
                storePassword.isNullOrEmpty() || storeFile == null
            ) {
                throw GradleException(
                    "Release signing credentials are incomplete. " +
                    "Ensure key.properties contains keyAlias, keyPassword, storePassword, and storeFile, " +
                    "or set KEY_ALIAS, KEY_PASSWORD, KEYSTORE_PASSWORD, and KEYSTORE_FILE environment variables."
                )
            }
        }
    }

    defaultConfig {
        applicationId = "com.the360ghar.flatmates"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] =
            googleMapsApiKey.ifBlank { "MISSING_GOOGLE_MAPS_API_KEY" }
    }

    buildTypes {
        release {
            // Use the release signing config when keystore credentials are available,
            // otherwise fall back to the debug signing config for development builds.
            signingConfig = if (keystorePropertiesFile.exists()
                || System.getenv("KEYSTORE_FILE") != null
            ) {
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
