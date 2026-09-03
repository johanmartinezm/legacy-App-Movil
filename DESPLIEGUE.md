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

**Diferencia entre las tres variantes.** Comprobado el 2026-08-25: `config.json` y `config.json.prod`
son **idénticos**, y lo único que cambia en `config.json.develop` es a qué API apunta.

| Clave | `config.json` y `.prod` | `config.json.develop` |
|---|---|---|
| `api_url_web` / `api_url_ios` | `https://legacy.intelyclick.com` | `http://localhost:8080` |
| `api_url_android` | `https://legacy.intelyclick.com` | `http://10.0.2.2:8080` |
| `environment` | `production` | `development` |

Los dos GraphQL externos (`graphql_url` a `lso.school` y `content_graphql_url` a
`legacynetworkco.com`) son **los mismos en las tres**.

Hasta el 2026-08-25 esta sección afirmaba que `.prod` apuntaba a `app.legacynetworkco.com/lso-api` y
`/content-api`. No es así, y esos dominios no responden. Si alguien los necesita alguna vez, hay que
volver a crearlos: no están en ninguna de las tres variantes.

**El archivo activo apunta a producción.** Para trabajar en local hay que copiar `config.json.develop`
encima de `config.json` — y acordarse de deshacerlo antes de compilar un release.

## 2. Subir la versión

```bash
grep '^version:' pubspec.yaml     # el número real, no el que ponga aquí
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

## Notificaciones push en iOS

Tres piezas, y con que falte una no llega ni un aviso. Las tres quedaron resueltas el 2026-08-12:

| Pieza | Dónde | Estado |
|---|---|---|
| App registrada en Firebase con el bundle real | Firebase, proyecto `app-legacy-848f1` | `co.legacynetwork.legacyapp` |
| Configuración que usa la app | `lib/firebase_options.dart` | **es la que manda**, no el `.plist` |
| Clave APNs subida a Firebase | Cloud Messaging | `AuthKey_6W3PXQC2A6.p8`, Key ID `6W3PXQC2A6`, Team ID `87LBVBLK8T` |

**`firebase_options.dart` es lo que manda, no `GoogleService-Info.plist`.** `main.dart` inicializa
con `DefaultFirebaseOptions.currentPlatform`, así que reemplazar solo el `.plist` no cambia nada.
Hasta el 2026-08-12 ese archivo declaraba `com.example.legacyApp` —el identificador de ejemplo de
Flutter— y las notificaciones de iOS se registraban contra una app que no era la instalada. En
Android nunca falló, que es donde se probaban.

Al cambiar de app en Firebase, el `REVERSED_CLIENT_ID` cambia y hay que reflejarlo **a mano** en el
esquema de URL de `ios/Runner/Info.plist`, o el acceso con Google deja de volver a la aplicación.

**No confundir las dos claves `.p8`:** `AuthKey_H4DGAZR68T.p8` es la de App Store Connect API, la que
usa el workflow para subir builds. `AuthKey_6W3PXQC2A6.p8` es la de APNs. Apple solo permite dos
claves APNs por cuenta y **cada una se descarga una única vez**; ambas viven en `docs/ios/` **de la raíz del monorepo** (no en `App-Movil/`), fuera de
git.

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

3. ~~Falta `com.apple.developer.applesignin`~~ → ya declarado en `Runner.entitlements` (`Default`),
   con la capability *Sign in with Apple* habilitada en el App ID. La app ofrece login con Google y
   la directriz **4.8** obliga entonces a ofrecer también el de Apple. **Si alguna vez hay que
   rehacerlo, el orden importa:** primero la capability en el App ID desde el portal, y solo después
   la clave en el entitlements — al revés la firma falla, porque el perfil no la incluye.
4. ~~`ITSAppUsesNonExemptEncryption` sin declarar~~ → `false` en `Info.plist` desde el 2026-08-10, así
   que cada build deja de quedar en *Missing Compliance*. Es una **declaración legal** sobre el
   cifrado de la app: vale `false` porque la app no cifra por su cuenta —solo HTTPS y el Keychain—, y
   el AES-256 vive en el backend. Si eso cambia, hay que revisarla.

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
en `docs/ios/` de la raíz del monorepo, no en `App-Movil/` (y fuera de git): ahí están la clave privada, el `.cer`, el `.p12` y su contraseña.

### Cada vez que se quiera publicar

*Actions → iOS · TestFlight → Run workflow*, indicando el **número de build**, que **debe ser mayor
que el último subido**. Si se deja vacío, se usa el de `pubspec.yaml` y TestFlight rechazará el envío
si ese número ya existe.

**No confíes en ningún número escrito en este archivo**: se queda viejo enseguida. El que manda es el
de `pubspec.yaml`, y el último realmente subido se mira en TestFlight o en Play Console. Al 2026-09-02
`pubspec.yaml` va por `1.0.0+19`, y **ese número ya está ocupado en App Store Connect**: la ejecución
del 2026-08-22 se lanzó sin `subir_a_testflight=false` y terminó con `UPLOAD SUCCEEDED`. El próximo
envío arranca por tanto en `+20`.

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
| Build rechazado por número repetido | Subir el número de build. Al 2026-09-02 el último ocupado es el **19** |
| En TestFlight sale *Missing Compliance* | Cuestionario de cifrado; se responde en App Store Connect o se declara `ITSAppUsesNonExemptEncryption` |

**El `.ipa` queda como artefacto de la ejecución aunque la subida falle**, así que un problema al
publicar no obliga a repetir la compilación.

## Requisitos de ficha, comunes a las dos tiendas

Nada de esta sección es código; se rellena en Play Console y en App Store Connect. Desde el
2026-09-02 **ya no queda aquí nada que dependa de terceros**: los textos legales que faltaban están
publicados.

### Política de privacidad

```text
https://legacynetworkco.com/politica-de-privacidad/
```

Va en el campo *Privacy Policy URL* de las dos fichas.

**Ya cubre la app.** Verificado contra la página publicada el 2026-09-02: trae el numeral 6,
«Tratamiento de datos personales a través de la aplicación móvil Legacy», que era exactamente lo que
faltaba. Con eso desaparecen los dos problemas que tenía la versión corporativa:

1. **6.1 lista los datos que recoge la app** —nombre, correo, teléfono, tipo y número de documento,
   fecha de nacimiento, alias, foto, inscripciones y asistencia, compras de eventos, identificador de
   dispositivo para las notificaciones— y dice expresamente que la app **no accede a GPS** y **no usa
   publicidad, rastreo ni analítica**, aclarando que las demás categorías que menciona la política
   (salud, biométricos, centrales de riesgo) **no se recogen a través de la app**. Esa separación es
   la que permite responder los cuestionarios sin contradecir lo publicado.
2. **6.3 nombra a los terceros**: Google y Apple para el acceso, Firebase para las notificaciones y
   Credibanco para los pagos, aclarando que los datos de tarjeta no los almacena Legacy Network.

Los cuestionarios *App Privacy* y *Data Safety* se responden con esa lista —nombre, correo, teléfono,
alias, bio, foto, tokens FCM y el pago por Credibanco—. **No declares salud ni biométricos** aunque
la parte corporativa de la política los mencione: dispara requisitos adicionales que aquí no aplican,
y la propia política ya dice que la app no los toca.

### Eliminación de cuenta

Apple se cubre con el borrado dentro de la app (`DELETE /api/me`, implementado el 2026-08-06).
**Google Play exige además una URL pública** donde se pueda solicitar la eliminación sin instalar la
app, en *Play Console → Contenido de la app → Eliminación de datos*.

**Sirve la misma URL de la política.** Su numeral **6.6** ya describe el procedimiento real: Perfil →
«Eliminar mi cuenta», el mecanismo de confirmación, y la cuenta **anonimizada de forma inmediata**.
Dice también qué se conserva anonimizado —las inscripciones y los mensajes de chat, para que la otra
persona siga viendo su conversación—, que el nuevo registro con el mismo correo crea una cuenta
distinta, y deja el correo de soporte como vía alterna para quien ya desinstaló la app. Los T&C
publicados dicen lo mismo en su **cláusula 13.1**, que también apareció.

No hay página dedicada: `/eliminar-cuenta/`, `/eliminacion-de-datos/` y las dos variantes de
«autorización» responden **404** (comprobado el 2026-09-02). Si algún día se crea una, tiene que
seguir diciendo *inmediata*: el borrador de los **5 días hábiles** que circuló en agosto describe un
trámite por correo que la app no hace desde el 2026-08-06.

### Lo que falta para enviar

Revisado el 2026-09-02. Todo lo que queda se hace desde aquí, sin esperar a nadie.

- **Subir el número de build.** `pubspec.yaml` está en `1.0.0+19` y el **+19 ya se usó** en el
  TestFlight del 22-08. Un envío nuevo empieza por dejarlo en `+20`.
- **Cuestionario App Privacy (Apple) y Data Safety (Google).** Ya se pueden responder: la lista de
  datos está arriba y la política publicada ya no la contradice. Era el bloqueo principal.
- **Capturas y activos de ficha: hechos** (2026-08-25). Están en `reports/capturas_20260825/ficha/`:
  cinco pantallas en `appstore_69/` (1320×2868) y en `play/` (1242×2208) —Inicio, Eventos, Mi
  credencial, Legacy Knowledge y Legacy+—, más `grafico_funciones_1024x500.png`, obligatorio en Play,
  y `icono_512x512.png`. Se capturaron contra un **entorno local con datos inventados**, no contra
  producción: no aparece ninguna persona real ni ningún QR de check-in auténtico. El `LEEME.md` de esa
  carpeta explica cómo regenerarlas. Ojo: `reports/` está fuera de git, así que esas imágenes no
  viajan con el repositorio.
- **Textos de ficha:** hay borradores —nombre, subtítulo, descripción corta, palabras clave y
  descripción completa— con el recuento de caracteres ya medido contra el límite de cada tienda, en
  `reports/capturas_20260825/textos_ficha.py`. Falta pegarlos y decidir categoría y clasificación por
  edad, coherente con el límite de mayoría de edad de los T&C.
- **Probar el login con Google y con Apple en iOS.** En Android quedó verificado el 2026-08-26
  (hallazgo F7, en `qa_bitacora.md`). Los cuatro casos de iOS —entrar y registrarse, con cada
  proveedor— siguen **sin ejecutar por falta de hardware**, y es lo primero que toca un revisor.
- **Icono de la ficha:** el del build (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`) está bien,
  sin canal alfa. Pero `assets/images/flutter_icons/ios/Icon-1024.png` **sí lo tiene**, y App Store
  rechaza el icono con alfa — no tomes ese para la ficha.
- **La cuenta de demo del revisor**: renombrar el evento `[PRUEBA QA] Evento gratuito de
  verificacion` al que está inscrita, porque ese nombre le sale en la credencial, y cargar sus
  credenciales en *App Store Connect → App Review Information*.
- **Decisión de negocio abierta**: los T&C publicados siguen ofreciendo eventos "virtuales o
  presenciales" —comprobado el 2026-09-02—, y un evento virtual es contenido digital que la directriz
  **3.1.1** obliga a cobrar dentro de la app. El esquema tampoco distingue modalidad. No bloquea el
  envío, pero es lo que más probablemente provoque un rechazo.

**Ya resuelto, no lo vuelvas a buscar:** el apartado de la app en la política de privacidad y la
cláusula 13.1 de los T&C, publicados y verificados el 2026-09-02; las capturas y el gráfico de
funciones; cuenta de demo creada y verificada en producción (`reports/20260812_cuenta_demo_apple.md`);
`ITSAppUsesNonExemptEncryption` en `false`; `com.apple.developer.applesignin` declarado; bloquear y
reportar personas (directriz 1.2); eliminar cuenta desde la app (directriz 5.1.1(v)); y la prueba
cerrada de 14 días de Play, que **no aplica** por ser cuenta de Organización.

## Web

```bash
./compilar_web.sh        # flutter clean + pub get + flutter build web --release
```

Salida: `build/web/`.

**Hoy no hay ningún host publicando este artefacto.** En `legacy.intelyclick.com` la raíz la sirve
el panel Angular (`legacy_frontend`). Si se quiere publicar la app web hay que decidir primero
dónde: subdominio propio o una ruta enrutada en HAProxy, con su contenedor nginx.

Ten en cuenta que la web usa `localhost` como API salvo que `config.json` diga otra cosa, y que el
backend **ya no acepta cualquier origen**: `main.go` filtra con `origenPermitido`, que solo deja pasar
`https://legacy.intelyclick.com` y cualquier `localhost` (comprobado contra producción el 2026-08-26).
Si la app web se publica en otro dominio, hay que añadirlo a `origenesDeConfianza` o el navegador
bloqueará todas las llamadas.

## Al cerrar la entrega

Registra el envío en `qa_bitacora.md` con el formato del proyecto: fecha, **Alcance** con los
archivos tocados y **Criterios de QA** numerados y verificables por una persona.
