# Despliegue de la app móvil

La app no se "despliega" en un servidor: se **compila y se publica** como artefacto en cada tienda.
Esta guía cubre Android (Play Store), iOS (App Store) y la variante web.

> Este repositorio es **público**. El keystore (`android/app/upload-keystore.jks`),
> `android/key.properties` y `android/api-key.json` están excluidos por `android/.gitignore` —
> verificado. No los versiones ni copies sus valores a archivos nuevos.

La lista de comprobaciones previas está en la skill `preflight-release`
(`.claude/skills/preflight-release/`). Cada punto de esta guía corresponde a un fallo que ya
ocurrió en el proyecto.

## 1. Confirmar a qué backend apunta

La configuración **no** se pasa por `--dart-define`: sale de `assets/config/config.json`, que
`ConfigService` lee al arrancar. Hay tres variantes en la misma carpeta y se cambian copiando una
sobre otra:

```bash
cat assets/config/config.json                       # ver el activo
cp assets/config/config.json.develop assets/config/config.json   # trabajar en local
cp assets/config/config.json.prod    assets/config/config.json   # volver a producción
```

El archivo por defecto **ya apunta a producción** (`https://legacy.intelyclick.com`). Un build de
pruebas con esta configuración escribe en la base de datos real.

`ConfigService` resuelve la URL por plataforma: `10.0.2.2` en el emulador Android, `localhost` en
web e iOS.

**Diferencia entre `config.json` y `config.json.prod`.** No son iguales: cambian los GraphQL
externos.

| Clave | `config.json` (activo) | `config.json.prod` |
|---|---|---|
| `graphql_url` | `https://lso.school/graphql` | `https://app.legacynetworkco.com/lso-api` |
| `content_graphql_url` | `https://legacynetworkco.com/graphql` | `https://app.legacynetworkco.com/content-api` |

Decide cuál de las dos es la buena **antes** de compilar: la app consume esos endpoints para los
cursos y para las noticias de WordPress, y usar el juego equivocado deja secciones vacías.

## 2. Subir la versión

```bash
grep '^version:' pubspec.yaml     # actualmente 1.0.0+8
```

El número tras el `+` es el `versionCode` de Android. **Play Store rechaza un `versionCode` ya
usado**, así que hay que incrementarlo en cada envío aunque la versión visible no cambie.

## Android

### Requisitos

- **JDK 21 (Temurin)**, fijado con `flutter config --jdk-dir`. Gradle 8.12 no soporta Java 25, que
  es el que trae la última Android Studio; el síntoma es un build que falla mostrando solo un
  número de versión (`25.0.2`), sin explicación.
- `android/key.properties` y `android/app/upload-keystore.jks` presentes. Sin ellos, `build.gradle.kts`
  no puede resolver `signingConfigs.release` y el build de release falla.
- En Windows, **Modo de Desarrollador** activado (`start ms-settings:developers`): sin él Flutter no
  puede crear symlinks y los plugins fallan antes de empezar.

### Verificar la firma contra Firebase

```bash
export JAVA_HOME="/c/Program Files/Eclipse Adoptium/jdk-21.0.12.8-hotspot"
"$JAVA_HOME/bin/keytool" -list -v -keystore android/app/upload-keystore.jks -alias upload | grep "SHA1:"
grep -o '"certificate_hash": "[^"]*"' android/app/google-services.json
```

Las huellas deben coincidir. Si no, **Google Sign-In falla en release con `DEVELOPER_ERROR`
(código 10)** aunque todo lo demás funcione. Firebase admite varias: conviene registrar la del
keystore de subida, la de Play App Signing (Play Console → Integridad de la app) y el
`debug.keystore` de cada equipo.

### Compilar

```bash
./compilar_android.sh
```

Hace `flutter clean`, `flutter pub get` y `flutter build appbundle --release --obfuscate
--split-debug-info=build/app/outputs/symbols`, y comprueba que el `.aab` exista al terminar.

Salida: `build/app/outputs/bundle/release/app-release.aab`.

**Guarda `build/app/outputs/symbols/` junto al artefacto y súbelo a Play Console.** Con
`--obfuscate`, sin esos símbolos los stack traces de producción son ilegibles.

Para un APK de prueba instalable directamente:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
"$ANDROID_SDK/build-tools/36.0.0/apksigner.bat" verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

El certificado debe decir `CN=Legacy Network`. Si dice `CN=Android Debug`, se firmó con la clave de
depuración y no sirve para distribuir.

⚠️ **No confíes en el código de salida si canalizas la salida.** `flutter build ... | tail` devuelve
el código de `tail`, no el de Gradle: un build fallido parece exitoso. Usa `${PIPESTATUS[0]}` o no
canalices.

### Subir a Play Store

```bash
./upload_play_store.sh          # fastlane supply, track "internal"
```

Necesita `android/api-key.json` (cuenta de servicio de Google Play con permiso de publicación) y
`fastlane` instalado. El script sube al canal **interno**; la promoción a producción se hace desde
Play Console.

El `package_name` del `Appfile` y el `applicationId` de `build.gradle.kts:37` coinciden en
`co.legacynetwork.legacyapp`, que es el paquete firmado y publicado. Si alguna vez dejan de
coincidir, la subida automatizada apunta a una aplicación distinta de la compilada sin avisar.

### Antes de publicar

Sube el número de versión en `pubspec.yaml`: Play rechaza un `versionCode` repetido, y el `+N`
del `version:` es exactamente ese `versionCode`.

El tráfico HTTP sin cifrar está permitido **solo en debug**
(`android/app/src/debug/AndroidManifest.xml`), porque `config.json.develop` apunta el emulador a
`http://10.0.2.2:8080`. El manifest de `main/` no lleva `usesCleartextTraffic`, así que el release
es HTTPS de punta a punta. No lo devuelvas a `main/` para depurar un problema de red en release.

## iOS

**Solo se compila en macOS.** No hay forma de generar un `.ipa` desde Windows: hace falta un Mac con
Xcode o CI con runners macOS (Codemagic, GitHub Actions `macos-latest`, Bitrise, Xcode Cloud). El
equipo de firma ya está configurado en el proyecto; la cuenta de Apple Developer es imprescindible.

```bash
cd ios && pod install && cd ..
flutter build ipa --release --obfuscate --split-debug-info=build/ios/symbols
```

**Resueltos el 2026-08-06:**

1. ~~`aps-environment` en `development`~~ → ahora `production` en `Runner.entitlements`, que usan
   Release y Profile, con `RunnerDebug.entitlements` en `development` para los builds de Xcode.
   Se añadió además `UIBackgroundModes: [remote-notification]`, sin el cual iOS nunca ejecutaba el
   `onBackgroundMessage` que la app ya registraba.
2. ~~Deployment target desalineado~~ → `15.0` en las tres configuraciones y en
   `Flutter/AppFrameworkInfo.plist`, que era un tercer sitio donde también decía 13.0.

**Sigue pendiente, y es motivo de rechazo en la revisión:** falta
`com.apple.developer.applesignin`. La app ofrece login con Google y la directriz **4.8** obliga
entonces a ofrecer también Sign in with Apple; la dependencia `sign_in_with_apple` ya está en el
proyecto, pero sin el entitlement el login falla en ejecución. **Orden correcto:** primero habilitar
la capability *Sign in with Apple* en el App ID desde el portal de Apple, y solo después añadir la
clave al entitlements — al revés, la firma falla porque el perfil no la incluye.

Conviene declarar `ITSAppUsesNonExemptEncryption` en `Info.plist` para no responder el cuestionario
de cumplimiento de exportación en cada subida. Es una **declaración legal** sobre el cifrado que usa
la app, así que la decide quien publica: si solo se usa HTTPS estándar, el valor es `false`.

## Compilar iOS sin un Mac: GitHub Actions

`.github/workflows/ios-testflight.yml` compila el `.ipa` en un runner de macOS y lo sube a
TestFlight. **Los runners de macOS son gratuitos en repositorios públicos como este.**

Solo se lanza a mano desde la pestaña *Actions*. No se dispara en `push` ni en `pull_request` a
propósito: cada ejecución ocupa un número de build en TestFlight y usa los secretos de la cuenta de
Apple, que no deben quedar al alcance de un pull request de un fork.

### Preparación, una sola vez

1. **Clave de API en App Store Connect.** *Users and Access → Integrations → App Store Connect API*
   → generar una clave con rol **App Manager**. Descarga el `.p8`: **solo se puede descargar una
   vez**. Anota el **Key ID** y el **Issuer ID** de esa pantalla.
2. **La app debe existir en App Store Connect** con el bundle id `co.legacynetwork.legacyapp`.
   TestFlight rechaza builds de una app que no esté registrada.
3. **El App ID necesita la capability *Push Notifications*** habilitada en *Certificates,
   Identifiers & Profiles*. Sin ella, el `aps-environment` del entitlement no se puede firmar.
4. **El certificado de distribución.** Es el paso que más confunde, porque **Apple no permite
   crearlo con la clave de API**: devuelve `403 You are not allowed to perform this operation`
   incluso con rol Admin. Solo se crea desde el portal web — pero **se puede hacer entero desde
   Windows**, sin ningún Mac:

   ```bash
   # a) Clave privada y CSR, en local. openssl necesita un .cnf minimo porque
   #    el de Windows suele apuntar a una ruta que no existe.
   openssl genrsa -out dist_private_key.pem 2048
   openssl req -new -key dist_private_key.pem -out dist.csr -config openssl_min.cnf

   # b) Subir dist.csr en https://developer.apple.com/account/resources/certificates/add
   #    eligiendo "Apple Distribution", y descargar el .cer

   # c) Convertirlo y empaquetarlo con su clave privada
   openssl x509 -inform DER -in distribution.cer -out dist_cert.pem
   openssl pkcs12 -export -out dist.p12 -inkey dist_private_key.pem -in dist_cert.pem \
     -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg SHA1 -passout pass:LA_QUE_SEA
   ```

   El PBE clásico del último comando no es capricho: es el formato que `security import` de macOS
   lee sin protestar. Y **la clave privada es irremplazable**: Apple no la tiene, así que si se
   pierde hay que revocar el certificado y repetir el proceso.

5. **Cinco secretos en GitHub** (*Settings → Secrets and variables → Actions*):

   | Secreto | Contenido |
   |---|---|
   | `APPSTORE_KEY_ID` | el Key ID, unos 10 caracteres |
   | `APPSTORE_ISSUER_ID` | el Issuer ID, con formato de UUID |
   | `APPSTORE_PRIVATE_KEY` | el contenido **completo** del `.p8`, con sus líneas `-----BEGIN/END PRIVATE KEY-----` |
   | `APPLE_DIST_CERT_P12` | el `.p12` del paso 4 **en base64** (`base64 -w0 dist.p12`) |
   | `APPLE_DIST_CERT_PASSWORD` | la contraseña con la que se exportó ese `.p12` |

**Los provisioning profiles sí los crea Xcode solo**, con la clave de API y
`-allowProvisioningUpdates`. Lo único que no puede conseguir por su cuenta es el certificado de
distribución, y por eso viaja como secreto.

### Renovar el certificado

Caduca **al año**. Cuando expire, el workflow fallará al firmar y hay que repetir el paso 4 completo
—CSR nuevo, portal, `.p12` nuevo— y actualizar los dos secretos. Los archivos del proceso quedaron
en `docs/ios/` (fuera de git): ahí están la clave privada, el `.cer`, el `.p12` y su contraseña.

### Cada vez que se quiera publicar

*Actions → iOS · TestFlight → Run workflow*, indicando el **número de build**, que **debe ser mayor
que el último subido**. La última versión conocida es `1.0.0+10`, así que el siguiente sería `11`.
Si se deja vacío, se usa el de `pubspec.yaml` y TestFlight rechazará el envío si ese número ya
existe.

El `.ipa` queda como artefacto de la ejecución durante 14 días, aunque la subida falle: así un
problema al publicar no obliga a repetir veinte minutos de compilación.

### Variante ad-hoc: un `.ipa` para pasarle a QA

El `.ipa` de TestFlight **no se puede instalar en un teléfono**: está firmado para App Store y solo
lo aceptan App Store y TestFlight. Para entregarle un instalable a alguien de QA hace falta un build
**ad-hoc**, que es otro producto, con su propio perfil.

**Preparación, una sola vez por dispositivo:**

1. **Registrar el dispositivo.** Necesitas su **UDID** (en el iPhone: *Ajustes → General →
   Información*, o conectándolo a un ordenador). Se añade en
   *Certificates, Identifiers & Profiles → Devices → `+`*.
2. **Crear el perfil ad-hoc** en
   [Profiles → `+`](https://developer.apple.com/account/resources/profiles/add): en **Distribution**
   elige **Ad Hoc**, el App ID `co.legacynetwork.legacyapp`, el mismo certificado de distribución, y
   **marca los dispositivos** que podrán instalarlo. Nómbralo exactamente:

   ```
   Legacy Ad Hoc QA
   ```

3. Descárgalo y cárgalo como secreto **`APPLE_PROVISIONING_PROFILE_ADHOC`** (en base64, igual que el
   otro).

**Cada vez que QA necesite una versión:** *Run workflow* con **`tipo_de_build: adhoc`**. No sube
nada a TestFlight —App Store Connect rechazaría ese `.ipa`— y deja el instalable como artefacto de
la ejecución, con el nombre `legacy-ios-adhoc-<n>`.

**Cómo lo instala QA.** El `.ipa` no se instala tocándolo: hace falta una de estas vías:

- **Apple Configurator** (Mac) o **Finder/iTunes** con el teléfono conectado.
- Un servicio de distribución tipo **Diawi** o **InstallOnAir**: se sube el `.ipa` y devuelven un
  enlace que se abre desde el iPhone. Es lo más cómodo si QA está en otra ciudad.

**Un dispositivo que no esté en el perfil no podrá instalarlo**, aunque tenga el archivo: la lista de
UDID va firmada dentro. Añadir un dispositivo nuevo obliga a regenerar el perfil y recargar el
secreto.

> Si QA va a probar a menudo, **TestFlight sale más cómodo**: no exige registrar UDID, admite hasta
> 100 probadores internos y actualiza solo. La vía ad-hoc tiene sentido cuando hace falta un
> instalable sin pasar por la revisión de Apple ni por cuentas de prueba.

### Si falla

Estos son los fallos que costó ocho ejecuciones dejar atrás el 2026-08-06. Ninguno se puede
anticipar desde Windows: casi todos solo aparecen en macOS o contra los servidores de Apple.

| Síntoma | Causa y arreglo |
|---|---|
| `flutter analyze` falla con errores en `build/ios/SourcePackages/...` | En macOS, `pub get` resuelve ahí los Swift Packages y arrastra el código de **ejemplo** de los plugins. Ya está resuelto con `exclude: [build/**]` en `analysis_options.yaml` |
| `MAC verification failed during PKCS12 import (wrong password?)` | Casi nunca es la contraseña: es un `\n` al final del secreto. El workflow ya recorta `\r\n`, pero al recargar el secreto conviene usar `printf '%s'`, no `echo` |
| `No signing certificate "iOS Distribution" found` | Falta el `.p12`, o el secreto no llegó. Apple **no** deja crear certificados de distribución por API |
| `No profiles for 'co.legacynetwork.legacyapp' were found` | Falta el provisioning profile, o su **nombre** no coincide con el de `ExportOptions.plist`. Apple tampoco deja crearlos por API |
| `X does not support provisioning profiles, but provisioning profile ... has been manually specified` | Se pasaron ajustes de firma por línea de comandos a `xcodebuild`: se aplican a **todos** los targets, y los Swift Packages de Firebase o GoogleSignIn no los admiten. La firma va en `ExportOptions.plist`, no en el archive |
| `The file .../Runner.ipa cannot be found` | El `.ipa` toma el nombre del **producto** (`legacy_app.ipa`), no el del target. El workflow ya lo descubre solo |
| `This app was built with the iOS X SDK... must be built with the iOS 26 SDK or later` | Apple subió el SDK mínimo. Hay que cambiar el runner a una imagen con un Xcode más nuevo; el paso "Version de Xcode y SDK" del log dice con cuál se está compilando |
| Build rechazado por número repetido | Subir el número de build. El **11** ya está usado |
| En TestFlight sale *Missing Compliance* | Cuestionario de cifrado; se responde en App Store Connect o se declara `ITSAppUsesNonExemptEncryption` |

**El `.ipa` queda como artefacto de la ejecución aunque la subida falle**, así que un problema al
publicar no obliga a repetir la compilación.

## Web

```bash
./compilar_web.sh        # flutter clean + pub get + flutter build web --release
```

Salida: `build/web/`.

**Hoy no hay ningún host publicando este artefacto.** En `legacy.intelyclick.com` la raíz la sirve
el panel Angular (`legacy_frontend`). Si se quiere publicar la app web hay que decidir primero
dónde: subdominio propio o una ruta enrutada en HAProxy, con su contenedor nginx.

Ten en cuenta que la web usa `localhost` como API salvo que `config.json` diga otra cosa, y que el
backend tiene `CORS AllowedOrigins: "*"` — funcionará desde cualquier origen, pero eso es un
problema de seguridad del backend, no una garantía en la que apoyarse.

## Al cerrar la entrega

Registra el envío en `qa_bitacora.md` con el formato del proyecto: fecha, **Alcance** con los
archivos tocados y **Criterios de QA** numerados y verificables por una persona.
