# Documentación Técnica: Implementación de Firebase y Autenticación Híbrida

Este documento sirve como **Blueprint (Plano Maestro)** para la integración de Firebase en proyectos **legacy**, diseñado para evitar reprocesos y fallos comunes en entornos Flutter + Go + Web.

---

## 1. Arquitectura de Autenticación (Flujo Híbrido)

### Flujo de Comunicación
1.  **Frontend (Flutter):** 
    *   Obtiene el `idToken` mediante `GoogleSignIn`.
    *   *Importante:* En Web se requiere el `clientId`, en móvil debe ser `null`.
2.  **Middleware (HTTPS):** Envía el token al backend en el header `Authorization: Bearer <token>`.
3.  **Backend (Go):** 
    *   Valida el token con `auth.VerifyIDToken`.
    *   Extrae datos confiables del usuario (email, UID, nombre).
    *   Genera un JWT propio para la sesión de la API.

---

## 2. Blueprint: Implementación en Backend (Go)

### Inicialización del Admin SDK
Para nuevos proyectos, use este patrón de inicialización agnóstico:
```go
// Pattern: Firebase Admin Init
func InitFirebase(serviceAccountPath string) (*firebase.App, error) {
    opt := option.WithCredentialsFile(serviceAccountPath)
    return firebase.NewApp(context.Background(), nil, opt)
}

// Pattern: Verify ID Token
func VerifyToken(ctx context.Context, app *firebase.App, idToken string) (*auth.Token, error) {
    client, _ := app.Auth(ctx)
    return client.VerifyIDToken(ctx, idToken)
}
```

---

## 3. Blueprint: Implementación en Frontend (Flutter)

### Inicialización Segura (main.dart)
Para evitar la "pantalla en blanco" en Web, use siempre un patrón asíncrono no bloqueante:
```dart
Future<void> initFirebase() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // El renderizado NO debe detenerse si Firebase falla (ej. bloqueadores de ads)
    debugPrint("Firebase Init Skip: $e");
  }
}
```

### Configuración de Google Sign-In
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: kIsWeb ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com' : null,
  scopes: ['email', 'profile'],
);
```

---

## 4. Requisitos Críticos para Web (PWA)

### A. Service Worker
Para soporte de notificaciones push y persistencia, el archivo `web/firebase-messaging-sw.js` debe existir con la configuración del proyecto:
```javascript
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');
firebase.initializeApp({ /* config values */ });
```

### B. Headers de Seguridad y CORS
El backend **DEBE** permitir el origen de la web dinámicamente si se usan credenciales:
*   **Permitido:** `Access-Control-Allow-Origin: https://tudominio.com` + `Access-Control-Allow-Credentials: true`.
*   **Prohibido:** `Access-Control-Allow-Origin: *` + `Access-Control-Allow-Credentials: true`.

---

## 5. Troubleshooting Matrix (Tabla de Errores Comunes)

| Error | Causa Probable | Solución |
| :--- | :--- | :--- |
| `popup_closed_by_user` | El usuario cerró el popup de Google antes de terminar. | Manejar la excepción en el `try-catch` del provider. |
| `idpiframe_initialization_failed` | Origen no registrado en Google Cloud Console. | Añadir `localhost` o dominio a "Orígenes de JS autorizados". |
| `401 Unauthorized` (Backend) | El token de Firebase expiró o es de un proyecto distinto. | Usar `user.getIdToken(true)` para forzar refresco antes de cada llamada. |
| Pantalla blanca en Web | Bloqueo síncrono en `main()`. | Mover la inicialización a un bloque `try-catch` asíncrono. |

---

## 6. Seguridad y CI/CD

1.  **Secretos:** NUNCA subas `adminsdk.json` o `google-services.json` a repositorios públicos. Úsalos como variables de entorno base64 en GitHub Actions o GitLab CI.
2.  **Producción:** Asegúrate de que los "Redirect URIs" en Google Cloud Console apunten a las URLs finales de producción y no solo a localhost.
3.  **Scopes:** Solicita solo la información mínima necesaria (`email`, `profile`) para mejorar la tasa de conversión en el login.

---
*Este documento es el estándar de oro para implementaciones de Firebase en legacy. Sígalo estrictamente para garantizar estabilidad multiplataforma.*
