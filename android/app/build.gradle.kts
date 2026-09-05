import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}


android {
    namespace = "com.legacynetworkco.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // El paquete lo fija Play, no nosotros: la app de Play Console se creo
        // con `com.legacynetworkco.app` y ese nombre queda ligado a ella para
        // siempre. Subir un bundle con otro applicationId lo rechaza con
        // "El nombre de paquete del archivo APK o Android App Bundle debe ser
        // com.legacynetworkco.app" (2026-09-04).
        //
        // El anterior era `co.legacynetwork.legacyapp`, que sigue siendo el
        // bundle ID de iOS. Las dos plataformas dejan de coincidir a proposito:
        // en Play el nombre reservado no se libera nunca, ni borrando la app.
        //
        // ⚠️ Al cambiarlo, Google Sign-In depende de que la huella SHA-1 este
        // registrada en Firebase para ESTE paquete. La de `upload-keystore.jks`
        // estaba solo en el paquete viejo.
        applicationId = "com.legacynetworkco.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
