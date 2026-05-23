plugins {
    id "com.android.application"
    // 注意：这里已经删除了旧版报错的 id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace "com.example.question_app" // ⚠️请将这里的 com.example.question_app 改成你的实际包名
    compileSdk flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    // 注意：这里已经删除了旧版报错的 kotlinOptions 块

    defaultConfig {
        applicationId "com.example.question_app" // ⚠️请将这里的 com.example.question_app 改成你的实际包名
        minSdk flutter.minSdkVersion
        targetSdk flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    // 基础依赖，不用再写 kotlin stdlib
}
