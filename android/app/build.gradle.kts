import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ─────────────────────────────────────────────────────────────────────────────
//  Firma de release
//
//  Antes, el tipo de build `release` usaba `signingConfigs.getByName("debug")`:
//  todo APK de release salía firmado con la clave de depuración, que es pública
//  y va incluida en cada instalación de Flutter. Cualquiera podía firmar una
//  actualización que el sistema aceptaría como legítima sobre esa instalación.
//
//  Ahora la firma sale de `android/key.properties`, que no está versionado
//  (ver `android/.gitignore`). Si falta, el build de release **falla**: no
//  vuelve a caer en la clave de depuración en silencio. Ese silencio es lo que
//  permitió que el problema durara tanto — un aviso por consola se pierde entre
//  cientos de líneas de Gradle, un fallo no.
//
//  Para builds que no se distribuyen (medir tamaño en CI, probar release en un
//  dispositivo) se genera una clave desechable:
//      tool/android/generar_keystore.sh --efimero
// ─────────────────────────────────────────────────────────────────────────────
val ficheroClaves = rootProject.file("key.properties")
val claves = Properties().apply {
    if (ficheroClaves.exists()) ficheroClaves.inputStream().use { load(it) }
}
val hayFirmaPropia = ficheroClaves.exists()

android {
    namespace = "com.example.salud_dental_clinic_management"
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
        applicationId = "com.example.salud_dental_clinic_management"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hayFirmaPropia) {
            create("release") {
                keyAlias = claves.getProperty("keyAlias")
                keyPassword = claves.getProperty("keyPassword")
                storeFile = claves.getProperty("storeFile")?.let { file(it) }
                storePassword = claves.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hayFirmaPropia) {
                signingConfigs.getByName("release")
            } else {
                // Se anula la firma en vez de heredar la de depuración. Un APK
                // sin firmar no se puede instalar, así que el error aparece
                // ahora y no cuando ya se ha repartido algo firmado con una
                // clave que conoce todo el mundo.
                null
            }
        }
    }
}

// Corta el build de release antes de producir nada si no hay clave propia.
// Va como comprobación de tarea y no como `throw` en la configuración para no
// romper `flutter test`, `flutter analyze` ni los builds de debug, que no
// firman nada.
tasks.matching { it.name.startsWith("assembleRelease") || it.name.startsWith("bundleRelease") }
    .configureEach {
        doFirst {
            if (!hayFirmaPropia) {
                throw GradleException(
                    """
                    No hay clave de firma para el release.

                    Falta android/key.properties. Sin él, este build saldría sin
                    firmar o —como ocurría antes— con la clave de depuración, que
                    es pública: cualquiera podría firmar una actualización que el
                    dispositivo aceptaría como legítima.

                    Para publicar de verdad:   tool/android/generar_keystore.sh
                    Para medir o probar:       tool/android/generar_keystore.sh --efimero

                    Detalles en RELEASE.md.
                    """.trimIndent()
                )
            }
        }
    }

flutter {
    source = "../.."
}
