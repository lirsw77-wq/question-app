plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // 强制锁定版本，并添加对 AGP 9 的兼容处理
    id("com.android.application") version "8.1.1" apply false
    id("com.android.library") version "8.1.1" apply false
    id("org.jetbrains.kotlin.android") version "1.8.10" apply false
}

// 恢复你原有的加载逻辑
includeBuild("${settingsDir.parent}/packages/flutter_tools/gradle")
include(":app")
