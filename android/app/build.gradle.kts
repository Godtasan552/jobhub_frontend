plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.form_validate"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ เพิ่ม desugaring
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.form_validate"
        // ✅ เปลี่ยนเป็น 21 เพื่อรองรับ notifications
        minSdk = flutter.minSdkVersion  // ✅ ต้องเป็น 21 ขึ้นไป
        targetSdk = 36  
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // ✅ เพิ่ม multiDex
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ เพิ่ม dependencies เหล่านี้
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1")

    // ✅ เพิ่ม dependencies เหล่านี้สำหรับ notifications
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.work:work-runtime-ktx:2.10.0")
}
