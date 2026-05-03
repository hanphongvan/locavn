import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { localProperties.load(it) }
}

// Flutter Gradle plugin truyền compile defines qua `dart-defines` (chuỗi base64("KEY=VALUE") nối bằng dấu phẩy).
// Build từ Android Studio không dùng `flutter build --dart-define=...` nên thiếu API_BASE_URL → release crash.
// Thêm vào android/local.properties (đã gitignore): API_BASE_URL=https://hoặc-http://máy-chủ-của-bạn
// Hoặc đặt biến môi trường API_BASE_URL khi chạy Gradle/CI.
val apiBaseUrlForDart =
    localProperties.getProperty("API_BASE_URL")?.trim()?.takeIf { it.isNotEmpty() }
        ?: System.getenv("API_BASE_URL")?.trim()?.takeIf { it.isNotEmpty() }
if (apiBaseUrlForDart != null) {
    val encodedSegment =
        Base64.getEncoder().encodeToString("API_BASE_URL=$apiBaseUrlForDart".toByteArray(Charsets.UTF_8))
    val existingDartDefines =
        (findProperty("dart-defines") as String?)?.trim()?.takeIf { it.isNotEmpty() }
    extra["dart-defines"] =
        if (existingDartDefines != null) "$existingDartDefines,$encodedSegment" else encodedSegment
}

fun releaseProp(name: String): String? =
    (rootProject.findProperty(name) as String?)?.trim()?.takeIf { it.isNotEmpty() }

val httmReleaseStoreFile = releaseProp("HTTM_RELEASE_STORE_FILE")
val httmReleaseStorePassword = releaseProp("HTTM_RELEASE_STORE_PASSWORD")
val httmReleaseKeyAlias = releaseProp("HTTM_RELEASE_KEY_ALIAS")
val httmReleaseKeyPassword = releaseProp("HTTM_RELEASE_KEY_PASSWORD")

val httmReleaseStore = httmReleaseStoreFile?.let { rootProject.file(it) }
val httmReleaseSigningReady =
    httmReleaseStore != null &&
        httmReleaseStore.isFile &&
        httmReleaseStorePassword != null &&
        httmReleaseKeyAlias != null &&
        httmReleaseKeyPassword != null

android {
    namespace = "vn.gov.dms.locavn"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "vn.gov.dms.locavn"
        // Thêm vào android/local.properties (gitignore): GOOGLE_MAPS_API_KEY=AIza...
        // Hoặc: set biến môi trường GOOGLE_MAPS_API_KEY khi build (CI).
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] =
            System.getenv("GOOGLE_MAPS_API_KEY")?.trim()?.takeIf { it.isNotEmpty() }
                ?: localProperties.getProperty("GOOGLE_MAPS_API_KEY")?.trim()?.takeIf { it.isNotEmpty() }
                ?: ""
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (httmReleaseSigningReady) {
            create("release") {
                storeFile = httmReleaseStore!!
                storePassword = httmReleaseStorePassword!!
                keyAlias = httmReleaseKeyAlias!!
                keyPassword = httmReleaseKeyPassword!!
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
