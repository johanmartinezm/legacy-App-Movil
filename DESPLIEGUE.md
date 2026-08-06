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
4. **Tres secretos en GitHub** (*Settings → Secrets and variables → Actions*):

   | Secreto | Contenido |
   |---|---|
   | `APPSTORE_KEY_ID` | el Key ID, unos 10 caracteres |
   | `APPSTORE_ISSUER_ID` | el Issuer ID, con formato de UUID |
   | `APPSTORE_PRIVATE_KEY` | el contenido **completo** del `.p8`, incluidas las líneas `-----BEGIN PRIVATE KEY-----` y `-----END PRIVATE KEY-----` |

No hace falta exportar ningún `.p12` ni provisioning profile: el workflow usa
`xcodebuild -allowProvisioningUpdates` con esa clave, y Xcode pide a Apple el certificado y el
perfil que necesite. Eso es lo que permite publicar sin tener un Mac.

### Cada vez que se quiera publicar

*Actions → iOS · TestFlight → Run workflow*, indicando el **número de build**, que **debe ser mayor
que el último subido**. La última versión conocida es `1.0.0+10`, así que el siguiente sería `11`.
Si se deja vacío, se usa el de `pubspec.yaml` y TestFlight rechazará el envío si ese número ya
existe.

El `.ipa` queda como artefacto de la ejecución durante 14 días, aunque la subida falle: así un
problema al publicar no obliga a repetir veinte minutos de compilación.

### Si falla

- **La primera ejecución es la que más falla**, casi siempre por firma o por que falte alguno de los
  tres pasos de preparación. Los registros de `xcodebuild` se guardan como artefacto.
- **`No profiles for 'co.legacynetwork.legacyapp' were found`**: la app no está en App Store Connect
  o la clave de API no tiene rol suficiente.
- **Build rechazado por número repetido**: subir el número de build.
- **Aparece en TestFlight como *Missing Compliance***: es el cuestionario de cifrado; se resuelve
  respondiendo en App Store Connect o declarando `ITSAppUsesNonExemptEncryption`.

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
