---
name: preflight-release
description: Comprobaciones obligatorias antes de compilar o publicar la app Flutter (APK, AAB o IPA). Verifica firma contra Firebase, entitlements de iOS, entorno del config.json y compatibilidad JDK/Gradle. Usar antes de cualquier flutter build de release o de subir a Play Store o App Store.
---

# Comprobaciones previas a un release móvil

Cada punto de esta lista corresponde a un fallo real que ya ocurrió en este proyecto. Ejecútalos
**antes** de lanzar el build: todos fallan tarde y caro.

## 1. Compatibilidad JDK / Gradle

```bash
flutter doctor -v 2>&1 | grep -i "Java version"
grep distributionUrl android/gradle/wrapper/gradle-wrapper.properties
```

Gradle 8.12 **no soporta Java 25**, que es el que trae la última Android Studio. El síntoma es
desconcertante: el build falla con un mensaje que es solo el número de versión (`25.0.2`), sin
explicación.

Este proyecto usa Temurin JDK 21, fijado con `flutter config --jdk-dir`. Si el build falla así,
verifica que Flutter siga apuntando ahí y no al JDK de Android Studio.

## 2. A qué entorno apunta la app

```bash
cat assets/config/config.json
```

**Por defecto apunta a producción** (`https://legacy.intelyclick.com`). Hay tres variantes en la
misma carpeta y se cambian copiando una sobre otra:

- Release → `config.json` con URLs de producción
- Desarrollo → copiar `config.json.develop` encima

Confirma que el entorno sea el que quieres **antes** de compilar. Un APK de pruebas apuntando a
producción escribe en la base de datos real.

## 3. Firma Android contra Firebase

```bash
export JAVA_HOME="/c/Program Files/Eclipse Adoptium/jdk-21.0.12.8-hotspot"
"$JAVA_HOME/bin/keytool" -list -v -keystore android/app/upload-keystore.jks -alias upload \
  -storepass <clave> 2>/dev/null | grep "SHA1:"

grep -o '"certificate_hash": "[^"]*"' android/app/google-services.json
```

**Las dos huellas deben coincidir.** Si no, Google Sign-In falla en el build de release con
`DEVELOPER_ERROR` (código 10), aunque todo lo demás funcione.

Firebase admite varias huellas y conviene registrar las tres:

| Huella | Para qué |
|---|---|
| `upload-keystore.jks` | APK instalado directamente |
| Play App Signing (Play Console → Integridad de la app) | Descargas desde Play Store |
| `debug.keystore` de cada equipo | Desarrollo diario |

## 4. Google Sign-In necesita `serverClientId`

```bash
grep -n "GoogleSignIn.instance.initialize" lib/domain/providers/auth_provider.dart
```

Debe pasar `serverClientId` con el cliente **web** (`client_type: 3`) de `google-services.json`,
que es el mismo que valida el backend en `config.yaml`. Sin él, el `idToken` de Android no lleva el
`aud` correcto y el servidor rechaza el login aunque el usuario entre bien en el dispositivo.

## 5. iOS: entitlements y versión mínima

```bash
cat ios/Runner/Runner.entitlements
grep -n "IPHONEOS_DEPLOYMENT_TARGET" ios/Runner.xcodeproj/project.pbxproj | head -1
grep -n "^platform" ios/Podfile
```

- `aps-environment` debe ser **`production`** para TestFlight y App Store. Con `development` las
  notificaciones push no llegan en builds distribuidos.
- Debe existir `com.apple.developer.applesignin`. Como la app ofrece login con Google, la directriz
  4.8 de App Store **obliga** a ofrecer también Sign in with Apple; sin el entitlement falla y el
  envío es candidato a rechazo.
- El deployment target del proyecto Xcode y el `platform` del `Podfile` deben coincidir. Firebase
  4.x y `google_sign_in` 7 exigen iOS 15+.
- Conviene declarar `ITSAppUsesNonExemptEncryption` en `Info.plist` para no responder el
  cuestionario de cumplimiento de exportación en cada subida.

## 6. Tráfico en claro en Android

```bash
grep -n "usesCleartextTraffic" android/app/src/main/AndroidManifest.xml
```

Está en `true`, lo que permite HTTP sin cifrar. Debe quitarse antes de publicar.

## Compilar

```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols   # APK
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols  # Play Store
```

**No confíes en el código de salida si canalizas la salida.** `flutter build ... | tail` devuelve el
código de `tail`, no el de Gradle: un build fallido parece exitoso. Usa `${PIPESTATUS[0]}` o no
canalices.

Verifica siempre el artefacto en disco y su firma:

```bash
ls -la build/app/outputs/flutter-apk/
"$ANDROID_SDK/build-tools/36.0.0/apksigner.bat" verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

El certificado debe decir `CN=Legacy Network`. Si dice `CN=Android Debug`, se firmó con la clave de
debug y no sirve para distribuir.

Guarda `build/app/outputs/symbols/` junto al artefacto: con `--obfuscate`, sin esos símbolos los
stack traces de producción son ilegibles.

## iOS solo se compila en macOS

No hay forma de generar un `.ipa` desde Windows. Las salidas son un Mac con Xcode, o CI con runners
macOS (Codemagic, GitHub Actions `macos-latest`, Bitrise, Xcode Cloud). En cualquier caso hace falta
la cuenta de Apple Developer; el equipo de firma ya está configurado en el proyecto.

```bash
cd ios && pod install && cd ..
flutter build ipa --release --obfuscate --split-debug-info=build/ios/symbols
```
