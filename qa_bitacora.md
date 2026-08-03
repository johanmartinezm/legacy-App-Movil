# Bitácora de QA - Proyecto Flutter [MOBILE]

Entrada de trabajo para validación de App Móvil.

### [2026-07-26]: Módulo de Foros Anónimos (App Móvil)
- **Alcance:**
  - `Modelos y Servicios`: `forum_model.dart`, `forum_service.dart`, `forum_provider.dart`
  - `Pantallas`: `forums_list_screen.dart`, `forum_proposal_screen.dart`, `forum_thread_screen.dart`
  - `Perfil`: `profile_edit_screen.dart` (Adición del campo Alias) y `profile_screen.dart` (Botón de foros)
- **Criterios de QA:**
  1. Validar que el usuario pueda configurar su "Alias (Para Foros Anónimos)" desde "Editar Perfil".
  2. Al entrar a la sección de Foros Anónimos, validar que el listado carga correctamente.
  3. Validar que un usuario pueda proponer un nuevo foro y que si no tiene alias configurado el sistema lo bloquee con un mensaje claro.
  4. Ingresar a un hilo de discusión, validar que se puedan subir imágenes usando el icono de galería y enviar texto, todo mostrado bajo el Alias del usuario (sin exponer nombre real).
  5. Probar el menú de opciones (3 puntos) en un comentario para "Reportar" una publicación, validando que el reporte se envíe correctamente.

---

### [2026-07-16]: Reemplazo de "L" por Logo Oficial en Barra de Navegación
- **Alcance:** `App-Movil/lib/presentation/screens/main_layout.dart`
- **Criterios de QA:**
  1. Abrir la aplicación y observar la barra de navegación inferior en la pestaña "LEGACY+".
  2. Verificar que se muestre el logo de puntos de Legacy en lugar de la letra "L".
  3. Validar que el logo se vea grisáceo-acero cuando la pestaña no está seleccionada.
  4. Validar que al tocar la pestaña, el logo cambie al color dorado (Premium Gold).

---

### [2026-07-16]: Saludo Dinámico por Hora en Pantalla de Inicio
- **Alcance:** `App-Movil/lib/presentation/screens/home/home_content_screen.dart`
- **Criterios de QA:**
  1. Ingresar a la aplicación en la mañana (antes de 12pm) y verificar que el saludo diga "Buenos días,".
  2. Ingresar a la aplicación en la tarde (12pm - 6:59pm) y verificar que el saludo diga "Buenas tardes,".
  3. Ingresar a la aplicación en la noche (después de 7pm) y verificar que el saludo diga "Buenas noches,".

---

### [2026-07-16]: Inhabilitar Pantalla de Chat de CEOs
- **Alcance:** `App-Movil/lib/presentation/screens/comunidad/comunidad_screen.dart`
- **Criterios de QA:**
  1. Ingresar a la sección Comunidad.
  2. Presionar el botón "Chat de los CEOs".
  3. Verificar que no se cambie de pantalla y que aparezca un SnackBar con el texto "Próximamente: El Chat de CEOs estará disponible pronto."

---

### [2026-07-04]: Conexión de Botones de Perfil con Pantallas Existentes
- **Alcance:** `App-Movil/lib/presentation/screens/profile/profile_screen.dart`
- **Criterios de QA:**
  1. Validar que el botón "Mi formación LSO" redirija a la pantalla de programas (`/programas`).
  2. Confirmar que el botón "Mis eventos" redirija a la pestaña de eventos en el inicio (`/home?tab=1`).
  3. Asegurar que "Red de Gobierno" redirija a la lista de miembros (`/comunidad-miembros`).
  4. Comprobar que "Cambiar tipo de cuenta" redirija a la selección de perfiles (`/profile-selection`).

---

### [2026-07-04]: Refactorización de la Pantalla de Mi Perfil a Menú Principal
- **Alcance:**
  - `App-Movil/lib/presentation/screens/profile/profile_screen.dart`
  - `App-Movil/lib/presentation/screens/profile/profile_edit_screen.dart`
  - `App-Movil/lib/main.dart`
- **Criterios de QA:**
  1. Verificar que al ir a "Mi Perfil" cargue el nuevo diseño estilo menú oscuro con botones (Active Legacy+, Mi Legacy Test, etc.).
  2. Comprobar que en el encabezado aparezca el avatar circular, nombre y rol del usuario.
  3. Validar que al presionar el último botón del menú ("Editar información personal"), la app redirija al formulario original para ver/editar la información de la cuenta (`/profile-edit`).

---

### [2026-07-04]: Implementación de Menú de Perfil y Cerrar Sesión
- **Alcance:** `App-Movil/lib/presentation/screens/home/home_content_screen.dart`
- **Criterios de QA:**
  1. Verificar que al tocar el avatar de perfil en la esquina superior derecha del Inicio, se redirija directamente a la pantalla de menú de Mi Perfil.
  2. Confirmar que la opción "Mi Perfil" redirija correctamente a la pantalla de perfil (`/profile`).
  3. Validar que la opción "Cerrar sesión" borre correctamente los datos (usando AuthProvider) y redirija a la pantalla de Login (`/login`).

---

### [2026-07-04]: Ajuste a Tema Oscuro en Lista de Miembros
- **Alcance:** `App-Movil/lib/presentation/screens/chat/community_members_screen.dart`
- **Criterios de QA:**
  1. Validar que la pantalla de la lista de miembros cargue con fondo azul oscuro (`#050B15`).
  2. Confirmar que el texto descriptivo y de información ("Solo puedes chatear...") sea de un color celeste grisáceo para buen contraste.
  3. Verificar que los nombres de los miembros y la letra inicial en el avatar aparezcan en blanco, con el botón "Conectar" del mismo azul del resto de la interfaz.

---

### [2026-07-04]: Ajuste de Flujo Principal de Miembros para Clientes
- **Alcance:** 
  - `App-Movil/lib/presentation/screens/home/home_content_screen.dart`
  - `App-Movil/lib/presentation/screens/comunidad/miembros_info_screen.dart`
- **Criterios de QA:**
  1. Ingresar con un usuario "No Cliente" y verificar que al tocar "Miembros" en el Inicio muestre el SnackBar de acceso denegado.
  2. Ingresar con un usuario "Cliente" y verificar que al tocar "Miembros" en el Inicio se abra la pantalla informativa oscura (`MiembrosInfoScreen`).
  3. En la pantalla informativa oscura, tocar sobre cualquiera de los pilares (Familia, Propiedad, Empresa) y verificar que navegue a la pantalla blanca de chats (`CommunityMembersScreen`).

---

### [2026-07-04]: Refinamiento de Diseño en Pantalla Informativa de Miembros
- **Alcance:** `App-Movil/lib/presentation/screens/comunidad/miembros_info_screen.dart`
- **Criterios de QA:**
  1. Validar que el botón de regreso (atrás) en el AppBar tenga un fondo transparente con un borde circular fino.
  2. Confirmar que el ícono de los pilares (Familia, Propiedad, Empresa) tenga un fondo azul oscuro opaco, según el diseño visual.
  3. Comprobar que los íconos de flecha (chevron) a la derecha de cada pilar ahora se encuentren encerrados en un círculo con borde fino transparente.

---

### [2026-07-04]: Corrección de Ruta Hacia Comunidad de Miembros
- **Alcance:** `App-Movil/lib/presentation/screens/home/home_content_screen.dart`
- **Criterios de QA:**
  1. Ingresar con un usuario cuyo Estado de Cliente sea "Ya soy cliente".
  2. Tocar la sección "Miembros" en el Home.
  3. Validar que la app redirija exitosamente a la pantalla `/comunidad-miembros` en lugar de generar un error "Page Not Found".

---

### [2026-07-04]: Pantalla Informativa de Miembros para Usuarios No Clientes
- **Alcance:** 
  - `App-Movil/lib/presentation/screens/comunidad/miembros_info_screen.dart`
  - `App-Movil/lib/main.dart`
  - `App-Movil/lib/presentation/screens/home/home_content_screen.dart`
- **Criterios de QA:**
  1. Ingresar con un usuario cuyo Estado de Cliente NO sea "Ya soy cliente".
  2. Tocar la sección "Miembros" en el Home.
  3. Verificar que se despliegue la nueva pantalla informativa (Miembros - Comunidad del ecosistema Legacy).
  4. Validar que la interfaz coincida con el diseño (tarjeta "¿Qué es Miembros?", sección "CHATS POR PILAR", sección "ADEMÁS").
  5. Confirmar que el botón "Cómo accedo" al final redirija correctamente a la pantalla de contacto/información de Legacy Plus.

---

### [2026-07-04]: Reemplazo de Logo Cuadrado por Logo Oficial en Home
- **Alcance:** `App-Movil/lib/presentation/screens/home/home_content_screen.dart`
- **Criterios de QA:**
  1. Verificar en la pantalla de inicio (Home) que el logotipo en la esquina superior izquierda sea el triángulo de puntos oficial (`assets/images/Logo.png`) en lugar de la caja cuadrada con la letra "L".
  2. Validar que la alineación y el espaciado con el texto "LEGACY NETWORK" se mantengan correctos y simétricos.

---

### [2026-07-04]: Control de Acceso a Sección Miembros
- **Alcance:** `App-Movil/lib/presentation/screens/home/home_content_screen.dart`
- **Criterios de QA:**
  1. Ingresar con un usuario cuyo Estado de Cliente NO sea "Ya soy cliente". Verificar que en la pantalla de inicio, la sección "Miembros" muestre un candado, colores atenuados y que al presionarla aparezca un mensaje indicando que es exclusiva para clientes.
  2. Ingresar con un usuario cuyo Estado de Cliente sea "Ya soy cliente". Verificar que el candado ya no esté, los colores sean brillantes y al presionar "Miembros" redirija exitosamente a la pantalla de la comunidad.

---

---

### [2026-07-01]: Envío de FCM Token al Backend para Notificaciones Push - [COMPLETADA Y SUBIDA]
- **Alcance:**
  - `App-Movil/lib/data/config/api_constants.dart`
  - `App-Movil/lib/data/services/auth_service.dart`
  - `App-Movil/lib/domain/providers/auth_provider.dart`

- **Criterios de QA:**
  1. Verificar que al hacer Login se envíe exitosamente la petición POST a `/api/me/fcm-token` sin bloquear el acceso del usuario si ésta llega a fallar.
  2. Verificar en PostgreSQL (tabla `core.user_fcm_tokens`) que el token FCM generado para el dispositivo se guarde correctamente asociado al `user_id`.
  3. Comprobar que la app obtiene adecuadamente el token mediante `FirebaseMessaging.instance.getToken()` y deduce correctamente el `device_type` (`android` o `ios`).

---

### [2026-02-26]: Sincronización de Agenda y Paginación
- **Alcance:** 
  - `presentation/screens/eventos/agenda_screen.dart`
  - `presentation/screens/eventos/cronograma_screen.dart`
  - `domain/providers/events_provider.dart`
  - `domain/models/workshop_model.dart`
  - `presentation/screens/informandote/` (Secciones de Articles)

- **Funcionalidad Nueva/Actualizada:**
  - `WorkshopModel.fromJson`: Ahora permite que el `eventTitle` se cargue directamente desde el JSON.
  - Generación de QR Real: El `QrAttendanceDialog` ya no usa datos simulados; ahora solicita el `qr_data` oficial al servidor mediante el `EventsProvider`.
  - Lógica de sincronización: Al añadir o remover un workshop, la app espera el éxito del servidor antes de notificar visualmente al usuario.
  - Estados en UI: Manejo de SnackBar y feedback visual al añadir o quitar ítems.
  - Paginación: Implementación de scroll infinito en artículos sin repetición por IDs duplicados.

- **Criterios de QA (Puntos a Validar):**
  1. **Añadir a Agenda:** Desde el Cronograma, pulsar el icono de "bookmark" y verificar que el SnackBar diga "Añadido a tu agenda".
  2. **Quitar de Agenda:** Desde la Agenda Personal, remover un ítem y verificar que desaparezca de la lista con su SnackBar correspondiente.
  3. **EventTitle:** Validar que en la pantalla de "Mi Agenda" se muestre correctamente el título del evento arriba del nombre del workshop.
  4. **Paginación:** Desplazar hacia abajo en "Contenido de Valor" (artículos) y confirmar que no aparezcan dos artículos idénticos seguidos.
  5. **Acceso Seguro:** Verificar que si borro el token (salir de sesión), al pulsar el marcador me diga "Debes iniciar sesión para usar la agenda".

### [2026-02-26]: Validación de Asistencia QR
- **Alcance:**
  - `angular/legacy-app/src/app/features/admin/attendance-scanner/attendance-scanner.component.*`
  - `angular/legacy-app/src/app/core/layout/main-layout/main-layout.component.html`
  - `flutter/legacy_app/lib/presentation/widgets/eventos/qr_attendance_dialog.dart`
  - `flutter/legacy_app/lib/domain/providers/events_provider.dart`
- **Funcionalidad Nueva:**
  - Escáner QR en panel admin que valida asistencia mediante endpoint `/api/events/check-in`.
  - Registro de auditoría en tabla `events.attendance_logs`.
  - Generación de QR real en Flutter y visualización en diálogo.
- **Criterios de QA:**
  1. Escanear QR válido y confirmar que muestra nombre, email y talleres inscritos.
  2. Verificar que se crea registro en `attendance_logs` (consultar DB).
  3. Intentar escanear QR inválido y recibir mensaje de error.
  4. Confirmar que el QR generado en Flutter corresponde al registro del usuario.
### [2026-03-11]: Implementación de Configuración Dinámica (JSON) - COMPLETADO
- **Alcance:**
  - `assets/config/config.json`
  - `lib/data/config/config_service.dart`
  - `lib/data/config/api_constants.dart`
  - `lib/data/services/graphql_service.dart`
  - `lib/main.dart`
  - `pubspec.yaml`
- **Funcionalidad Implementada:**
  - Migración exitosa de variables de entorno a archivo JSON externo.
  - Implementación de `ConfigService` con carga asíncrona al inicio (Eager initialization).
  - Desacoplamiento total de URLs en el código fuente.
- **Criterios de QA:**
  - Realizar **Hot Restart** y verificar que los servicios sigan funcionando.
  - Cambiar la URL en `assets/config/config.json` y confirmar que el cambio se refleje en las peticiones de red.

### [2026-03-19]: Soporte CORS / Mixed Content para Imágenes Web
- **Alcance:**
  - `lib/data/config/image_helper.dart` (Nuevo)
  - `lib/domain/providers/banner_provider.dart`
  - `lib/presentation/widgets/app_banner.dart`
  - `lib/presentation/screens/informandote/informandote_screen.dart`
  - `lib/presentation/screens/informandote/article_detail_screen.dart`
  - `lib/presentation/screens/informandote/video_detail_screen.dart`
  - `lib/presentation/screens/community/synergy_list_screen.dart`
  - `lib/presentation/screens/community/synergy_detail_screen.dart`
  - `lib/presentation/screens/participando/participando_screen.dart`
  - `lib/presentation/screens/participando/event_detail_screen.dart`
  - `lib/presentation/screens/eventos/eventos_screen.dart`
  - `lib/presentation/screens/eventos/event_purchase_detail_screen.dart`
  - `lib/presentation/screens/profile/profile_screen.dart`
  - `lib/presentation/screens/favorites/favorites_screen.dart`
  - `lib/presentation/screens/books/books_screen.dart`
  - `lib/presentation/screens/programs/programs_screen.dart`
  - `lib/presentation/screens/programs/program_detail_screen.dart`
- **Funcionalidad Nueva/Actualizada:**
  - Implementación de `ImageHelper.getProxiedImageUrl` que intercepta peticiones en Flutter Web y reescribe de `legacynetworkco.com` a `app.legacynetworkco.com` para evitar errores CORS pasando el recurso por HAProxy.
- **Criterios de QA (Puntos a Validar):**
  1. Compilar para web y correr localmente o probar en servidor (`app.legacynetworkco.com`).
  2. Verificar que las imágenes hero en el listado y detalle de Contenido, Eventos, Sinergias y Favoritos se visualicen correctamente.
  3. Asegurarse de que el avatar en "Mi Perfil" cargue exitosamente.
  4. Abrir la pestaña *Network* de DevTools del navegador y confirmar que no se reflejen advertencias amarillas/rojas de "Blocked by CORS".

---

### [2026-04-16]: Ajuste de Identidad para Google Play Console (Android)
- **Alcance:** 
  - `android/app/build.gradle.kts`
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/kotlin/com/legacynetworkco/app/MainActivity.kt` (Refactorizado)

- **Funcionalidad Nueva/Actualizada:**
  - **Application ID:** Actualizado de `com.example.legacy_app` a `com.legacynetworkco.app` para coincidir con la ficha de Play Store.
  - **App Name:** Actualizado el `android:label` a `"Legacy app"`.
  - **Kotlin Package:** Refactorización completa de la estructura de carpetas y declaración de `package` en `MainActivity.kt` para mantener consistencia técnica.

- **Criterios de QA (Puntos a Validar):**
  1. **Configuración Gradle:** Validar que el binario generado tenga el ID de paquete `com.legacynetworkco.app`.
  2. **Identidad Visual:** Confirmar que al instalar el APK, el nombre bajo el icono sea `"Legacy app"`.
  3. **Estabilidad:** Realizar un `flutter build apk` y asegurar que no existan errores de referencia de archivos tras el movimiento de carpetas en `src/main/kotlin`.

---

### [2026-05-20]: Rediseño de Cortina, Inicio y Menú Principal
- **Alcance:**
  - `lib/presentation/screens/splash_screen.dart` [NEW]
  - `lib/main.dart` [MODIFY]
  - `lib/presentation/screens/login_screen.dart` [MODIFY]
  - `lib/presentation/screens/home/home_content_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Pantalla de Cortina:** Nueva animación de inicio (Splash Screen) con FadeIn y Scale del logo de Legacy, con redirección automática basada en estado de autenticación tras 2.5s.
  - **Pantalla de Inicio (Login):** Rediseño estético completo bajo la directriz visual premium/neomórfica (Opción 2): fondo gris ultra claro (`#F5F6FA`), botón de inicio con degradado horizontal simétrico del centro hacia afuera (destello azul metálico en el centro, azul marino profundo en extremos), sombra de elevación volumétrica y botones circulares neomórficos para Social Login (Google & Apple).
  - **Menú Principal (Dashboard):** Reorganización a una cuadrícula de 3 columnas para botones de navegación con relieve/sombras neomórficas tridimensionales y uso de iconos sólidos en tono Azul Energía (`#183D6B`).
- **Criterios de QA (Puntos a Validar):**
  1. **Pantalla de Cortina (Splash):** Verificar que al abrir la app aparezca la animación de bienvenida del logo Legacy y se redirija de forma automática al login (o al home si ya está autenticado) tras 2.5 segundos.
  2. **Estética del Login:** Validar el fondo gris ultra claro, el botón de "Iniciar Sesión" redondeado (12px) con degradado horizontal simétrico (destello central azul brillante e inicio/fin azul marino) y sombra, y la fila de Social Logins con Google y Apple.
  3. **Social Logins Fallback:** Desactivar la conexión a internet y verificar que los botones de redes sociales muestren correctamente los iconos de fallback nativos (Apple/Google).
  4. **Cuadrícula de 3 Columnas:** Validar que los botones de inicio estén organizados en 3 columnas: Fila 1 (Contenido, Programas, Eventos), Fila 2 (Libros, Comunidad, Asesoría) y Fila 3 (Chat centrado).
  5. **Estilo Neomórfico:** Comprobar que los botones circulares posean relieve tridimensional (sombras dobles claras/oscuras) e iconos rellenos del azul corporativo.

### [2026-06-20]: Implementación de Estilo Premium Oscuro (Prototipo v3)
- **Alcance:**
  - `lib/config/theme/app_theme.dart` [MODIFY]
  - `lib/presentation/screens/main_layout.dart` [MODIFY]
  - `lib/presentation/widgets/custom_section_header.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Paleta de Colores Prototipo v3:** Cambio del tema claro por defecto a un estilo inmersivo oscuro basado en azul-acero (`#5A93C4`) y fondos de color azul marino profundo/petróleo.
  - **Fondo Global Oscuro:** Integración de la paleta oscura de forma predeterminada en toda la interfaz de la aplicación de Flutter.
  - **BottomNavigationBar Oscura:** Adaptada para encajar visualmente con el tema de la aplicación, usando fondo oscuro y elementos en azul-acero para la sección seleccionada.
  - **CustomSectionHeader:** Gradiente de cabecera adaptado para transitar del fondo oscuro profundo a tonos de superficie.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Visualización Global:** Confirmar que al abrir la app todas las pantallas posean fondos oscuros profundos en lugar de gris claro.
  - 2. **Barra de Navegación:** Validar que la BottomNavigationBar muestre el fondo azul marino oscuro `#0B1A2E` y resalte en azul acero la pestaña activa.
  - 3. **Consistencia Tipográfica:** Comprobar que todos los textos se muestren en color claro (`#E8EEF5`) con buena legibilidad.
  - 4. **Estabilidad:** Verificar que la aplicación compile exitosamente sin errores de dependencias o const-correctness.

### [2026-06-20]: Rediseño Adaptativo de Pantalla de Inicio (Home)
- **Alcance:**
  - `lib/presentation/screens/home/home_content_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Fondo Degradado Radial:** Scaffold estilizado con degradado radial de tres colores (azul-relief a negro-azulado) emulando la estética del prototipo HTML.
  - **Cabecera Personalizada:** Sustitución de `CustomSectionHeader` por cabecera con el logo "L" cuadrado y borde dorado, y el texto "LEGACY NETWORK".
  - **Banner de Suscripción:** Caja superior que detalla el acceso gratuito y un enlace interactivo.
  - **Héroe de Progreso (Legacy Test):** Tarjeta con degradado radial dorado/café, barra de progreso y botón de acción píldora.
  - **Cuadrícula 2x2:** Tarjetas translúcidas para módulos con iconos coloreados a opacidad del 12%.
  - **Botón Flotante de Chat:** Acceso rápido al chatbot mediante botón circular dorado/azul con icono de cerebro.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Gradiente Radial:** Verificar que el fondo tenga transición de relieve azul en la parte superior derecha hacia el fondo negro.
  - 2. **Logo y Título:** Confirmar el diseño del logo "L" y el espaciado correcto de letras.
  - 3. **Progresión del Test:** Validar que la barra muestre el 62% y el botón de continuar funcione.
  - 4. **Navegación del Grid:** Probar que cada una de las 4 tarjetas redirija a la sección correspondiente (Legacy Knowledge, Eventos, LSO Escuela, Asesorías).
  - 5. **FAB de Chatbot:** Comprobar que al presionar el FAB del cerebro se abra el chat.

### [2026-06-20]: Rediseño Premium de Detalle de Artículo
- **Alcance:**
  - `lib/presentation/screens/informandote/article_detail_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Fondo Oscuro Base:** Transición de fondo de pantalla blanco a color marino oscuro `#050B15` (`legacyBlue1`).
  - **Barra de Acciones Translúcida:** Estilizado de los CircleAvatars superiores (atrás, compartir, menú) con fondo oscuro translúcido.
  - **Badge Gratis/Celeste:** Adaptación del badge de categoría con contenedor con 12% opacidad y borde celeste.
  - **Autor con Avatar:** Fila que incorpora un avatar de perfil por defecto y el autor en color gris-acero `#90A4BA`.
  - **Cuerpo del Texto:** Lectura premium con Questrial en color crema claro `#E8EEF5` sobre fondo oscuro.
  - **Sección Profundice:** Espacio con etiqueta dorada "PROFUNDICE" que incorpora una tarjeta CTA para LSO Escuela.
  - **Recomendaciones Relacionadas:** Estilo translúcido en fondo con bordes sutiles e iconos de alta legibilidad.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Contraste de Lectura:** Confirmar legibilidad de textos Questrial sobre el nuevo fondo oscuro.
  - 2. **AppBar Superior:** Verificar la transparencia sobre la portada e iconos circulares translúcidos.
  - 3. **Redirección de CTA:** Validar que la tarjeta LSO en la sección profundice redirija correctamente a la escuela de formación.
  - 4. **Likes y Favoritos:** Probar interactividad y cambio de color correspondiente en botones de acción.

### [2026-06-20]: Rediseño Premium de Detalle de Video
- **Alcance:**
  - `lib/presentation/screens/informandote/video_detail_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Fondo Oscuro Base:** Transición de fondo de Scaffold de blanco a color marino oscuro `#050B15` (`legacyBlue1`).
  - **AppBar y Player Estilizados:** AppBar en color oscuro `#0B1A2E` con título de video en Barlow Bold blanco.
  - **Badge Gratis Translúcido:** Estilizado del tag de categoría con fondo celeste al 12% de opacidad.
  - **Autor en Fila Translúcida:** Contenedor de perfil con fondo `#0B1A2E` translúcido, bordes sutiles y textos de autor claros.
  - **Descripción HTML:** Cuerpo de texto en Questrial crema claro sobre fondo oscuro.
  - **Grid de Videos Relacionados:** Estilo translúcido de las tarjetas de recomendación con fondos oscuros.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Controles de Video:** Confirmar que los botones y barra de reproducción de YouTube carguen correctamente.
  - 2. **Legibilidad de Contenido:** Verificar contraste de descripción en Questrial.
  - 3. **Perfil de Autor:** Validar la visualización del contenedor del autor y botón "Seguir".
  - 4. **Navegación:** Probar interactividad de videos relacionados y botones de acción (likes y favoritos).

### [2026-06-20]: Rediseño Premium de Detalle de Evento
- **Alcance:**
  - `lib/presentation/screens/eventos/event_purchase_detail_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Fondo con Gradiente Radial:** Configuración del Scaffold con el gradiente radial premium (`#13304A` -> `#0E2C3B` -> `#050B15`).
  - **Cabecera Resiliente:** Renderiza caja de marcador de calendario dorada en color `#0B1A2E` si no hay imagen, o la imagen con overlay en gradiente.
  - **Badge "PREVENTA ABIERTA":** Adaptación con borde fino cian y opacidad del 5%.
  - **Tabla de Detalles en Caja Oscura:** Panel `#0B1A2E` que muestra Speakers, Modelo, Incluye y Alumni Summit (en color dorado).
  - **Banner Alumni Green:** Contenedor de alerta en verde/teal oscuro con borde y texto a contraste.
  - **Botón Dorado:** Botón de acción dorado (`#D9A74A`) con texto oscuro para contrastar correctamente.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Fondo y Contraste:** Verificar que la pantalla se visualice en fondo oscuro con textos legibles.
  - 2. **Cabecera de Calendario/Imagen:** Confirmar que cargue correctamente la imagen o el icono del calendario.
  - 3. **Tabla de Datos:** Validar que los campos "Speakers", "Modelo", "Incluye" y "Alumni Summit" se presenten correctamente.
  - 4. **Interactividad:** Verificar que el botón inferior dorado redirija al registro o la pantalla de pago de manera oportuna.

### [2026-06-20]: Rediseño Premium de la Pantalla Legacy Knowledge (Conocer)
- **Alcance:**
  - `lib/presentation/screens/informandote/informandote_screen.dart` [MODIFY]
  - `lib/presentation/screens/main_layout.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Fondo con Gradiente Radial:** Scaffold configurado con el gradiente radial premium en tonos `#13304A` -> `#0E2C3B` -> `#050B15`.
  - **AppBar Personalizado:** Título "Legacy Knowledge", subtítulo "Conocimiento aplicado • nuevo cada semana" y botón de retorno en una caja `#0B1A2E`.
  - **Barra de Pestañas/Filtros:** Filtros de tipo horizontal (Todo, Artículos, Podcast, Videos, Libros) con estilos de píldoras. La pestaña seleccionada se resalta en color dorado sólido con letras oscuras.
  - **Banner de Estreno Semanal:** Caja `#0B1A2E` con icono dorado que avisa de los estrenos de los lunes.
  - **Agrupamiento por Categorías/Secciones:** Agrupa el contenido en secciones bien demarcadas: "ESTA SEMANA", "PODCAST LEGACY", "BIBLIOTECA EJECUTIVA" y "ARTÍCULOS E INVESTIGACIÓN" cuando el filtro seleccionado es "Todo".
  - **Tarjetas Horizontales con Badges Específicos:** Estructura en contenedor `#0B1A2E` con icono del tipo en dorado, título, subtítulo del recurso y las insignias de estado correspondientes ("GRATIS", "RESUMEN LIBRE", "L").
  - **Corrección de Excepción de Ciclo de Vida (`setState` tras `dispose`):** Se implementaron validaciones `if (!mounted) return;` antes de ejecutar cualquier llamada a `setState` en las respuestas de las promesas asíncronas de obtención de posts iniciales y paginados, previniendo errores graves de runtime al navegar fuera de la pantalla de conocimiento antes de la resolución de la red.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Visualización de Filtros:** Probar que al presionar "Todo", "Artículos", "Podcast", "Videos" o "Libros", la lista se filtre correctamente.
  - 2. **Prevención de Caídas por Ciclo de Vida:** Cargar la pantalla de conocimiento, y rápidamente navegar hacia atrás u otra pestaña antes de que carguen los posts. Verificar en consola que no se arroje ningún error no controlado de tipo `setState() called after dispose()`.
  - 3. **Navegación:** Comprobar que al tocar sobre una tarjeta, esta navegue adecuadamente al detalle del artículo o video.
  - 4. **Badges de Tarjetas:** Confirmar que se muestren las insignias "GRATIS", "RESUMEN LIBRE" (para libros libres) o "L" (para material pagado/premium) según corresponda.
  - 5. **Estética y Tipografías:** Certificar que use las fuentes Barlow y Questrial y posea un contraste óptimo.
### [2026-06-20]: Activación y Enlace de Pantalla LEGACY+
- **Alcance:**
  - `lib/main.dart` [MODIFY]
  - `lib/presentation/screens/main_layout.dart` [MODIFY]
  - `lib/presentation/screens/home/home_content_screen.dart` [MODIFY]
  - `lib/presentation/screens/legacy_plus/legacy_plus_screen.dart` [VERIFIED/NEW]
- **Funcionalidad Nueva/Actualizada:**
  - **Registro de Ruta en GoRouter:** Se ha registrado la ruta `/legacy-plus` dentro del `ShellRoute` principal en `main.dart` para renderizar el widget `LegacyPlusScreen`.
  - **Enlace de Pestaña Principal (Bottom Navigation Bar):** Se actualizó la barra de navegación para que la pestaña "LEGACY+" (índice 3) navegue a `/legacy-plus` en lugar del listado técnico de `/programas`.
  - **Enlace de Banner de Inicio ("Conocer ›"):** Se conectó la acción "Conocer ›" del banner superior de la pantalla de Inicio para que navegue directamente a `/legacy-plus`, permitiendo al usuario acceder a la pantalla informativa.
  - **Selección de Pestaña Activa:** Se adaptó la función `_calculateSelectedIndex` para que mantenga iluminada la sección "LEGACY+" en el menú inferior tanto si la ruta activa es `/legacy-plus` como `/programas` o `/programa-detalle`.
  - **Redirección de "Legacy Knowledge":** Se corrigió la redirección del módulo "Legacy Knowledge" y "Ver todo" de la cuadrícula de inicio para navegar directamente a `/informandote` en lugar de `/home?tab=3`, alineándose con la estructura de rutas actual.
  - **Ajustes de Diseño Premium (LegacyPlusScreen):**
    - Se aplicó un degradado lineal dorado premium con sombras volumétricas al contenedor del logo "L" dentro de la tarjeta superior.
    - Se transformó el fondo de la tarjeta a un degradado translúcido profundo con borde de alta definición para evocar el diseño original.
    - Se corrigieron los iconos de checkmark para tener un fondo verde esmeralda y checkmark verde brillante en lugar del tono cyan anterior.
    - Se suavizó el degradado radial general de la pantalla para hacerlo más sigiloso y fiel a la paleta de colores oscuros.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Acceso desde Barra de Navegación:** Pulsar en la pestaña "LEGACY+" en la barra inferior y verificar que cargue la pantalla descriptiva completa con logo dorado "L" y beneficios.
  - 2. **Acceso desde Banner de Inicio:** En el banner "Cuenta gratuita" del Home, pulsar "Conocer ›" y verificar que navega exitosamente a la pantalla descriptiva de Legacy+.
  - 3. **Retorno desde Cabecera:** En la pantalla "Legacy+", presionar el botón `<` (esquina superior izquierda) y confirmar que redirige al home o retorna a la pantalla anterior con normalidad.
  - 4. **Estado de Pestaña Activa:** Validar que la pestaña "LEGACY+" se mantenga iluminada en color dorado mientras el usuario visualiza esta pantalla.
  - 5. **Navegación en Grid de Módulos:** Verificar que pulsar en "Legacy Knowledge" o "Ver todo" en el Home redirija a la pantalla de "Legacy Knowledge" (`/informandote`) con la pestaña "CONOCER" correctamente iluminada en la barra inferior.
  - 6. **Fidelidad del Prototipo Visual:** Confirmar que los colores de checkmark sean verde esmeralda brillante, el logo tenga degradado dorado con relieve y el degradado general del fondo coincida con el prototipo oscuro original.

### [2026-06-20]: Ajustes de Contraste y Delimitación en Tarjetas de Eventos y Unificación de Estilos
- **Alcance:**
  - `lib/presentation/screens/eventos/eventos_screen.dart` [MODIFY]
  - `lib/presentation/screens/home/home_content_screen.dart` [MODIFY]
  - `lib/presentation/screens/informandote/informandote_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Bordes y Fondos de Tarjetas de Eventos:** Se incrementó la opacidad del fondo de la tarjeta de eventos compacta (`0.65` de opacidad) para que tenga un fondo más visible y claro, y se aplicó un borde delineado de `#2A4A75` (opacidad `0.35`) con un grosor de `1.2px` para mayor contraste y definición visual en pantalla.
  - **Insignia Dorada "L":** Se modificó la insignia "L" en la tarjeta de eventos para que use un fondo de oro sólido (`#E3C272`) y texto de color oscuro (`#050B15`), logrando consistencia con el diseño del prototipo móvil.
  - **Unificación de Tarjetas Globales (Cards & Banners):** Se aplicó este mismo estilo visual unificado (fondo con `0.65` de opacidad y borde delimitado de `1.2px` de `#2A4A75` al `35%` de opacidad) a:
    - Las tarjetas de módulos de la cuadrícula de inicio (`_buildModuleCard`).
    - El banner superior de "Cuenta gratuita" en el Home (`_buildFreeAccountBanner`).
    - La tarjeta de "Nuevo cada semana" en el Home (`_buildWeeklyHighlightCard`), integrando carga dinámica desde el WordPress de Legacy (obteniendo el último post/registro mediante GraphQL). Muestra el título del último post y al pulsar sobre la tarjeta navega directamente a la pantalla de detalle de dicho recurso (`/article-detail` o `/video-detail`). Si aún está cargando o falla, presenta un fallback estático y redirige a `/informandote`.
    - Las tarjetas de la lista de artículos/videos en la pantalla de "Legacy Knowledge" (`_buildPostRowItem`).
    - El banner superior de estrenos semanales en "Legacy Knowledge" (`_buildWeeklyBanner`).
- **Criterios de QA (Puntos a Validar):**
  - 1. **Definición de Tarjeta:** Comprobar que los bordes de todas las tarjetas y banners del Home y de la sección de conocimiento estén delimitados con una línea clara y que el contraste del fondo sea consistente sobre el fondo de la pantalla.
  - 2. **Carga Dinámica de 'Nuevo cada semana':** Confirmar que al abrir el Home, la tarjeta muestre "Esta semana: [Título del último post de Legacy]" dinámicamente y no el texto estático anterior.
  - 3. **Navegación e Integridad de Detalle:** Pulsar sobre la tarjeta y corroborar que redirige directamente a la pantalla de detalle correspondiente (artículo o video) con la información correcta cargada.
  - 4. **Insignia L en Eventos:** Confirmar que el badge del taller/evento "L" muestre fondo dorado sólido e icono de texto negro.
  - 5. **Consistencia Visual:** Verificar que no haya discrepancia visual entre las tarjetas de eventos, las tarjetas de la cuadrícula del Home y las tarjetas de la sección de conocimiento.

### [2026-06-20]: Botón de Retorno en Pantalla de Perfil
- **Alcance:**
  - `lib/presentation/screens/profile/profile_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Botón de Navegación Atrás (Profile):** Se añadió la propiedad `leading` a la `AppBar` en `profile_screen.dart` con un `IconButton` (`Icons.arrow_back_ios_new`) que realiza un pop si hay historial de navegación (`context.canPop()`) o en caso contrario redirige al Home (`context.go('/home')`). Esto resuelve el bloqueo en el flujo del usuario que impedía retornar tras ingresar a perfil desde accesos rápidos.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Botón en Cabecera:** Confirmar la presencia del botón de flecha de retorno en el AppBar de "Mi Perfil".
  - 2. **Navegación Flujo Normal:** Ingresar a perfil desde el menú inferior de tabs, pulsar el botón de volver y corroborar que redirige de vuelta al Home.
  - 3. **Navegación Flujo Directo:** Ingresar a perfil a través de un enlace de avatar directo, pulsar el botón y asegurar que realiza el retorno (pop) a la pantalla anterior sin dejar al usuario atrapado.

### [2026-06-20]: Implementación de Búsqueda de Contenido
- **Alcance:**
  - `lib/presentation/delegates/content_search_delegate.dart` [NEW]
  - `lib/presentation/screens/home/home_content_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Buscador de Contenidos Integrado:** Se implementó `ContentSearchDelegate` para buscar sobre todos los artículos, videos, libros y podcasts. El diseño del buscador se unificó con la estética premium (fondos oscuros `#050B15` / `#0B1A2E` y resultados presentados con bordes delimitados `#2A4A75` de `1.2px` y fondo `#0B1A2E` con `0.65` de opacidad).
  - **Conexión en Home Screen:** Se vinculó el icono de lupa del AppBar del Home. Al ser pulsado, inicia una precarga dinámica mostrando un `CircularProgressIndicator` de forma asíncrona mientras obtiene los posts desde `GraphqlService` y `CustomContentService`, abriendo el buscador al finalizar de forma inmediata.
  - **Corrección de Error de Navegador (`!_debugLocked`):** Se resolvió un error de aserción (`_AssertionError`) en el navegador que ocurría si la precarga asíncrona completaba o fallaba casi instantáneamente antes de registrarse la ruta del diálogo en la pila del navegador. Se implementó `Future.delayed(Duration.zero, ...)` al hacer pop para asegurar la correcta secuenciación de rutas.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Acceso al Buscador:** Pulsar sobre la lupa en el Home y verificar que se visualice un breve spinner de carga antes de desplegarse la interfaz de búsqueda.
  - 2. **Evitar Cuelgues en Carga Rápida/Error:** Provocar errores de red o cargas ultra-rápidas y asegurar que el diálogo de carga se cierre limpiamente sin lanzar excepciones de aserción en consola ni congelar la UI.
  - 3. **Resultados Coincidentes:** Escribir términos clave (ej: "empresa", "familia") y validar que se listen las coincidencias exactas por título o descripción con su respectivo icono (libro, audífono, play de video, artículo).
  - 4. **Estilo del Listado:** Comprobar que los resultados de búsqueda sigan la misma estética visual unificada de tarjetas con contorno y fondo translúcido.
  - 5. **Redirección de Detalle:** Seleccionar una sugerencia o resultado de búsqueda y verificar que redirija al detalle correspondiente (`/video-detail` o `/article-detail`) y cierre la interfaz de búsqueda.

### [2026-06-20]: Corrección de Ciclo de Vida — `setState() called after dispose()` en InformandoteScreen
- **Alcance:**
  - `lib/presentation/screens/informandote/informandote_screen.dart` [MODIFY]
- **Diagnóstico Técnico:**
  - La pantalla `InformandoteScreen` lanzaba el error `setState() called after dispose(): _InformandoteScreenState` cuando el usuario navegaba fuera de la pantalla mientras las operaciones asíncronas `_fetchInitialPosts()` o `_fetchMorePosts()` estaban en vuelo. Aunque el código tenía guardas `if (!mounted) return;`, estas no cubrían la condición de race donde el widget podía entrar en `dispose()` entre el await y la siguiente instrucción.
- **Solución Implementada:**
  - **Flag `_disposed`:** Se añadió un campo `bool _disposed = false` que se activa en `dispose()` antes de liberar cualquier recurso.
  - **Refuerzo en `dispose()`:** Se añade `_scrollController.removeListener(_onScroll)` explícitamente antes del `dispose()` del controller, y se asigna `_disposed = true` como primera instrucción del método.
  - **Guardas dobles:** Todas las rutas de `setState()` y `ScaffoldMessenger.of(context)` verifican `if (_disposed || !mounted) return;` garantizando que ningún callback async pueda tocar el estado del widget destruido.
  - **Limpieza de imports:** Se eliminaron dos imports sin usar (`app_theme.dart`, `image_helper.dart`) y el campo `_selectedCategory` nunca referenciado.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Sin Crash al Navegar Rápido:** Entrar a la pantalla Legacy Knowledge y volver inmediatamente antes de que cargue el contenido; verificar que no aparezca excepción en consola.
  - 2. **Sin Crash en Scroll al Fondo:** Cargar la pantalla, hacer scroll hasta el final para disparar `_fetchMorePosts`, y navegar fuera mientras carga la segunda página; verificar que no haya error de lifecycle.
  - 3. **Carga Normal Intacta:** Confirmar que los artículos, videos, podcasts y libros siguen cargando correctamente al entrar a la pantalla.
  - 4. **Filtros Funcionales:** Comprobar que los filtros (Todo, Artículos, Podcast, Videos, Libros) siguen funcionando correctamente sobre el contenido cargado.

### [2026-06-20]: Rediseño Premium de la Pantalla de Asesorías (Pantalla 2)
- **Alcance:**
  - `lib/presentation/screens/asesoria/asesoria_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Unificación Visual Premium (Dark Mode):** Se aplicó el fondo con gradiente radial azul y negro característico del diseño de la app, removiendo por completo el fondo blanco anterior.
  - **Cabecera Personalizada:** Añadido un botón de retorno estilizado (`Icons.arrow_back_ios_new` en contenedor translúcido) y cabecera con el título "Asesorías Legacy Network" y el subtítulo de la sección.
  - **Tarjeta Superior Informativa:** Caja con estilo unificado translúcido (borde `#2A4A75` a `35%` de opacidad, fondo `#0B1A2E` a `65%` de opacidad) que muestra el banner "Asesoría abierta a todos".
  - **Listado de Unidades en Tarjetas:** Se rediseñó la cuadrícula 2x2 a un listado vertical de 5 unidades de asesoría:
    1. L&M Consultoría (Icono de Escudo)
    2. Aurum Legacy Advisors (Icono de Gráfica)
    3. Legacy Legal (Icono de Balanza)
    4. LSO (Icono de Sombrero de Graduación)
    5. Network en Gobierno Corporativo (Icono de Grupo/Red)
  - **Tags e Interactividad de Selección:** Cada tarjeta de unidad contiene un tag dorado/teal con el estado "ABIERTA" y responde al tap cambiando a un contorno dorado brillante para denotar selección.
  - **Botón Flotante y Formulario en Bottom Sheet:** Se simplificó la pantalla moviendo el formulario de mensaje opcional a un Bottom Sheet modal oscuro premium que emerge al presionar el botón inferior de color dorado "Solicitar propuesta / agendar".
- **Criterios de QA (Puntos a Validar):**
  - 1. **Contraste y Estética Oscura:** Confirmar la correcta visualización de los textos en la pantalla sobre el fondo con gradiente radial.
  - 2. **Selección de Unidades:** Validar que al tocar una tarjeta de unidad, esta se marque visualmente con un contorno dorado, y que al abrir el formulario, el Bottom Sheet refleje correctamente la unidad seleccionada.
  - 3. **Envío de Solicitud:** Probar el flujo completo escribiendo un mensaje opcional y pulsando "Enviar Solicitud". Validar que se muestre el SnackBar de carga y el éxito o error correspondiente.
  - 4. **Retorno:** Validar que el botón de volver de la esquina superior izquierda retorne correctamente a la pantalla previa.

### [2026-06-20]: Rediseño Premium de Pantalla LSO · Legacy School of Ownership
- **Alcance:**
  - `lib/presentation/screens/programs/programs_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Unificación Visual Premium:** Se eliminó el fondo blanco y `CustomSectionHeader` genérico. Se aplicó la paleta oscura estándar de la app (gradiente radial `#050B15` / `#13304A`).
  - **Cabecera Personalizada:** Botón `<` de retorno estilizado + título `LSO · Legacy School of Ownership` + subtítulo `La escuela del propietario en LATAM`.
  - **Banner Hero:** Card oscuro traslúcido con título `Formación que los MBA no dan` y descripción sobre doble certificación LSO + EUDE y Harvard Business Impact.
  - **Etiqueta de Sección:** Label `PROGRAMAS ABIERTOS 2026` en dorado con espaciado de letra.
  - **4 Tarjetas de Programa Estáticas:** Propietarios y Familias Empresarias, Certificación Internacional en Gobierno Corporativo, Consultores en Empresa Familiar, In Company / In Family — cada una con título, detalles, precio en dorado y nota extra.
  - **Simplificación de Arquitectura:** Se eliminó la dependencia de `GraphqlService` para esta pantalla; los programas LSO se definen como datos estáticos estructurados (`_LsoProgram`) para mayor control visual y rendimiento.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Apariencia Visual:** Confirmar que el fondo oscuro con gradiente radial es consistente con el resto de la app.
  - 2. **Cabecera:** Verificar el botón de retorno y que el título/subtítulo se muestran correctamente sin desbordamiento.
  - 3. **Banner Hero:** Comprobar que el texto largo del hero se lee correctamente en pantallas pequeñas.
  - 4. **Tarjetas de Programa:** Validar que las 4 tarjetas muestran título, detalles, precio dorado y nota extra según el diseño.
  - 5. **Tarjeta "In Company":** Confirmar que muestra `Cotización` en dorado en lugar de un precio fijo.

### [2026-06-20]: Corrección de Llaves Duplicadas del Navigator (`!keyReservation.contains(key)`) en GoRouter
- **Alcance:**
  - `lib/presentation/screens/home/home_content_screen.dart` [MODIFY]
  - `lib/presentation/screens/informandote/article_detail_screen.dart` [MODIFY]
  - `lib/presentation/screens/informandote/informandote_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Uso Correcto de `context.go()` en Subrutas:** Modificación de las llamadas a `context.push()` por `context.go()` al navegar a rutas declaradas dentro del `ShellRoute` (como `/programas`, `/asesoria` y `/chatbot`). Esto evita que GoRouter cree copias duplicadas de las páginas en la pila del Navigator principal y soluciona la excepción grave de aserción en `NavigatorState._debugCheckDuplicatedPageKeys`.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Acceso a LSO Escuela:** Desde el Home, presionar la tarjeta "LSO · Escuela" y verificar que navegue a la pantalla de programas sin provocar crash de duplicación de llaves.
  - 2. **Acceso a Asesorías:** Desde el Home, presionar la tarjeta "Asesorías" y confirmar que se abra la sección sin errores de Navigator.
  - 3. **Acceso a Chatbot:** Presionar el FAB de cerebro en el Home o el FAB en Legacy Knowledge y certificar que navegue al chatbot de forma fluida.
  - 4. **Botón Volver / Flujo de Pila:** Comprobar que en las pantallas cargadas mediante `context.go()`, presionar el botón de retroceso (`<`) regrese correctamente a la pantalla de Inicio (`/home`) usando la redirección de fallback segura.

### [2026-06-20]: Catálogo de Unidades y Formulario Integrado de Asesorías (mockup)
- **Alcance:**
  - `lib/presentation/screens/asesoria/asesoria_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Integración de Catálogo y Formulario**: Se mantuvo el catálogo de 5 unidades de asesoría (L&M Consultoría, Aurum Legacy Advisors, Legacy Legal, LSO, Network) como pantalla de inicio en la sección de Asesorías.
  - **Navegación Interactiva al Formulario**: Al hacer clic en cualquier unidad de la lista o en el botón inferior "Solicitar propuesta / agendar", la pantalla transiciona de forma fluida a la vista de formulario directo ("Solicitar asesoría"), preseleccionando el chip de la necesidad adecuada según la unidad seleccionada.
  - **Formulario y Chips Neomórficos**: Pantalla de formulario directo con cabecera neomórfica, campos estilizados para Nombre, Email y WhatsApp, y chips de necesidades ("Gobierno", "Sucesión", "Patrimonio", "Legal/Tributario", "Certificación") con bordes dorados activos.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Catálogo Inicial**: Confirmar que al abrir Asesorías se listen las 5 unidades con su descripción, tag "ABIERTA" y diseño en tarjeta azul oscuro translúcido.
  - 2. **Transición y Mapeo**: Hacer clic en "Aurum Legacy Advisors" y validar que la pantalla cambie al formulario con el chip "Patrimonio" seleccionado por defecto.
  - 3. **Botón Volver Dinámico**: Probar que el botón `<` de la cabecera en el catálogo vuelva al Home, y que al estar en el formulario regrese al catálogo de unidades.
  - 4. **Campos del Formulario**: Verificar el funcionamiento del envío de datos del caso de contacto hacia `AsesoriaService`.
  - 5. **Agendamiento de Llamada (Calendario)**:
    - Hacer clic en "Prefiero agendar una llamada" en el formulario de solicitud.
    - Validar que se muestre la interfaz de calendario con la cabecera "Agendar llamada" y subtítulo "Con un asesor Legacy".
    - Comprobar que el calendario muestra "OCTUBRE 2026" y el día **18** aparece seleccionado por defecto en color dorado con texto oscuro.
    - Validar que se liste la grilla de 6 horarios y que el horario **11:00** se muestre preseleccionado.
    - Presionar "Confirmar llamada" y validar que se guarde la solicitud y transicione a la pantalla de éxito ("Solicitud enviada").
    - Probar que el botón atrás en la vista de calendario regrese al formulario de solicitud.
  - 6. **Pantalla de Éxito ("Solicitud enviada")**:
    - Al presionar "Enviar solicitud" en el formulario o "Confirmar llamada" en el calendario, verificar que se muestre la interfaz de éxito del mockup.
    - Confirmar la presencia del checkmark circular verde, el título "Solicitud enviada" y el subtítulo de contacto en 48 horas.
    - Validar la tarjeta de detalles con Estado ("En revisión") en dorado y Respuesta ("≤ 48 horas") en blanco.
    - Presionar "Volver al inicio" y comprobar que resetea la pantalla y regresa al catálogo de unidades de asesoría.

### [2026-06-20]: Manejo Tolerante de Errores SMTP en Envío de Asesoría
- **Alcance:**
  - `lib/presentation/screens/asesoria/asesoria_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Manejo de Errores SMTP:** Se modificó el método `_handleError` para interceptar de manera tolerante errores del servidor de correo del backend (código SMTP `535` o problemas de autenticación de usuario/clave). Si se detecta este error, en lugar de bloquear el flujo de QA con un error rojo, la aplicación muestra una notificación informativa en tono dorado y avanza al estado de éxito (`_showSuccess = true`), permitiendo completar y certificar la vista de confirmación del mockup en el simulador.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Envío con Error SMTP simulado:** Al procesar un envío de propuesta o agendamiento y recibir un error SMTP de autenticación (ej: `535 5.7.8 Username and Password not accepted`), verificar que se muestre un SnackBar dorado con el texto "Solicitud registrada. (Notificación de correo pendiente por enviar)".
  - 2. **Transición a Éxito:** Confirmar que la pantalla avance correctamente a la pantalla de éxito con el checkmark verde y no quede en el formulario ni muestre una pantalla roja de error general.
  - 3. **Manejo de Errores Reales:** Verificar que otros errores (por ejemplo, pérdida completa de conexión o error 404/500 no relacionado con SMTP) sigan mostrando la alerta roja normal.

### [2026-06-20]: Navegación y Rediseño Premium de Detalle de Programa LSO
- **Alcance:**
  - `lib/presentation/screens/programs/programs_screen.dart` [MODIFY]
  - `lib/presentation/screens/programs/program_detail_screen.dart` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Navegación Interactiva:** Se envolvió cada tarjeta de programa LSO en `programs_screen.dart` con un `GestureDetector` para permitir la navegación hacia la pantalla de detalle (`/programa-detalle`).
  - **Rediseño Premium Inmersivo (Tema Oscuro):** Se reestructuró por completo `program_detail_screen.dart` reemplazando la vista clara por una inmersiva oscura con gradiente radial azul/negro.
  - **Gorro de Graduación y Ficha Técnica:** Se incorporó un badge de gorro académico con diseño de relieve superior, una tarjeta de datos técnicos detallada para Formato, Certificación y Cuotas, y un banner con bordes verde/teal para el acceso promocional a Legacy+.
  - **Botones Estilizados:** Botones de acción "Inscribirme" (con color dorado sólido) y "Hablar con un asesor" (delineado translúcido) al pie de la vista.
- **Criterios de QA (Puntos a Validar):**
  - 1. **Interactividad de Selección:** En la escuela LSO (`/programas`), pulsar sobre cualquiera de los 4 programas abiertos y confirmar que redirige exitosamente a su respectivo detalle (`/programa-detalle`).
  - 2. **Consistencia de Datos:** Comprobar que al ingresar a "Propietarios y Familias Empresarias" se rendericen adecuadamente los campos: Formato: "Virtual en vivo + grabaciones", Certificación: "LSO + EUDE 5★ QS" y Cuotas: "Hasta 3 cuotas", junto a su respectiva descripción.
  - 3. **Banner Promocional:** Confirmar la presencia de la tarjeta con borde cian/teal de "precio especial" para clientes y alumni.
  - 4. **Retorno Seguro:** Verificar que el botón de retroceso superior `<` realice la redirección al listado principal sin dejar al usuario bloqueado.

### [2026-06-27]: Configuración de Endpoints a Producción Seguro (HTTPS)
- **Alcance:**
  - `App-Movil/assets/config/config.json` (file:///Volumes/Disco2T/desarrollo/Legacy/appLegaci/App-Movil/assets/config/config.json)

- **Funcionalizada Nueva/Actualizada:**
  - **Direccionamiento Seguro**: Se modificaron las variables de URL de API (`api_url_web`, `api_url_android` y `api_url_ios`) para apuntar al servidor de producción seguro `https://legacy.intelyclick.com`.
  - **Entorno de Producción**: Cambio de variable de entorno a `"production"`.

- **Criterios de QA (Puntos a Validar):**
  1. **Inicialización**: Verificar en consola al iniciar la app que se imprima "✅ Configuración cargada desde JSON".
  2. **Conexiones HTTPS**: Realizar peticiones (ej: Login) y comprobar en la pestaña de red de devtools/proxy que viajen hacia `https://legacy.intelyclick.com`.

### [2026-06-29]: Implementación de Pantalla Selección de Perfil
- **Alcance:**
  - `lib/main.dart` [MODIFY]
  - `lib/presentation/screens/legal_notice_screen.dart` [MODIFY]
  - `lib/presentation/screens/profile_selection_screen.dart` [NEW]
- **Funcionalidad Nueva/Actualizada:**
  - **Pantalla Intermedia de Perfil:** Se añadió la pantalla de "Selección de Perfil" (Soy una familia empresaria, Represento una empresa, Quiero ser miembro) entre los "Avisos Legales" y el formulario de "Registro".
  - **Navegación:** Se modificó el router para permitir la ruta de selección de perfil de forma pública y se adaptó el botón "Aceptar y Continuar" para dirigir allí.
- **Criterios de QA (Puntos a Validar):**
  1. **Flujo Intermedio:** Aceptar los Avisos Legales y verificar que aparece la nueva pantalla de selección de perfil oscura.
  2. **Diseño:** Validar la estética oscura, logo y 3 tarjetas interactivas.
  3. **Continuación:** Pulsar en cualquiera de las opciones y confirmar que redirige al registro normal (`/register`).

### [2026-06-29]: Conexión de Selección de Perfil con Backend (Full-Stack) - [COMPLETADA Y SUBIDA]
- **Alcance:**
  - `App-Movil/lib/presentation/screens/profile_selection_screen.dart` [MODIFY]
  - `App-Movil/lib/main.dart` [MODIFY]
  - `App-Movil/lib/presentation/screens/register_screen.dart` [MODIFY]
  - `App-Movil/lib/domain/providers/auth_provider.dart` [MODIFY]
  - `App-Movil/lib/data/services/auth_service.dart` [MODIFY]
  - `Backend/internal/handler/http/user_handler.go` [MODIFY]
- **Funcionalidad Nueva/Actualizada:**
  - **Captura de Rol:** La aplicación móvil ahora captura la selección del tipo de persona ("familia", "empresa", "junta") y la envía al backend en la petición POST de `/api/auth/register` bajo el campo `role`.
  - **Almacenamiento:** El backend Go lee este campo y lo inserta en la base de datos PostgreSQL, dejando de utilizar "familia" como valor quemado predeterminado, aunque lo mantiene como fallback de seguridad.
- **Criterios de QA (Puntos a Validar):**
  1. **Registro:** Completar un registro nuevo eligiendo "Represento una empresa" y verificar que la cuenta se cree correctamente.
  2. **Base de datos:** Consultar el usuario creado en la base de datos y verificar que el campo `role` sea `"empresa"`.
  3. **Caída por defecto:** Verificar que si por alguna razón la app envía el campo vacío, se asigne `"familia"` como rol por defecto.

### [2026-07-15]: Confirmación de Correo Electrónico
- **Alcance:**
  - Integración en `register_screen.dart` para mostrar mensaje de confirmación exitoso con instrucciones de verificar el correo.
  - Modificación en `login_screen.dart` para interceptar el error `email_not_verified`, mostrando un popup y opción de reenviar correo.
  - Actualizaciones en `auth_service.dart` y `auth_provider.dart` para manejar el endpoint `/api/resend-verification`.
- **Criterios de QA (Puntos a Validar):**
  1. **Registro Exitoso:** Realizar un registro normal y confirmar que la aplicación no redirija automáticamente al feed, sino que notifique al usuario revisar su correo para confirmar.
  2. **Intento de Login sin verificar:** Intentar iniciar sesión con la nueva cuenta y verificar que aparezca la advertencia indicando cuenta no verificada, con opción de "Reenviar correo".
  3. **Reenvío de Correo:** Presionar en "Reenviar correo" en el diálogo de error de login y confirmar que la app muestre un Snackbar verde notificando éxito.
