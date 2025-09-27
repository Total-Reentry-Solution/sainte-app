plugins {
    kotlin("multiplatform")
    id("com.android.library")
    kotlin("native.cocoapods")
}

kotlin {
    android()
    iosX64()
    iosArm64()
    iosSimulatorArm64()

    cocoapods {
        summary = "Shared domain and data models"
        homepage = "https://example.com"
        ios.deploymentTarget = "13.0"
        framework {
            baseName = "shared"
        }
    }

    sourceSets {
        val commonMain by getting {
            dependencies {
                // Common dependencies can be added here
            }
        }
        val commonTest by getting
        val androidMain by getting
        val iosX64Main by getting
        val iosArm64Main by getting
        val iosSimulatorArm64Main by getting
        val iosMain by creating {
            dependsOn(commonMain)
            iosX64Main.dependsOn(this)
            iosArm64Main.dependsOn(this)
            iosSimulatorArm64Main.dependsOn(this)
        }
    }
}

android {
    namespace = "com.reentry.shared"
    compileSdk = 33
    defaultConfig {
        minSdk = 21
    }
}
