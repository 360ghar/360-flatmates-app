import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
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

val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val releaseKeyAlias = keystoreProperties.getProperty("keyAlias")
    ?: System.getenv("KEY_ALIAS") ?: ""
val releaseKeyPassword = keystoreProperties.getProperty("keyPassword")
    ?: System.getenv("KEY_PASSWORD") ?: ""
val releaseStorePassword = keystoreProperties.getProperty("storePassword")
    ?: System.getenv("KEYSTORE_PASSWORD") ?: ""
val releaseStoreFilePath = keystoreProperties.getProperty("storeFile")
    ?: System.getenv("KEYSTORE_FILE")
val releaseSigningRequested = keystorePropertiesFile.exists()
    || System.getenv("KEYSTORE_FILE") != null
    || System.getenv("KEY_ALIAS") != null
    || System.getenv("KEY_PASSWORD") != null
    || System.getenv("KEYSTORE_PASSWORD") != null
val releaseSigningComplete = releaseKeyAlias.isNotBlank()
    && releaseKeyPassword.isNotBlank()
    && releaseStorePassword.isNotBlank()
    && !releaseStoreFilePath.isNullOrBlank()

if (releaseTaskRequested && releaseSigningRequested && !releaseSigningComplete) {
    throw GradleException(
        "Release signing credentials are incomplete. " +
            "Ensure key.properties contains keyAlias, keyPassword, storePassword, and storeFile, " +
            "or set KEY_ALIAS, KEY_PASSWORD, KEYSTORE_PASSWORD, and KEYSTORE_FILE environment variables."
    )
}

if (releaseTaskRequested && !releaseSigningRequested && !releaseSigningComplete) {
    throw GradleException(
        "Release builds require signing. " +
            "Provide key.properties or set KEYSTORE_FILE, KEY_ALIAS, KEY_PASSWORD, and KEYSTORE_PASSWORD environment variables."
    )
}

android {
    namespace = "com.the360ghar.flatmates360"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    signingConfigs {
        create("release") {
            // key.properties file takes precedence; fall back to environment variables.
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
            storePassword = releaseStorePassword
            storeFile = if (releaseStoreFilePath != null) file(releaseStoreFilePath) else null
        }
    }

    defaultConfig {
        applicationId = "com.the360ghar.flatmates360"
        // maplibre_gl requires minSdk >= 21. Flutter's default (24) already
        // satisfies this; guard explicitly so the requirement survives any
        // future change to the Flutter default.
        minSdk = maxOf(21, flutter.minSdkVersion)
        // Pin to 35 to match the previous Play Store release's device catalog.
        // Flutter 3.41.x defaults to 36 which drops ~18k device profiles.
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use the release signing config when keystore credentials are available,
            // otherwise fall back to the debug signing config for development builds.
            signingConfig = if (releaseSigningComplete) {
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
