buildscript {
    ext["kotlin_version"] = "1.9.20"

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // 锁死兼容的 AGP 版本，避开 9.0+ 的坑
        classpath("com.android.tools.build:gradle:8.7.3")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${ext["kotlin_version"]}")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
