# Plan de Implementación: Inicio de Sesión Social (Google y Apple)

## 1. Visión General y Lógica de Negocio (Requerimientos)
El sistema debe permitir a los usuarios iniciar sesión utilizando sus cuentas de Google y Apple. 
La regla de negocio estricta indica que:
- **Si el usuario YA existe en la base de datos:** El sistema debe autenticarlo automáticamente y enviarlo al Inicio (`/home`).
- **Si el usuario NO existe:** El sistema debe detectar que es un usuario nuevo y redirigirlo obligatoriamente a la pantalla de Registro (`/register`) para que termine de llenar sus datos personales (Teléfono, Ocupación, Identificación, etc.). Los datos traídos del proveedor (Nombre y Correo) deben estar pre-llenados.

---

## 2. Cambios a Nivel de Base de Datos (PostgreSQL)
Para vincular de forma segura a los usuarios con los proveedores externos, el modelo `User` y la tabla `users` necesitan columnas específicas que almacenen los IDs únicos de Google y Apple.

### Script SQL a ejecutar en el Servidor:
```sql
-- 1. Añadir columnas de vinculación externa
ALTER TABLE users ADD COLUMN google_id VARCHAR(255) UNIQUE;
ALTER TABLE users ADD COLUMN apple_id VARCHAR(255) UNIQUE;

-- 2. Modificar el requerimiento de contraseña
-- Como los usuarios sociales no crean contraseña, este campo no puede ser NOT NULL absoluto a menos que se inyecte un hash aleatorio.
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
```

---

## 3. Desarrollo Backend (Go / Arquitectura Hexagonal)

### 3.1. Actualización de Modelos (`internal/core/domain/user.go`)
```go
type User struct {
    // ... campos existentes ...
    GoogleID *string `json:"google_id" db:"google_id"`
    AppleID  *string `json:"apple_id" db:"apple_id"`
}
```

### 3.2. Nuevo Endpoint HTTP: `POST /api/auth/social-login`
Crear este endpoint en el `AuthHandler` con el siguiente flujo:
1. **Recibir Body:** `{"provider": "google|apple", "id_token": "token_largo_del_dispositivo"}`
2. **Validar Token:** Usar las librerías oficiales de Google/Apple en Go para decodificar y validar que el token sea verídico y no haya expirado.
3. **Extraer Correo:** Extraer el email y el nombre seguro validado por Google/Apple.
4. **Consulta a Base de Datos:** Buscar al usuario en la BD utilizando la lógica de `EmailBlindIndex` o el sistema de encriptación existente de Legacy.
5. **Decisión de Flujo:**
    *   **Si el usuario existe:** Actualizar su registro en DB insertándole el `GoogleID` o `AppleID` (si estaba nulo). Generar el token JWT del sistema y retornar un `200 OK`.
    *   **Si NO existe:** Retornar un `404 Not Found` (o código personalizado `403 UserNotRegistered`). El JSON de respuesta debe incluir el `email` y `name` que Google/Apple arrojó, para que la App Móvil los use.

### 3.3. Modificar Endpoint de Registro: `POST /api/auth/register`
*   Si el body recibe el parámetro adicional `google_id` o `apple_id`, el sistema debe permitir que el campo `password` venga vacío (o el backend le asignará un hash aleatorio criptográficamente seguro).

---

## 4. Desarrollo App Móvil (Flutter)

### 4.1. Instalación de Dependencias (`pubspec.yaml`)
Agregar los paquetes oficiales:
*   `google_sign_in: ^6.2.1`
*   `sign_in_with_apple: ^6.1.1`

### 4.2. Configuraciones Nativas
*   **Android (`android/app/build.gradle` y Consola de Google):** Agregar el SHA-1 de producción y desarrollo en Google Cloud Console para autorizar la app. Descargar el `google-services.json`.
*   **iOS (Xcode y `Info.plist`):** Agregar el "URL Scheme" inverso de Google. Entrar a Xcode y agregar la capacidad oficial (*Capability*) de **"Sign in with Apple"** al proyecto. 

### 4.3. Modificaciones en la Interfaz Gráfica (UI)
*   **Pantalla de Login (`login_screen.dart`):** Agregar dos botones con los logos oficiales (Google y Apple). Apple SignIn sólo se mostrará si la plataforma es iOS (usando `Platform.isIOS`).
*   **Pantalla de Registro (`register_screen.dart`):** Ajustar la pantalla para que reciba parámetros por la URL (usando GoRouter). Si recibe nombre y correo, rellenar los `TextEditingController` de esos campos y bloquear el cuadro de "Correo Electrónico" para que sea de "Sólo Lectura" (`readOnly: true`).

### 4.4. Conexión de Estado (Providers / Services)
*   Implementar una función `socialLoginRequest(provider)` en `AuthProvider`.
*   **Manejo de Errores (Redirección):**
    Al hacer la llamada al backend, el `auth_service.dart` debe interceptar la respuesta:
    ```dart
    if (response.statusCode == 200) {
       // Guardar token JWT localmente, redirigir al Home
       context.go('/home');
    } else if (response.statusCode == 404) {
       // El usuario no existe en la base de datos
       final socialEmail = response.data['email'];
       final socialName = response.data['name'];
       
       // Redirigir a registro inyectando variables por URL
       context.push('/register?email=$socialEmail&name=$socialName&provider=$provider');
    }
    ```

---

## 5. Requerimientos de Credenciales para el Cliente (Legacy)
Para poder ejecutar este desarrollo, el cliente debe proveer lo siguiente:
1.  **Acceso a Google Cloud Console:** Para generar el "OAuth 2.0 Client ID" de iOS y Android.
2.  **Cuenta de Apple Developer:** Activa y pagada para configurar el "Services ID" y el "Key .p8" necesario para desencriptar los tokens de Apple en el servidor Go.
