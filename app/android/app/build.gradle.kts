import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "br.fatec.memora"
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
        applicationId = "br.fatec.memora"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Nome sob o icone (FR-009b da 004). A depuracao sobrescreve.
        manifestPlaceholders["rotuloDoApp"] = "Memora"
    }

    // A chave do Memora mora fora do repositorio: key.properties e o .jks estao
    // no android/.gitignore. Sem eles (CI, outra maquina), o release cai na
    // chave de depuracao, com aviso: APK assinado assim nao instala por cima
    // de um assinado com a chave do Memora. Ver docs/deploy/render.md.
    val propriedadesDaChave = Properties()
    val arquivoDaChave = rootProject.file("key.properties")
    val temChaveDoMemora = arquivoDaChave.exists()
    if (temChaveDoMemora) {
        arquivoDaChave.inputStream().use { propriedadesDaChave.load(it) }
    }

    signingConfigs {
        if (temChaveDoMemora) {
            create("memora") {
                storeFile = file(propriedadesDaChave.getProperty("storeFile"))
                storePassword = propriedadesDaChave.getProperty("storePassword")
                keyAlias = propriedadesDaChave.getProperty("keyAlias")
                keyPassword = propriedadesDaChave.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        // A versao de depuracao instala ao lado da release no mesmo aparelho
        // (outro identificador e outro nome), para conferir trabalho em
        // andamento sem apagar a release nem os dados dela.
        debug {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["rotuloDoApp"] = "Memora (teste)"
        }
        release {
            signingConfig =
                if (temChaveDoMemora) {
                    signingConfigs.getByName("memora")
                } else {
                    logger.warn(
                        "AVISO: android/key.properties ausente; o release sera " +
                            "assinado com a chave de DEPURACAO desta maquina.",
                    )
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
