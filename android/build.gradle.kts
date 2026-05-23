plugins {
    id("com.android.application")
    // ⚠️ 这里已经移除了会导致报错的 kotlin-android 插件
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.question_app" // ⚠️ 请务必把双引号里的内容改成你的实际包名！
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.question_app" // ⚠️ 请务必把双引号里的内容改成你的实际包名！
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
    // 基础依赖，交给 Flutter 自动管理
}
