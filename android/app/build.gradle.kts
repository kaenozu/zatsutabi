import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseStoreFile = providers.environmentVariable("RELEASE_STORE_FILE")
val releaseStorePassword = providers.environmentVariable("RELEASE_STORE_PASSWORD")
val releaseKeyAlias = providers.environmentVariable("RELEASE_KEY_ALIAS")
val releaseKeyPassword = providers.environmentVariable("RELEASE_KEY_PASSWORD")
val releaseSigningConfigured = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { it.isPresent }

val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(',')
        ?.mapNotNull { encoded ->
            runCatching {
                val decoded = String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
                val separator = decoded.indexOf('=')
                if (separator <= 0) null
                else decoded.substring(0, separator) to decoded.substring(separator + 1)
            }.getOrNull()
        }
        ?.toMap()
        ?: emptyMap()

val googleTestAndroidAppId = "ca-app-pub-3940256099942544~3347511713"
val googleTestAndroidBannerId = "ca-app-pub-3940256099942544/6300978111"
val productionAds = dartDefines["ZATSUTABI_PRODUCTION_ADS"]?.toBooleanStrictOrNull() ?: false
val admobAppId = dartDefines["ADMOB_ANDROID_APP_ID"] ?: googleTestAndroidAppId
val admobBannerId = dartDefines["ADMOB_ANDROID_BANNER_ID"] ?: googleTestAndroidBannerId

if (productionAds) {
    check(admobAppId.isNotBlank() && admobAppId != googleTestAndroidAppId) {
        "Production ads require a non-test ADMOB_ANDROID_APP_ID supplied via --dart-define."
    }
    check(admobBannerId.isNotBlank() && admobBannerId != googleTestAndroidBannerId) {
        "Production ads require a non-test ADMOB_ANDROID_BANNER_ID supplied via --dart-define."
    }
}

android {
    namespace = "jp.zatsutabi.zatsutabi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "jp.zatsutabi.zatsutabi"
        // The manifest and Dart runtime read the same --dart-define value.
        manifestPlaceholders["admobAppId"] = admobAppId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.create("release") {
                    storeFile = file(releaseStoreFile.get())
                    storePassword = releaseStorePassword.get()
                    keyAlias = releaseKeyAlias.get()
                    keyPassword = releaseKeyPassword.get()
                }
            } else {
                signingConfig = null
            }
        }
    }
}

tasks.matching { it.name == "assembleRelease" || it.name == "bundleRelease" }.configureEach {
    doFirst {
        check(releaseSigningConfigured) {
            "Release signing is not configured. Set RELEASE_STORE_FILE, " +
                "RELEASE_STORE_PASSWORD, RELEASE_KEY_ALIAS, and RELEASE_KEY_PASSWORD."
        }
        if (productionAds) {
            check(admobAppId != googleTestAndroidAppId && admobBannerId != googleTestAndroidBannerId) {
                "Production ad builds must not use Google's test AdMob IDs."
            }
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
