import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Real upload-key signing for release builds. key.properties (gitignored,
// alongside the *.jks it points at) holds the store/key passwords — never
// committed. When the file does not exist in a local setup checkout, the
// release buildType below can fall back to debug signing. CI release builds
// are explicitly rejected below before that fallback can be selected.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

// The legacy fallback described above applies only to a local setup build.
// `requiresReleaseSigning` below makes every CI publication candidate fail
// before Gradle can select the debug signing configuration.
// A local developer may intentionally build a debug-signed release variant
// while setting up their environment. A CI build must never do that: it is a
// publication candidate, and publishing a debug-signed APK would permanently
// undermine the release channel. GitHub Actions sets CI=true automatically.
val hasReleaseSigning = keystorePropertiesFile.isFile &&
    keystoreProperties["keyAlias"] is String &&
    keystoreProperties["keyPassword"] is String &&
    keystoreProperties["storePassword"] is String &&
    (keystoreProperties["storeFile"] as? String)?.let(::file)?.isFile == true
val requiresReleaseSigning =
    System.getenv("CI")?.equals("true", ignoreCase = true) == true ||
    providers.gradleProperty("cashlyRequireReleaseSigning").orNull == "true"

if (requiresReleaseSigning && !hasReleaseSigning) {
    throw GradleException(
        "Release signing is required in CI. Provide the Android keystore and " +
            "key.properties through protected CI secrets; never publish a " +
            "debug-signed release.",
    )
}

android {
    namespace = "com.cashlylao.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.cashlylao.app"
        // firebase_auth requires API 23+.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Real upload-key signing when key.properties/the keystore are
            // present; a local setup build falls back to debug keys otherwise.
            // CI release builds fail closed before reaching this branch.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
