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

Dos cosas hay que arreglar antes de un envío:

1. **`ios/Runner/Runner.entitlements` tiene `aps-environment` en `development`.** Debe ser
   `production` para TestFlight y App Store; con `development` las notificaciones push no llegan en
   builds distribuidos. Falta además `com.apple.developer.applesignin`: como la app ofrece login con
   Google, la directriz 4.8 obliga a ofrecer también Sign in with Apple.
2. **El deployment target está desalineado.** `project.pbxproj` declara
   `IPHONEOS_DEPLOYMENT_TARGET = 13.0` y el `Podfile` declara `platform :ios, '15.0'`. Firebase 4.x y
   `google_sign_in` 7 exigen iOS 15+: hay que subir el proyecto Xcode a 15.0 para que coincidan.

Conviene declarar `ITSAppUsesNonExemptEncryption` en `Info.plist` para no responder el cuestionario
de cumplimiento de exportación en cada subida.

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
