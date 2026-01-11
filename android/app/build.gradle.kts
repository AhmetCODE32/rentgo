plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.rentgo"
    compileSdk = 36 
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // BİLDİRİMLER İÇİN GEREKLİ: Desugaring aktifleştirildi
        isCoreLibraryDesugaringEnabled = true 
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
        options.compilerArgs.add("-Xlint:-deprecation")
    }

    defaultConfig {
        applicationId = "com.example.rentgo"
        minSdk = flutter.minSdkVersion
        targetSdk = 36 
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // BİLDİRİMLER İÇİN GEREKLİ KÜTÜPHANE
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
