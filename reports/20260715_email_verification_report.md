# Reporte Técnico: Flujo de Verificación de Correo (App Móvil - Flutter)

**Fecha:** 2026-07-15
**Autor:** Antigravity / IA Arquitecto

## Cambios Realizados
1. **Capa de Servicios y Providers:** 
   - `auth_service.dart`: Añadido método `resendVerificationEmail(email)` que invoca `/api/resend-verification`.
   - `auth_provider.dart`: Añadido `resendVerificationEmail` que maneja el estado de carga y devuelve booleano según éxito de la operación.
2. **Registro de Usuario (`register_screen.dart`):**
   - Tras recibir respuesta exitosa 201 Created del backend, se intercepta la redirección directa al login y en su lugar se pinta un `AlertDialog` notificando al usuario revisar su bandeja de entrada (incluyendo la advertencia sobre SPAM).
3. **Inicio de Sesión (`login_screen.dart`):**
   - El Provider ahora detecta si la falla devuelve `email_not_verified`.
   - Al detectar este fallo, se despliega un Dialog ofreciendo cancelar o "Reenviar correo", enlazado a la función agregada. Un Snackbar inferior reporta el resultado de la petición de reenvío.

## Impacto UX
- El usuario siempre queda guiado; los flujos ciegos (como un error abstracto) se redujeron, ofreciendo rutas de mitigación desde la propia aplicación sin requerir contactar soporte.
