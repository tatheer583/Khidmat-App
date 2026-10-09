import java.util.Properties
plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


val khidmatKeyProperties = Properties()
val khidmatKeyFile = rootProject.file("key.properties")
val khidmatTestBuild = providers.gradleProperty("khidmatTestBuild").orNull == "true" ||
    providers.environmentVariable("KHIDMAT_TEST_BUILD").orNull == "true"
if (khidmatKeyFile.exists()) {
    khidmatKeyFile.inputStream().use { khidmatKeyProperties.load(it) }
}
android {
    signingConfigs {
        if (khidmatKeyFile.exists()) {
            create("khidmatRelease") {
                keyAlias = khidmatKeyProperties.getProperty("keyAlias")
                keyPassword = khidmatKeyProperties.getProperty("keyPassword")
                storeFile = file(khidmatKeyProperties.getProperty("storeFile"))
                storePassword = khidmatKeyProperties.getProperty("storePassword")
            }
        }
    }
    namespace = "com.khidmat.khidmat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.khidmat.khidmat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Test builds must opt in explicitly. Production signing never
            // silently falls back to a debug certificate.
            signingConfig = if (khidmatKeyFile.exists()) signingConfigs.getByName("khidmatRelease")
                else if (khidmatTestBuild) signingConfigs.getByName("debug")
                else null
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

gradle.taskGraph.whenReady {
    if (allTasks.any { it.name == "assembleRelease" || it.name == "bundleRelease" } &&
        !khidmatKeyFile.exists() && !khidmatTestBuild) {
        throw GradleException("Production signing is missing. Restore the existing private signing configuration; use khidmatTestBuild only for undistributed QA builds.")
    }
}
