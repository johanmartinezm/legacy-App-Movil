# Bitácora de QA - Control de Calidad

- [2026-04-21]: Clasificación y Ordenamiento de Programas de Formación
  - Alcance: `program_model.dart`, `programs_screen.dart`, `program_detail_screen.dart`.
  - Criterios de QA: 
    1. Verificar que los programas completos (con "Programa" en el nombre) salgan al inicio.
    2. Verificar que los módulos salgan después de los programas.
    3. Verificar que los cursos salgan al final.
    4. Validar que los badges (Programa, Módulo, Curso) tengan los colores correctos y no desborden.

- [2026-04-21]: Corrección de Renderizado HTML en Detalle de Libro
  - Alcance: `book_detail_screen.dart`.
  - Criterios de QA: Verificar que la descripción del libro no muestre etiquetas como `<p>` o `<strong>` y renderice el formato correctamente.

- [2026-04-21]: Estabilización de Reproductor YouTube (iPhone/Android)
  - Alcance: `video_detail_screen.dart`.
  - Criterios de QA: Verificar que los videos que mostraban Error 152-4 en iPhone ahora carguen correctamente al eliminar el parámetro `origin` restrictivo.

- [2026-06-20]: Manejo Tolerante de Errores SMTP (Asesorías)
  - Alcance: `asesoria_screen.dart`.
  - Criterios de QA: 
    1. Confirmar que el error SMTP `535` devuelto por el backend no interrumpa la navegación del usuario.
    2. Verificar que se muestre el SnackBar informativo dorado.
    3. Asegurar que se transicione exitosamente a la pantalla de confirmación/éxito.

- [2026-06-20]: Rediseño Premium de Detalle de Programa LSO
  - Alcance: `programs_screen.dart`, `program_detail_screen.dart`.
  - Criterios de QA:
    1. Verificar que al presionar una tarjeta de programa en LSO se navegue correctamente al detalle del mismo.
    2. Validar que la pantalla de detalle posea fondo oscuro inmersivo y el gorro académico.
    3. Confirmar que la tabla muestre la información de Formato, Certificación y Cuotas correspondiente.
    4. Comprobar que los botones Inscribirme y Hablar con un asesor realicen sus respectivas acciones.

- [2026-06-21]: Rediseño de Pantalla Confirmar Registro de Evento (EventPaymentScreen)
  - Alcance: `event_payment_screen.dart`
  - Criterios de QA:
    1. Entrar al detalle de un evento de pago y presionar "Reservar cupo · preventa".
    2. Verificar que el fondo de la pantalla cargue con el degradado radial oscuro premium.
    3. Validar la legibilidad de todos los textos (título, datos del participante, precios y total) asegurando un contraste óptimo.
    4. Confirmar que los inputs (`TextFormField`) tengan texto blanco e información perfectamente legible.
    5. Probar el cambio de método de pago (PSE / Tarjeta) y validar el check activo de color turquesa.
    6. Hacer clic en "PROCEDER AL PAGO" y verificar la legibilidad y estética del modal de éxito oscuro.

- [2026-06-21]: Integración de Firebase Core y Notificaciones Push (FCM)
  - Alcance: `pubspec.yaml`, `lib/main.dart`
  - Criterios de QA:
    1. Ejecutar `flutter pub get` y verificar la compilación exitosa sin conflictos de dependencias.
    2. Iniciar la aplicación y validar en los logs de la consola que se imprima el FCM Token formateado entre líneas punteadas.
    3. Probar el envío de una notificación de prueba desde la consola de Firebase usando el Token copiado.
    4. Confirmar la recepción en primer plano (Foreground) visualizando el SnackBar de alerta con el título e información del mensaje.
    5. Validar el procesamiento en segundo plano (Background/Terminated) y que al presionar la notificación la app se abra y registre la acción en los logs.

- [2026-06-21]: Campana de Notificaciones con Badge e Historial E2E
  - Alcance: `lib/domain/providers/notification_provider.dart`, `lib/presentation/screens/notifications/notifications_screen.dart`, `lib/presentation/screens/home/home_content_screen.dart`, `lib/main.dart`
  - Criterios de QA:
    1. Iniciar la aplicación y confirmar la campana superior derecha en la pantalla de Inicio.
    2. Recibir una notificación push (o simular una a través del provider) y comprobar que la campana muestra un numerito (badge dorado) en tiempo real con el conteo de no leídas.
    3. Hacer clic en la campana y verificar que navega a la pantalla de "Notificaciones".
    4. Validar el diseño premium oscuro de la pantalla de Notificaciones.
    5. Comprobar que al entrar a la pantalla de notificaciones, el contador/badge de la campana se limpia (se marcan todas como leídas).
    6. Verificar la acción de borrar notificaciones desde la papelera de la barra superior.

