# Configuración de Firebase para Inicio de Sesión Social

Para poder ejecutar la implementación de Google Sign-In y Apple Sign-In, es un pre-requisito estricto que el proyecto de Firebase esté correctamente configurado. Firebase actúa como el puente de autenticación nativo, especialmente para Google.

## Pasos a realizar en la Consola de Firebase

### 1. Habilitar Authentication
1. Ingresar a la [Consola de Firebase](https://console.firebase.google.com/).
2. Seleccionar el proyecto `Legacy App`.
3. Ir al menú lateral izquierdo: **Build > Authentication**.
4. Clic en la pestaña **Sign-in method** (Métodos de inicio de sesión).
5. Añadir nuevos proveedores:
   *   **Google:** Habilitarlo. Te pedirá seleccionar un correo electrónico de soporte del proyecto.
   *   **Apple:** Habilitarlo. Te pedirá el `Service ID`, `Team ID` y la llave privada `.p8` que se debe generar previamente en la cuenta de Apple Developer. 
       *Nota: Configura la siguiente URL de devolución de llamada en la consola de desarrollador de Apple:* `https://app-legacy-848f1.firebaseapp.com/__/auth/handler`

### 2. Configurar Android (Huellas SHA)
Para que Google Sign-In funcione en Android sin arrojar el error `DEVELOPER_ERROR`, Google necesita verificar las huellas digitales de la aplicación.
1. Ir al icono de **Engranaje (Configuración del Proyecto) > General**.
2. En la sección "Tus aplicaciones", seleccionar la app de **Android**.
3. Buscar la sección **Huellas digitales del certificado SHA**.
4. Añadir dos (2) huellas:
   *   **SHA-1 de Debug:** Para que los desarrolladores puedan probar en sus computadores.
   *   **SHA-1 de Release (Producción):** El código que genera la Google Play Console cuando la app se sube a la tienda.
5. Tras añadir los SHA-1, volver a descargar el archivo `google-services.json` y reemplazarlo en el código fuente de la app (`android/app/google-services.json`).

### 3. Configurar iOS (Info.plist)
1. En la misma ventana de "Configuración del Proyecto", selecciona la app de **iOS**.
2. Descarga el archivo `GoogleService-Info.plist`.
3. Reemplázalo en el código fuente (`ios/Runner/GoogleService-Info.plist`).
4. Abre ese archivo y copia el valor de `REVERSED_CLIENT_ID`.
5. Ese valor debe ser pegado en Xcode, en la sección **URL Types** dentro de la configuración de la aplicación (Info).

### 4. Extraer el Client ID para el Backend (Go)
El servidor en Go necesitará validar que el token de Google que le envía el celular es real y fue emitido específicamente para tu aplicación.
1. En Firebase, ve a **Authentication > Sign-in method > Google**.
2. Despliega el panel de "Configuración de los SDK web".
3. Copia el **ID de cliente web** (Web Client ID).
4. Este ID (que termina en `apps.googleusercontent.com`) es el que deberás configurar en tu base de datos o en tu archivo `config.yaml` del servidor backend para que Go pueda validar las firmas de Google.
