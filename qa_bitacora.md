# Bitácora de QA - Proyecto Flutter [MOBILE]

Entrada de trabajo para validación de App Móvil.

### [2026-08-25]: F7 — el acceso con Google en Android queda verificado en producción

Primera vez que se ejercita el acceso social de verdad. Se hizo con el **APK de release** apuntando a
producción, no con uno de depuración: ver la trampa al final.

- **Qué se probó:** en el teléfono conectado, tocar «Google» y elegir una cuenta que **ya tenía cuenta
  en Legacy con correo y contraseña**. Es el camino más frecuente y el que más cosas encadena.
- **Resultado:** entra a la cuenta existente, no crea una duplicada. `SocialLogin`
  (`auth_service.go:297`) la encuentra por índice ciego del correo cuando la identidad social todavía
  no está registrada, y enlaza el `google_id` para las próximas veces.
- **El token sirve en rutas privadas**, que es donde fallaba antes: la pantalla de inicio pintó el
  saludo con el nombre (`GET /api/me`) y «Mi credencial» cargó la inscripción real con su QR
  (`GET /api/me/registrations`). Eso confirma que el JWT lleva el claim `sub`, sin el cual toda ruta
  privada respondía 401.

**Verificación previa de la configuración**, que es donde han estado los fallos:

| Eslabón | Estado |
|---|---|
| SHA-1 del keystore de release ↔ `google-services.json` | coincide (`dad19859…89f`) |
| `serverClientId` de la app ↔ cliente web del proyecto | coincide |
| Cliente web ↔ `firebase.google_client_id` del backend | coincide |
| `apple.bundle_id` ↔ bundle real de la app | coincide |

🔴 **Trampa para la próxima vez: el SHA-1 del `debug.keystore` NO está registrado en Firebase.** Un
APK de depuración falla el acceso con Google con `DEVELOPER_ERROR` (`ApiException: 10`) por
configuración, no por defecto de la app. **F7 hay que probarlo con el APK de release**, o se obtiene
un falso negativo. Las dos huellas registradas son la del keystore de subida y una segunda, que por
descarte debería ser la de Play App Signing (no verificable sin Play Console).

- **Lo que queda de F7:** el registro **de usuario nuevo** por Google (hace falta una cuenta de Google
  sin registrar) y **los cuatro casos de iOS**, bloqueados por hardware: exigen subir un build a
  TestFlight e instalarlo en un iPhone. No es trabajo pendiente, es falta de dispositivo.
- **Criterios de QA** (para repetirlo):
  1. Instalar el **APK de release**, no el de depuración.
  2. Tocar «Google» y elegir una cuenta que ya tenga cuenta en Legacy: debe entrar a la suya.
  3. Abrir «Mi credencial»: debe cargar las inscripciones, no quedarse vacía ni dar error.
  4. Cerrar sesión y volver a entrar con Google: debe reconocerla ya por `google_id`.

### [2026-08-25]: Cancelar el acceso con Google o Apple deja de parecer un error

Salió al preparar F7 (los diez casos de acceso social), revisando el camino de error antes de
ejercitarlo en el teléfono.

- **El problema:** `handleSocialLogin` ponía `e.toString()` directo en `_errorMessage`, y la pantalla
  de acceso lo pinta en el recuadro rojo. Así que **cancelar el selector de cuenta —que no es un
  fallo— sacaba** `GoogleSignInException(code: GoogleSignInExceptionCode.canceled, ...)` en pantalla.
  Y un proyecto mal configurado sacaba el `ApiException: 10` en crudo. Los errores de red sí estaban
  redactados (`auth_service.dart`), pero los de los SDK no pasaban por ahí.
- **El fix:** `mensajeDeErrorSocial()`, función pura fuera de `AuthProvider`. Devuelve **`null` al
  cancelar** —no hay nada que avisar— y un mensaje redactado para lo demás. El caso de configuración
  orienta a entrar por correo mientras se arregla.
- **Se comprueba con `if` y no con `switch`** a propósito: `GoogleSignInExceptionCode` gana valores
  entre versiones del paquete, y un `switch` exhaustivo dejaría de compilar en cada actualización.
  Ya pasó dos veces al escribir esto (`providerConfigurationError` y `uiUnavailable`).
- **Vive fuera de la clase** porque el constructor de `AuthProvider` arranca `checkLoginStatus()` y
  necesita la configuración cargada; como función suelta se prueba sin montar nada.
- **Alcance:** `lib/domain/providers/auth_provider.dart`,
  `test/providers/errores_login_social_test.dart` (nuevo, 7 casos).
- **Verificado:** `flutter analyze` sin errores ni advertencias; `flutter test` **212/212** (205 + 7).
- **Criterios de QA:**
  1. **Tocar «Google» y cerrar el selector** sin elegir cuenta: no aparece ningún recuadro rojo.
  2. **Elegir una cuenta de Google** con el APK de release: entra, o lleva al registro si la cuenta no
     existe.
  3. **En iOS, tocar «Apple» y cancelar**: tampoco aparece error.
  4. **Ningún mensaje de error** debe mostrar texto entre paréntesis con nombres de clases o códigos.

### [2026-08-25]: La app pasa a llamarse «Legacy Network»

- **Decisión del usuario** (2026-08-25), junto con la de clasificar la app **solo para mayores de
  edad** en las dos tiendas, coherente con la sección 2 de los T&C.
- **El problema:** el nombre no era ni siquiera consistente. Android instalaba `Legacy app`, iOS
  `Legacy App`, y la web `legacy_app`. Ninguno es la marca, que es la que la gente busca en la tienda
  y la que muestra la propia pantalla de acceso.
- **Alcance:** `android/app/src/main/AndroidManifest.xml` (`android:label`),
  `ios/Runner/Info.plist` (`CFBundleDisplayName`), `web/index.html` y `web/manifest.json`,
  `lib/main.dart` (título de `MaterialApp`), y los textos visibles que lo nombraban:
  `faq_data.dart`, los dos de compartir en `article_detail_screen.dart` y `video_detail_screen.dart`,
  la versión en `custom_section_header.dart` y `pubspec.yaml`.
- **De paso, el texto legal dejó de nombrar a una entidad que no existe.** `legal_notice_screen.dart`
  decía «usted autoriza expresamente a **Legacy App** a recolectar…»; la responsable del tratamiento
  es Legacy Network. Ese bloque se sustituirá entero por el que redactó Legacy Legal, pero mientras
  tanto al menos nombra a quien corresponde.
- **Lo que NO se tocó, a propósito:** el nombre del paquete Dart (`legacy_app` en `pubspec.yaml`, del
  que cuelgan todos los `import package:legacy_app/...`), el `CFBundleName` de iOS —lo que se muestra
  es `CFBundleDisplayName`— y `ios/ExportOptions.plist`, donde «Legacy App Store CI» es el nombre de
  un **perfil de firma**, no de la app. Cambiar ese último rompería la firma del workflow.
- **Verificado:** `flutter analyze` sin errores ni advertencias; `flutter test` 205/205.
- **Criterios de QA:**
  1. **Instalar el APK**: bajo el icono dice «Legacy Network», no «Legacy app».
  2. **Multitarea de Android**: la tarjeta de la app muestra «Legacy Network».
  3. **Compartir un artículo y un video**: el texto dice «en Legacy Network».
  4. **Perfil › Acerca de**: muestra «Legacy Network v1.0.0».
  5. **En iOS**, bajo el icono debe decir «Legacy Network» (requiere build nuevo de TestFlight).

### [2026-08-25]: La app se declara solo para iPhone, no para iPad

- **El problema:** el proyecto iOS declaraba `TARGETED_DEVICE_FAMILY = "1,2"` —iPhone **y** iPad— en
  las tres configuraciones. Es el valor que trae Flutter al crear el proyecto, no una decisión. Con
  iPad declarado, Apple **exige capturas de iPad de 13"** en la ficha y revisa que la app se vea bien
  en esa pantalla. **Nadie ha abierto nunca la app en un iPad**, y está diseñada en vertical para
  teléfono.
- **El fix:** `TARGETED_DEVICE_FAMILY = "1"` en Debug, Release y Profile.
- **Decisión del usuario** (2026-08-25): quitar el iPad en vez de producir esas capturas y probar en
  tablet. Si alguna vez se quiere iPad, hay que devolver el valor **y** hacer el trabajo de diseño y
  pruebas que implica; no es solo cambiar el número.
- **`UISupportedInterfaceOrientations~ipad` se deja en `Info.plist`**: es inerte sin iPad declarado y
  quitarlo no aporta nada.
- **Alcance:** `ios/Runner.xcodeproj/project.pbxproj`.
- **Criterios de QA:**
  1. En App Store Connect, la ficha **no** debe pedir capturas de iPad.
  2. El build de TestFlight sigue instalándose y abriendo en iPhone.

### [2026-08-25]: Cinco arreglos previos al envío a las tiendas

Lote de higiene de cara a la revisión de App Store y Play. Ninguno depende de textos legales ni de
terceros; los cinco salen en el mismo build.

- **Los enlaces legales eran ilegibles.** `documentos_legales_enlaces.dart` pintaba con
  `Theme.of(context).primaryColor`, y con `brightness: dark` Flutter resuelve eso a
  `colorScheme.surface` (`#0B1A2E`), no a `primary`. Sobre el fondo del scaffold (`#050B15`) daba
  **1.13:1**. Pasa a `colorScheme.primary` (`#5A93C4`): **6.01:1**. Importa porque es la pantalla
  donde se aceptan las condiciones, y las dos tiendas exigen poder llegar a los documentos.
- **El teclado numérico admitía letras.** `keyboardType` solo sugiere un teclado; no restringe. En
  Android se pasa a las letras con una tecla, y un teclado físico o un pegado lo saltan del todo.
  `CustomTextField` gana `inputFormatters` (opcional, para no tocar los campos de texto libre) y se
  aplica en Número de Identificación (`digitsOnly`) y Teléfono (dígitos más `+ - ( ) espacio`, porque
  el propio ejemplo del campo lleva indicativo).
- **El selector de fecha salía en inglés.** `MaterialApp.router` no declaraba localización. Se añade
  `flutter_localizations` con los tres delegados globales y `locale: es` fijo — la app es solo en
  español, así que no sigue al idioma del dispositivo. Obligó a subir `intl` de `^0.19.0` a `^0.20.2`,
  que es lo que fija el SDK.
- **Tildes en el registro:** «Contrasena» → «Contraseña», «Minimo» → «Mínimo», «Las contrasenas no
  coinciden» → «contraseñas». El resto de rótulos ya estaban bien.
- **Permisos de almacenamiento heredados en Android.** `READ_EXTERNAL_STORAGE` y
  `WRITE_EXTERNAL_STORAGE` quedan acotados con `maxSdkVersion` (32 y 28). Desde Android 13 la
  fototeca va por `READ_MEDIA_IMAGES` y desde Android 10 el de escritura no concede nada; sin el
  tope, Play los ve como permisos de almacenamiento amplio y pregunta por ellos en la ficha.

- **Alcance:** `lib/presentation/widgets/documentos_legales_enlaces.dart`,
  `lib/presentation/widgets/custom_text_field.dart`, `lib/presentation/screens/register_screen.dart`,
  `lib/main.dart`, `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`,
  `test/screens/documentos_legales_test.dart` (+2), `test/widgets/campos_numericos_test.dart` (nuevo,
  5 casos), `test/widget_test.dart` (+2).
- **Verificado:** `flutter analyze` sin errores ni advertencias (49 `info` preexistentes, ninguno de
  estos archivos); `flutter test` **205/205** (196 previos + 9). El test de contraste calcula el ratio
  WCAG real y falla con el color anterior.
- **Criterios de QA:**
  1. **En el registro**, los dos enlaces legales se leen sin esfuerzo sobre el fondo oscuro, y siguen
     abriendo cada uno su documento.
  2. **En Perfil › Avisos legales**, los mismos enlaces se leen igual de bien.
  3. **Número de Identificación**: intentar escribir letras no deja nada; pegar «abc123» deja «123».
  4. **Teléfono**: `+57 300 123 4567` se escribe entero; las letras no entran.
  5. **Nombre y empresa** siguen aceptando tildes y eñes («Compañía Muñoz»).
  6. **Fecha de nacimiento**: el selector abre en español —meses, «Cancelar», «Aceptar»— incluso con
     el teléfono configurado en inglés.
  7. **Registro completo**: los rótulos de contraseña llevan tilde y el error de longitud dice
     «Mínimo 6 caracteres».
  8. **Subir foto de perfil** desde galería y desde cámara sigue funcionando en Android 13+ y en uno
     anterior a 13, si hay a mano.

### [2026-08-22]: «Ver mi credencial» ya no queda en negro al llegar desde el detalle de un evento

Del mismo tramo 5 del 21-08: «se abrió desde el detalle de un evento y salió una pantalla en negro; la
misma ruta abierta por enlace profundo pintaba perfecta».

- **El problema:** `/evento` (`main.dart:475`) vive fuera del `ShellRoute`, mientras `/mi-credencial`
  vivía dentro. El defecto no estaba en `MiCredencialScreen` —sus pruebas ya pasaban, y por enlace
  profundo directo se veía bien—, sino en cruzar de un navegador a otro al empujar una ruta del shell
  desde una ruta que no lo es.
- **El fix:** `/mi-credencial` se sacó del `ShellRoute` y pasó a vivir junto a `/evento`, `/favorites`,
  `/article-detail` y `/video-detail` — todas rutas de nivel superior reachables desde varios sitios.
- **Alcance:** `App-Movil/lib/main.dart`.
- **Verificado:** `flutter analyze` sin errores nuevos, `flutter test` 191/191 (sin cambios en
  `mi_credencial_screen_test.dart`, que ya no depende del shell). Comprobado en el teléfono
  reproduciendo el camino exacto del hallazgo: Eventos → «Prueba Evento» → Reservar cupo → Ver mi
  credencial. Antes de este fix se reprodujo la pantalla en negro; con el fix, «Mi credencial» pinta
  completa con su QR.
- **Criterios de QA:**
  1. Inscribirse a un evento gratuito desde su detalle (`/evento`) y tocar «Ver mi credencial»: debe
     abrir la pantalla con el QR, no una pantalla en negro.
  2. Abrir «Mi credencial» desde Perfil (dentro del shell): sigue funcionando igual que antes.

### [2026-08-22]: Los foros dejan de prometer una revisión que no existe

Cierra el punto de producto «Textos de "Foros anónimos" y aviso de aprobación de
foros» de `docs/plan_revision_qa_diana_uribe.md`. Decisión del usuario: arreglar el
texto ya, no esperar a que se decida si se construye la aprobación real.

- **El problema, ya documentado desde el 21-08 (F16.3):** proponer un foro lo publica
  al instante —el modelo solo tiene active/locked/hidden/deleted, no hay ningún estado
  de aprobación—, pero la pantalla lo decía dos veces: «El foro será revisado por un
  administrador antes de hacerse público» en `forum_proposal_screen.dart:85`, y «Tu
  foro ha sido propuesto y está pendiente de revisión» en el aviso de éxito
  (línea 41). Diana lo notó de forma independiente en su revisión.
- **De paso, «Foros Anónimos» tampoco explicaba qué era.** Sin ningún subtítulo, quien
  entra desde el menú de Perfil sin haber visto el flujo de proponer un foro no tiene
  cómo saber qué significa «anónimo» ahí.
- **El fix:**
  - `forum_proposal_screen.dart`: el texto de advertencia ahora dice «El foro se
    publica de inmediato y queda visible para toda la comunidad. Tu identidad se
    mantiene oculta usando tu alias.» El aviso de éxito dice «Tu foro ya está
    publicado y es visible para la comunidad.»
  - `forums_list_screen.dart`: nuevo banner bajo el título de la pantalla —«Espacios
    de discusión de la comunidad. Tu nombre nunca se muestra: participas con el alias
    que elegiste en tu perfil.»
- **No se tocó la aprobación en sí** (seguiría siendo F16.3 si el cliente decide
  construirla) — solo se dejó de prometer algo que no pasa.
- **Alcance:** `lib/presentation/screens/forums/forum_proposal_screen.dart`,
  `lib/presentation/screens/forums/forums_list_screen.dart`.
- **Verificado:** `flutter analyze` sin avisos nuevos, `flutter test` 196/196.
  Comprobado en producción de punta a punta: se propuso un foro real
  («QA_texto_honesto_2208»), se confirmaron los tres textos en pantalla —el banner de
  la lista, el aviso antes de proponer, y el snackbar de éxito—, y se borró el foro
  de prueba desde el panel al terminar.
- **Criterios de QA:** abrir Foros Anónimos y ver el banner explicativo; tocar «+» y
  ver el aviso de publicación inmediata (no de revisión); proponer un foro y ver el
  aviso de éxito sin mención de revisión pendiente.

### [2026-08-22]: La descripción del evento ya existía; le faltaba el rótulo

Cierra el punto de producto «Descripción en la ficha de evento» de
`docs/plan_revision_qa_diana_uribe.md`. El plan asumía que faltaba el campo y una
decisión de contenido del cliente; ninguna de las dos cosas era cierta.

- **Lo que se creía:** el evento no tenía dónde mostrar una descripción, y hacía falta
  que el cliente decidiera qué texto poner.
- **Lo que había de verdad, comprobado contra `GET /api/events` en producción:**
  `EventModel.description` ya existe, `event_purchase_detail_screen.dart` ya la pinta
  (línea ~130, sin cambios en esa parte), y **el Legacy Summit ya tiene una descripción
  real**: «El encuentro de empresas familiares más importante de Latinoamérica. Tres
  días de inmersión en estrategias de crecimiento, gobierno corporativo y bienestar
  integral.» El dato está y se muestra.
- **Lo que sí faltaba:** el párrafo no tenía ningún título. Sin rótulo, un texto suelto
  entre la ubicación y la ficha técnica del evento no se lee como «esta es la
  descripción» — se confunde con cualquier otro bloque de la pantalla. Es probable que
  esto, no la ausencia del dato, sea lo que motivó el comentario de Diana.
- **El fix:** se agregó el rótulo «DESCRIPCIÓN» (mismo estilo de sección dorada que
  «PROGRAMAS ABIERTOS 2026» en `programs_screen.dart`) justo encima del párrafo.
- **De paso, un bug real que apareció al revisar esto:** el texto de respaldo cuando
  `description` viene vacío era el del propio Legacy Summit («39 sesiones, contenido de
  Harvard...») y se mostraba igual en cualquier otro evento sin descripción, como si
  fuera suya. Con el rótulo nuevo eso sería más engañoso, no menos, así que se cambió
  por «Este evento todavía no tiene descripción.»
- **Cómo se verificó sin ver la pantalla completa:** el volcado de accesibilidad de
  `uiautomator` no expone el contenido de un `SingleChildScrollView` que quede fuera
  del viewport visible —limitación de la herramienta, no del código—, así que ese
  tramo de la pantalla no se pudo confirmar por adb. Lo confirmó el usuario a mano,
  desplazándose en el Legacy Summit real.
- **Alcance:** `lib/presentation/screens/eventos/event_purchase_detail_screen.dart`.
- **Verificado:** `flutter analyze` sin avisos, `flutter test` 196/196. Confirmado en
  producción por el usuario: el rótulo «DESCRIPCIÓN» aparece con el texto real del
  Summit.
- **Criterios de QA:** abrir el detalle de cualquier evento con descripción real y
  confirmar que aparece bajo el rótulo «DESCRIPCIÓN»; abrir uno sin descripción y
  confirmar que dice «Este evento todavía no tiene descripción», no texto del Summit.

### [2026-08-22]: Corregir el teléfono al inscribirse a un evento actualiza el perfil

Cierra el punto de producto «Aprovechar el celular pedido al inscribirse a un evento» de
`docs/plan_revision_qa_diana_uribe.md`. Decisión del usuario: actualizar sin preguntar.

- **El problema:** `EventPaymentScreen` precarga el teléfono con `auth.phone` y deja
  editarlo para esa inscripción puntual (`participantPhone`), pero la corrección nunca
  volvía al perfil. Diana: «¿podemos aprovechar que confirma y pide celular al
  inscribirse a un evento y esto nos sirva para actualizar datos?»
- **El fix:** tras registrar con éxito la inscripción, si el teléfono escrito es
  distinto al del perfil, se llama a `AuthService().updateProfile(token, {'phone':
  ...})` —el mismo patrón de actualización parcial de un solo campo que ya usa
  `forums_list_screen.dart` para el alias— y se refresca `AuthProvider` con
  `fetchProfile()`. Sin diálogo de confirmación, como se decidió.
- **No bloquea la inscripción si falla:** va en su propio `try/catch`; el cupo ya quedó
  reservado y un error de sincronización del perfil no debe perderlo.
- **Alcance:** `lib/presentation/screens/eventos/event_payment_screen.dart`.
- **Verificado:** `flutter analyze` sin avisos nuevos, `flutter test` 196/196 (los 11
  casos de `event_payment_screen_test.dart` siguen pasando; no se agregó una prueba
  nueva para la llamada de red porque `AuthService()` no está inyectado en esta
  pantalla —mismo patrón sin inyectar que ya tiene `PaymentService()` en el mismo
  archivo—, así que verificarlo por unit test habría exigido ampliar el alcance).
  Comprobado en producción de punta a punta: se inscribió a Johan al Legacy Summit,
  cambiando el teléfono a un número de prueba (`3009998877`); la pasarela de pago
  falló como ya se sabe (CredibanCo bloqueado), pero el cupo quedó reservado y el
  panel de administración confirma el teléfono nuevo en el perfil.
- **Criterios de QA:** en un evento de pago, cambiar el teléfono del formulario de
  inscripción y confirmar: el perfil debe quedar con el teléfono nuevo aunque la
  pasarela de pago falle después.

### [2026-08-22]: «Nuevo cada semana» deja de agotar el artículo ahí mismo

Cierra el punto de producto «"Nuevo cada semana" muestra el artículo completo» de
`docs/plan_revision_qa_diana_uribe.md`. Cambio mínimo, decisión del usuario: dejar de
mostrar el título completo y el destino puntual, sin construir un resumen real
multi-fuente (eventos + contenido + programas).

- **El problema:** la tarjeta pedía el último post por GraphQL, mostraba su título
  completo como subtítulo («Esta semana: "El gerente fusible..."») y el toque llevaba
  directo a ese artículo. Diana: «sugiero que no se lea todo el artículo nuevo ahí, sino
  que muestre qué evento habrá nuevo, qué artículo, qué programa inicia, etc. Y que al
  dar clic lleve a la sección correspondiente.»
- **El fix:** se quitó la consulta a `getPosts(first: 1)` y el `FutureBuilder` que la
  envolvía. El subtítulo vuelve a ser el texto genérico por rol que ya existía como
  respaldo («Esta semana: video de conversaciones difíciles, evento familiar...», y su
  variante para empresa/junta), y el toque siempre lleva a Legacy Knowledge
  (`/informandote`), no a un artículo puntual.
- **Alcance:** `lib/presentation/screens/home/home_content_screen.dart`.
- **Verificado:** `flutter analyze` sin avisos, `flutter test` 196/196. Comprobado en el
  teléfono: el subtítulo ya no trae el título del artículo, y tocar la tarjeta abre
  Legacy Knowledge.
- **Esto invalida F9.5 del plan de 226 casos, no solo un detalle suyo.** F9.5 verificaba
  justo el mecanismo que se quitó: «el destacado se sustituye por el último post real,
  sin importar el rol». Ahora la tarjeta siempre muestra el texto genérico por rol; ya
  no hay ninguna sustitución por contenido real. Es un cambio de comportamiento
  deliberado —decisión del cliente—, no una regresión que haya que arreglar, pero deja
  F9.5 desactualizado tal como está escrito. Anotado en `plan_pruebas.html`.

### [2026-08-22]: Programas se restructura en 3 secciones, sin pantalla de detalle

Cierra el punto de producto «Restructurar Programas» de
`docs/plan_revision_qa_diana_uribe.md`.

- **La propuesta de Diana traía 8 títulos; solo 4 existen tal cual en la tienda.**
  Comprobado contra el GraphQL real de `lso.school` (32 productos en la categoría
  «programas»): los 3 de «certificación EUDE» coinciden exacto. De los 5 de
  «actualización», solo 1 coincide exacto (Juntas, Consejos y Directorios); 2 tienen un
  programa real bajo un título distinto —«Gestión del Riesgo Cambiario: Conceptos y
  Herramientas» en vez de «Curso Introducción al Manejo de Riesgo Cambiario...», y
  «Gestión Patrimonial para Empresarios» en vez de «...y valoración de empresas»— y 2 no
  tienen ningún programa parecido («Gestión de conflictos», «Board branding»). Decisión
  del usuario: usar los títulos reales para los 2 que sí existen, dejar fuera los 2 que
  no existen en absoluto, en vez de mostrar tarjetas sin destino.
- **`programs_screen.dart` se restructuró de una lista plana de hasta 32 cursos** (con
  matching heurístico por palabras del título para rellenar campos falsos: «si el título
  contiene 'Propietarios'...») **a 3 secciones fijas**: certificación EUDE (3 programas),
  actualización (3 programas, de los 5 propuestos), e in-company/in-family (sin producto
  propio en la tienda — es un servicio a medida, la tarjeta lleva a Contáctenos).
- **Cada fila abre directo la página de pago en `lso.school`**, en vez de la pantalla de
  detalle interna. Es lo que pedía Diana: «no hay mucha información como para
  convencerme de comprarlo, pero sí hay énfasis en que pague [...] que los redirija a la
  página para pagar no más». La pantalla de detalle (`program_detail_screen.dart`) sigue
  existiendo para cuando se llega por la búsqueda global, que no se tocó.
- **Alcance:** `lib/presentation/screens/programs/programs_screen.dart` (reescrito).
- **Verificado:** `flutter analyze` sin avisos nuevos, `flutter test` 196/196 (incluida
  `biblioteca_alcanzable_test.dart`, que sigue pasando porque el enlace a `/libros`
  y el texto «Biblioteca» se conservaron). Comprobado en el teléfono contra producción:
  las imágenes reales de cada producto cargan, los precios («Cotización» o «USD $...»)
  vienen del GraphQL, y tocar una fila abre el navegador externo en la página real del
  producto (`lso.school/programas/programa-de-formacion-para-familias-empresarias-y-propietarios/`).
- **Criterios de QA:**
  1. Abrir LSO · Escuela: deben verse dos secciones con encabezado dorado
     («PROGRAMAS CON CERTIFICACIÓN EUDE», «PROGRAMAS DE ACTUALIZACIÓN») y una tarjeta de
     in-company al final.
  2. Tocar cualquier fila de programa: debe abrir el navegador externo en `lso.school`,
     no una pantalla dentro de la app.
  3. Tocar la tarjeta in-company: debe abrir Contáctenos.

### [2026-08-22]: Íconos en las filas de Perfil que no tenían

- **El problema:** 6 de las filas del menú de Perfil no tenían ícono —«Mi Legacy Test»,
  «Mi formación LSO», «Mis eventos», «Red de Gobierno», «Cambiar tipo de cuenta», «Mi
  credencial»—, mientras el resto sí. Pedido directo del usuario al ver la lista con
  «Mis favoritos» recién agregado (que sí trae ícono).
- **El fix:** `Icons.quiz_outlined`, `Icons.school_outlined`,
  `Icons.calendar_today_outlined`, `Icons.groups_outlined`, `Icons.swap_horiz_outlined` y
  `Icons.qr_code_outlined` respectivamente, reutilizando semántica ya usada en otras
  partes de la app (`groups_outlined` es el mismo de «Comunidad» en el menú «⋮»;
  `calendar_today_outlined` es el mismo de la pestaña Eventos).
- **Alcance:** `lib/presentation/screens/profile/profile_screen.dart`.
- **Verificado:** `flutter analyze` sin avisos.

### [2026-08-22]: Favoritos gana acceso propio en Perfil

Cierra el punto 3 de la parte de producto de `docs/plan_revision_qa_diana_uribe.md`
(«Dónde ubicar el acceso a Favoritos»). El usuario eligió agregarlo a la lista de Perfil,
de primero.

- **El problema:** Favoritos solo se alcanzaba desde el menú «⋮» de una pantalla de
  detalle (Books, Chat, Foros...) — ninguna de las 5 pestañas principales tenía un
  acceso propio. Quien guardaba un artículo desde el Inicio no tenía forma de volver a
  encontrarlo sin toparse con ese menú por casualidad; es justo lo que le pasó a Diana.
- **El fix:** nueva fila «Mis favoritos» en `profile_screen.dart`, primera de la lista
  —antes de «Active Legacy+»—, con el mismo ícono (`Icons.bookmark_outline`) que ya usa
  la entrada de Favoritos en el menú «⋮».
- **Alcance:** `lib/presentation/screens/profile/profile_screen.dart`.
- **Verificado:** `flutter analyze` sin avisos, `flutter test` 196/196. Comprobado en el
  teléfono: «Mis favoritos» aparece de primera en Perfil y abre la pantalla de
  favoritos.
- **Criterios de QA:** abrir Perfil y confirmar que «Mis favoritos» es la primera fila
  de la lista, antes de «Active Legacy+»; tocarla debe abrir la pantalla de Favoritos.

### [2026-08-22]: Parte técnica de la revisión de Diana Uribe (LSO)

Ver `docs/plan_revision_qa_diana_uribe.md` para el plan completo, incluida la parte de
producto que sigue esperando decisión del cliente. Esta entrada cubre lo que sí se pudo
resolver con código.

- **El paso «Empresa» del registro solo distinguía Colombia de «Otro»**, y ese «Otro»
  ofrecía tipos de identificación de persona (Pasaporte, Documento extranjero) para lo
  que en realidad es el documento tributario de una empresa. Nuevo:
  `domain/utils/identificacion_empresarial.dart`, con 17 países LATAM y su documento
  real (RFC en México, RUC en Perú, RUT en Chile, CUIT en Argentina...). Colombia
  conserva Cédula/Tarjeta de identidad además de NIT, porque un negocio unipersonal
  puede tributar con su cédula. 5 pruebas nuevas.
- **«Estado de Cliente/Alumni» no se entendía**: el desplegable lista las unidades de
  Legacy sin explicar la pregunta. Se le agregó `helperText`: «¿Ya eres cliente o alumni
  de alguna de estas unidades de Legacy?».
- **El ícono del asistente cambiaba de forma sin motivo**: `Icons.psychology_outlined`
  en el botón flotante de Inicio, `Icons.headphones_outlined` en el de Legacy Knowledge,
  mismo botón y mismo destino (`/chatbot`) en los dos. Se unificó al de Inicio.
- **«Red de Gobierno» (Perfil → Miembros) mostraba el error crudo del backend**:
  `community_members_screen.dart` pintaba literal `'Error: $e'`, es decir
  `"Error: Exception: connection already exists or is pending"`, sin traducir. Ahora
  `_mensajeDeInvitacion` traduce los tres casos reales del backend
  (`chat_service.go:41-61`: ya existe la conexión, está bloqueado, o te invitas a ti
  mismo) y cualquier otro cae en un mensaje genérico en español.
- **Investigado y descartado como bug — «Legacy+ no me reconoce como comunidad»**:
  `legacy_plus_screen.dart` es una pantalla puramente informativa, sin ninguna lógica
  de rol ni de estado de cuenta —de hecho no importa ningún provider—. El único
  elemento tocable de toda la pantalla es la flecha de atrás: no hay ningún botón para
  activarse, contactar ventas ni nada parecido. No es que la cuenta de Diana no
  califique; es que la pantalla no ofrece ninguna acción. Queda para la parte de
  producto del plan, no es código roto.
- **Dejado para decisión del cliente — «Intereses» del registro**: la lista completa es
  literalmente `['Gobierno corporativo', 'Familia empresaria']`
  (`register_screen.dart:444`). No hay ninguna lista de categorías en el resto del
  código de la que deducir cuáles faltan, así que no se inventó una — queda en la parte
  de producto del plan.
- **Alcance:**
  - `lib/domain/utils/identificacion_empresarial.dart` — nuevo.
  - `lib/presentation/screens/register_screen.dart` — país, tipo de identificación,
    ayuda de «Estado de Cliente/Alumni».
  - `lib/presentation/screens/informandote/informandote_screen.dart` — ícono del FAB.
  - `lib/presentation/screens/chat/community_members_screen.dart` — mensaje de error.
- **Verificado:** `flutter analyze` sin avisos nuevos (los 3 `info` de
  `use_build_context_synchronously` en `community_members_screen.dart` ya existían
  antes de tocar el archivo, confirmado con `git stash`). `flutter test`: 196/196.
  Instalado en el teléfono conectado.
- **Criterios de QA:**
  1. Registrarse como empresa, elegir un país LATAM distinto de Colombia (por ejemplo
     México) y confirmar que el tipo de identificación ofrece RFC, no Pasaporte
     genérico.
  2. En el mismo paso, ver que «Estado de Cliente/Alumni» trae una frase de ayuda debajo
     del desplegable.
  3. Comparar el ícono del botón flotante del asistente en Inicio y en Legacy Knowledge:
     debe ser el mismo.
  4. En Perfil → Red de Gobierno, invitar dos veces a la misma persona: el segundo
     intento debe explicar en español que ya existe la invitación, no mostrar
     `Exception: ...`.

### [2026-08-22]: Cinco hallazgos del tramo 5 (21-08) cerrados, más una advertencia al salir

Todos venían de `reports/20260820_ruta_pruebas_manuales.html`, sección «Lo que sacó la jornada del
21-08» — hallazgos que ningún caso del plan buscaba.

- **`GET /api/synergies` ya no devuelve `null` en vacío.** `ListSynergies`
  (`internal/adapter/storage/postgres/synergy_repository.go`) declaraba `var synergies []domain.Synergy`:
  sin filas, el slice quedaba `nil` y `encoding/json` lo serializa como `null`, no `[]`. Cambiado a
  `make([]domain.Synergy, 0)`. Comprobado con `curl` local: `?category=NoExiste123` da `[]`.
- **La ficha de programa ya no cruza sus propias etiquetas.** `_buildInfoRow('Certificación',
  program.duration)` y `_buildInfoRow('Cuotas', program.type)` en `program_detail_screen.dart:190,195`
  rotulaban duración como «Certificación» y tipo (Programa/Módulo/Curso) como «Cuotas» — ninguno de los
  dos campos tiene que ver con esos nombres, ninguna certificación ni cuotas existe en el modelo. Ahora
  dicen «Duración» y «Tipo».
- **El buscador de Eventos ya no distingue tildes.** `applyEventFilters`
  (`domain/utils/event_filters.dart`) comparaba con `.toLowerCase().contains(q)` sin más: buscar
  «sesion» no encontraba «Sesión». Reutiliza `normalizar()` de `domain/utils/busqueda_global.dart`, la
  misma función que ya evitaba este problema en el buscador global. 2 pruebas nuevas en
  `event_filters_test.dart` (16/16 en verde).
- **Favoritos y el Asistente dejan de salir en tema claro.** Las dos pantallas tenían `Colors.white`,
  `Colors.grey` y `Colors.black87` cableados desde el commit inicial, mientras el resto de la app usa la
  paleta oscura de `AppTheme` (`0xFF050B15`/`0xFF0B1A2E`/`0xFF2A4A75`). Quedaron con esos mismos tonos.
  Comprobado en el teléfono: las dos pantallas —incluida la burbuja del bot, los chips de acción y la
  caja de texto del Asistente— se ven ahora igual de oscuras que el resto de la app.
- **Alcance:**
  - `Backend/internal/adapter/storage/postgres/synergy_repository.go`
  - `App-Movil/lib/presentation/screens/programs/program_detail_screen.dart`
  - `App-Movil/lib/domain/utils/event_filters.dart` + `test/utils/event_filters_test.dart`
  - `App-Movil/lib/presentation/screens/favorites/favorites_screen.dart`
  - `App-Movil/lib/presentation/screens/chat/chatbot_screen.dart`
- **Verificado:** `go build`/`go vet` limpios; `flutter analyze` sin avisos; `flutter test` 191/191 en
  verde (185 antes + los 2 casos nuevos, más los ya existentes). Los cuatro cambios visuales se
  comprobaron en el teléfono conectado con el APK reinstalado.

🟢 **Pedido aparte durante esta ronda: advertencia al salir de la app.** Salió porque una notificación de
otra app tapó un toque y disparó una salida accidental sin querer. `MainLayout` (el shell con la barra
inferior) ahora envuelve su `Scaffold` en un `PopScope` que solo intercepta el botón atrás **en la
pestaña Inicio** —en las demás, atrás sigue teniendo a dónde volver dentro de la app— y muestra
«¿Salir de Legacy Network?» antes de cerrar. Comprobado en el teléfono: cancelar se queda en Inicio,
salir cierra la app.
- **Alcance:** `App-Movil/lib/presentation/screens/main_layout.dart`.
- **Criterios de QA:**
  1. En Inicio, tocar atrás: aparece «¿Salir de Legacy Network?» con Cancelar/Salir.
  2. Cancelar deja la app abierta, en Inicio.
  3. Salir cierra la app.
  4. En cualquier otra pestaña, atrás navega dentro de la app sin mostrar el diálogo.

### [2026-08-20]: La Biblioteca ya se puede alcanzar

- **El problema:** la ruta `/libros` existía desde el commit inicial y la pantalla estaba completa
  —cinco libros con portada, precio y enlace a la tienda—, pero **ninguna pantalla enlazaba a ella**.
  Ni el menú lateral, ni el Inicio, ni Legacy Plus, ni la barra inferior.
- **El único camino era el asistente:** escribirle algo con la palabra «libro» hace que responda con un
  enlace interno a `/libros`. Nadie llega ahí por casualidad.
- **Se descubrió al intentar probarla**, cuando no había forma de abrir la sección. La tienda sí tenía
  los cinco libros: comprobado con la consulta exacta de la app contra `lso.school/graphql`.
- **Va en la sección de LSO por decisión del cliente** (2026-08-20): los libros salen de la misma
  tienda que los programas, así que es donde se buscan.
- **Colocada bajo la tarjeta de presentación y sobre «PROGRAMAS ABIERTOS 2026»**, para que se vea sin
  desplazar. **Compacta a propósito** —una fila, no una tarjeta como las de los programas—: los libros
  acompañan a la formación, no compiten con ella.
- **La prueba mira el código fuente**, no pinta widgets: lo que se perdió no fue un elemento sino la
  existencia de un camino, y eso no lo detecta un widget test de la pantalla.
- **Alcance:**
  - `presentation/screens/programs/programs_screen.dart` — la entrada.
  - `test/screens/biblioteca_alcanzable_test.dart` — nuevo, 2 pruebas.
- **Verificado:** `flutter analyze` sin errores ni avisos y **189 pruebas** en verde (187 antes).
  Comprobado en el teléfono: la fila se ve sin desplazar, abre la Biblioteca con los cinco libros, y el
  icono de un libro abre su página en la tienda.
- **Nota sobre el destino:** la página de LSO se ve mal en un teléfono —elementos superpuestos, el
  carrito de la tienda encima del contenido—. No es de la app, pero es adonde mandamos a comprar.
- **Criterios de QA:**
  1. **Abrir LSO · Escuela:** la fila «Biblioteca · Los libros de LSO» se ve sin desplazar.
  2. **Tocarla:** abre la Biblioteca con los libros publicados.
  3. **Tocar el icono de un libro:** abre su página en la tienda.
  4. **Volver:** regresa a la Biblioteca, y otra vez atrás a LSO.
  5. **Comprobar que sigue funcionando el camino del asistente** («libros»).
  6. **Si algún día la tienda no responde:** la Biblioteca muestra su estado vacío, no una pantalla rota.

### [2026-08-20]: Ningún enlace externo se abría en Android 11 o superior

- **El problema:** `AndroidManifest.xml` declaraba `<queries>` **solo** para `PROCESS_TEXT` —el bloque
  que trae Flutter por defecto—. Desde Android 11 una app solo «ve» las aplicaciones que declara ahí,
  así que **`canLaunchUrl` devolvía `false` aunque hubiera navegador instalado**.
- **Nueve puntos de la app preguntan con `canLaunchUrl` antes de abrir**, y todos quedaban muertos:
  - `data/config/documentos_legales.dart` — **términos y política de privacidad**, que Apple y Google
    exigen alcanzables desde la app;
  - `eventos/event_payment_screen.dart` — **la pasarela de pago**;
  - `informandote/article_detail_screen.dart` y `video_detail_screen.dart` — enlaces del contenido;
  - `login_screen.dart` y `widgets/app_banner.dart` — legales del login y banners con enlace;
  - `programs/program_detail_screen.dart` y `domain/utils/abrir_en_lso.dart` — la tienda de LSO.
- **Por qué nadie lo había notado:** los sitios que llaman a `launchUrl` **sin** preguntar antes —el de
  contacto, uno del artículo— sí funcionaban. El fallo solo aparece donde se comprueba primero.
- **Explica que F3.11 nunca se hubiera ejecutado**: «abrir los dos enlaces legales; las tiendas exigen
  que sean alcanzables» habría fallado en cualquier teléfono moderno.
- **Se declaran dos intents:** `VIEW + https` y `VIEW + mailto`, que son los dos únicos esquemas que
  lanza la app. No se declara nada más: `<queries>` es una lista de lo que la app necesita ver, no un
  comodín.
- **Alcance:** `android/app/src/main/AndroidManifest.xml`.
- **Verificado:** comprobado con `aapt2 dump xmltree` que los dos intents viajan en el APK compilado, y
  después en el teléfono: el botón de LSO abre el navegador.
- **Criterios de QA:**
  1. **Abrir los dos enlaces legales** desde el menú de la app: cargan en el navegador. Es F3.11.
  2. **Tocar «Inscribirme en LSO»** en un programa: abre la tienda.
  3. **Un enlace dentro de un artículo o de un vídeo:** abre.
  4. **Un banner con enlace:** abre.
  5. **Comprar un evento de pago:** la pasarela abre —pendiente de que se desbloquee—.
  6. **En un Android 10 o anterior:** sigue funcionando igual; la restricción es de API 30 en adelante.

---

### [2026-08-20]: El enlace del programa se perdía entre la lista y el detalle

- **El problema:** «Inscribirme en LSO» avisaba «No pudimos abrir la página del programa» y no hacía
  nada. El enlace estaba en el modelo y llegaba de la tienda, pero **no llegaba a la pantalla de
  detalle**.
- **La causa:** `programs_screen.dart` no pasa el objeto que devuelve el GraphQL. Construye un
  `_LsoProgram` para pintar la tarjeta y, al abrir el detalle, **reconstruye** un `GraphqlProgram` a
  partir de ella para añadirle los textos de marketing —formato, certificación, cuotas—. Esa copia
  nacía **sin `url`** y con un **id inventado** a partir del título.
- **Así que la comprobación funcionaba y el dato no existía:** `program.url` era siempre `null` y el
  aviso saltaba sin intentar abrir nada.
- **Se conservan `id` y `url` en la tarjeta** y la copia los arrastra. Son lo único que no puede
  reconstruirse desde el título; el resto sí.
- **Se descubrió al probar en el teléfono**, después de haber arreglado un fallo distinto que también
  impedía abrir enlaces —el `<queries>` del manifiesto—. Dos causas encadenadas para el mismo síntoma.
- **Alcance:**
  - `presentation/screens/programs/programs_screen.dart` — la tarjeta conserva id y enlace.
  - `test/screens/programa_conserva_enlace_test.dart` — nuevo, 3 pruebas.
- **Lo que enseña:** el cambio de LSO se dio por bueno con pruebas de modelo y de widget, y **ninguna
  cubría el trayecto entre las dos pantallas**. Ver el botón en una captura no es lo mismo que pulsarlo.
- **Verificado:** `flutter analyze` sin errores ni avisos, **187 pruebas** en verde (184 antes), y
  comprobado en el teléfono: el botón abre el navegador en la página del programa.
- **Criterios de QA:**
  1. **Abrir un programa y tocar «Inscribirme en LSO»:** abre la página **de ese** programa.
  2. **Repetir con otro programa distinto:** abre la suya, no la del primero.
  3. **Volver a la app:** sigue en la ficha.
  4. **Un programa sin enlace** (hoy no hay ninguno): sale el aviso, no un toque mudo.
  5. **Los libros:** siguen abriendo su página, que usan otro camino.

### [2026-08-20]: Los precios de los eventos dicen que son dólares

- **Por qué:** los eventos se cobran en dólares —confirmado por el cliente el 2026-08-20—, pero
  `CurrencyFormatter` los formateaba con locale `es_CO` y un «$» suelto. El Legacy Summit, de 499
  dólares, se veía como **«499 $»**: la cifra sin moneda, con formato colombiano y junto a contenido en
  pesos. **499 pesos son doce centavos de dólar**, y nada en la pantalla permitía distinguirlo.
- **Salió recorriendo el tramo 2** de la ruta de pruebas manuales sobre el teléfono, mirando la lista de
  eventos de producción: Summit a 499 y Coffee & Networking a 25, dos cifras que solo tienen sentido en
  dólares.
- **Se arregla en el formateador y no en cada pantalla:** es el único punto por el que pasan los precios
  de evento —la tarjeta del listado, la pantalla de pago y la de confirmación—, así que las tres dicen
  la moneda a la vez.
- **La moneda va delante —«USD $499»—** igual que en los programas de LSO (`precioConMoneda`): si la
  cifra queda justa de sitio, lo primero que se lee sigue siendo de qué moneda se habla. Las dos
  superficies con precio de la app lo dicen de la misma forma.
- **Gratis sigue siendo gratis:** un evento sin precio dice «GRATIS», no «USD $0».
- **Se conserva la agrupación de miles con punto** (`150000` → `USD $150.000`), que es como se escribe
  aquí y como lo publica la tienda de LSO.
- **⚠️ Esto arregla lo que se ve, no lo que se cobra.** La app manda a la pasarela el importe en
  centavos y **la divisa la fija el comercio en CredibanCo** —está documentado en
  `Backend/internal/infrastructure/credibanco/client.go`: `currency` no se envía a propósito—. Si esa
  cuenta está configurada en pesos, un Summit de «USD $499» se cobraría como 499 pesos. **Hay que
  confirmarlo con el banco antes de desbloquear la pasarela**; no se puede comprobar desde aquí.
- **Alcance:**
  - `config/utils/currency_formatter.dart` — la moneda y su documentación.
  - `test/utils/currency_formatter_test.dart` — nuevo, 5 pruebas.
- **Verificado:** `flutter analyze` sin errores ni avisos, **184 pruebas** en verde (179 antes), y
  comprobado en el teléfono contra producción: la tarjeta del Summit muestra «USD $499» y la de la
  sesión gratuita sigue diciendo «Gratis».
- **Criterios de QA:**
  1. **Abrir Eventos:** los de pago muestran «USD $…».
  2. **Un evento gratuito:** sigue diciendo «Gratis», sin moneda.
  3. **Abrir un evento de pago y llegar a la pantalla de pago:** el importe también lleva la moneda.
  4. **La pantalla de confirmación:** igual.
  5. **Comparar con los programas de LSO:** los dos sitios dicen la moneda de la misma forma.
  6. **Antes de cobrar de verdad:** confirmar con CredibanCo en qué divisa está configurado el comercio.

### [2026-08-20]: El encabezado dice en qué pantalla estás

Cierra F24.3 y F24.4 del plan de pruebas. Sustituye a la entrada anterior de hoy sobre el mismo widget.

- **El problema:** `CustomSectionHeader` mostraba siempre «LEGACY / Network®». Las **diez** pantallas que
  lo usan se veían idénticas y ninguna decía dónde estabas, mientras cada una pasaba un `title` que el
  widget declaraba obligatorio y no pintaba.
- **Se pinta en la segunda línea del bloque de marca**, donde iba «Network®». Se conserva «LEGACY»
  arriba: es la mitad que reconoce la marca, y perderla en las pantallas interiores habría sido peor
  que repetir «Network®» diez veces. Sin título, se sigue viendo «Network®».
- **Se recortan tres nombres, y se vieron mal solo al pintarlos:**
  - `ASISTENTE LEGACY` → **ASISTENTE**. Con el logotipo encima quedaba «LEGACY / ASISTENTE LEGACY».
  - `MIEMBROS DE LA COMUNIDAD` → **MIEMBROS**. Era el más largo de los diez y la sección ya se llama
    Comunidad.
  - `DETALLE DE SINERGIA` → **SINERGIA**. Que es el detalle se ve; decirlo no aporta.
- **Los otros siete se quedan:** BIBLIOTECA, CHAT DE CEOS, COMITÉ DE SINERGIAS, COMUNIDAD, CUENTAS
  BLOQUEADAS, NUEVA SINERGIA y el nombre de la persona en el chat individual.
- **Uno merece consulta al cliente: «CHAT DE CEOS».** El chat es entre miembros, y el cuarto perfil que
  se añadió el 18-08 es *miembro de junta o consejo*, no CEO. No se toca sin preguntar: es su
  vocabulario, no un descuido de implementación.
- **Una línea, con recorte por si acaso:** `maxLines: 1` y elipsis. Con los nombres actuales sobra
  sitio —el más largo pasa a ser COMITÉ DE SINERGIAS—, pero el chat individual muestra el nombre de la
  persona, que no se controla desde aquí.
- **Menos espaciado que el «Network®» al que sustituye** (1.0 en vez de 1.5), porque un nombre de
  sección es más largo que una palabra de marca.
- **Comprobado en el teléfono**, que es donde se vieron los tres nombres a recortar: el asistente
  muestra «LEGACY / ASISTENTE».
- **Alcance:**
  - `presentation/widgets/custom_section_header.dart` — pinta `title` y documenta el campo.
  - `chat/chatbot_screen.dart`, `chat/community_members_screen.dart`,
    `community/synergy_detail_screen.dart` — los tres nombres.
- **Verificado:** `flutter analyze` sin errores ni avisos y **179 pruebas** en verde.
- **Criterios de QA:**
  1. **Abrir el asistente:** el encabezado dice «LEGACY / ASISTENTE».
  2. **Recorrer las diez pantallas con ese encabezado:** cada una muestra su nombre bajo el logotipo.
  3. **Abrir un chat con una persona de nombre largo:** se recorta con puntos suspensivos, no desborda.
  4. **Comparar cada nombre con el sitio desde el que se entra:** dicen lo mismo.
  5. **Con el tamaño de letra del sistema aumentado:** el encabezado no se rompe.
  6. **Preguntar al cliente por «CHAT DE CEOS»**, que es el único nombre en duda.

### [2026-08-20]: El asistente deja de llamarse «BOT CONTACTANOS» en el código, y aparece por qué eso no se veía

- **Lo que se cambió:** el título que `chatbot_screen.dart` pasa al encabezado pasa de
  `BOT CONTACTANOS` a `ASISTENTE LEGACY`. El nombre anterior ni mencionaba Legacy —lo que pide la
  directriz de identidad, F23.5— ni se distinguía de la sección *Contacto*, que es otra cosa.
- **⚠️ En pantalla no cambia nada, y ese es el hallazgo.** `CustomSectionHeader` **declara `title` como
  parámetro obligatorio y no lo pinta en ninguna parte**: el centro del encabezado muestra siempre la
  marca «LEGACY / Network®». Las **diez** pantallas que usan ese widget pasan un nombre que nadie ve.
- **Cómo se descubrió:** al comprobar el cambio en el teléfono. La captura mostró la marca donde se
  esperaba el nombre nuevo. Se había reportado que el asistente «se llama BOT CONTACTANOS» leyendo el
  código, sin haberlo visto en pantalla; en la app no se llama de ninguna manera.
- **F23.5 en realidad se cumple:** el encabezado enseña el logo y el nombre de Legacy Network.
- **Las pantallas que sí muestran su título lo pintan en su cuerpo**, no en el encabezado — Legacy
  Knowledge es el ejemplo, con su nombre y su bajada propios.
- **Se documenta el parámetro en el widget** para que no vuelva a usarse como fuente de verdad sobre
  cómo se llama una pantalla. Se conserva en vez de retirarlo: es el sitio natural si algún día el
  encabezado enseña el nombre de la sección, y quitarlo obligaría a tocar diez pantallas para nada.
- **Queda una decisión de producto:** hoy **ninguna pantalla se identifica en su encabezado**. Si el
  cliente quiere que se vea dónde está —que es lo que buscaba F24.3—, hay que pintar `title` en el
  centro junto a la marca o debajo de ella, y revisar los diez nombres de una vez.
- **Alcance:**
  - `presentation/screens/chat/chatbot_screen.dart` — el título que pasa.
  - `presentation/widgets/custom_section_header.dart` — la advertencia sobre `title`.
- **Verificado:** `flutter analyze` sin errores ni avisos y **179 pruebas** en verde. No se compiló un
  APK nuevo para esto: no hay nada visible que comprobar.
- **Criterios de QA:**
  1. **Abrir el asistente:** el encabezado muestra el logo y «LEGACY Network®», como el resto.
  2. **Comprobar que sigue funcionando:** saluda y responde igual.
  3. **Recorrer otras pantallas con ese encabezado:** todas muestran la marca, ninguna su nombre.
  4. **Si se decide pintar el título:** revisar los diez nombres antes, no después.

### [2026-08-20]: La pestaña de la barra inferior pasa a llamarse «KNOWLEDGE»

Cierra F24.1 del plan de pruebas.

- **El problema:** la sección se llama «Legacy Knowledge» en el home, el menú lateral, su encabezado y
  Legacy Plus —se unificaron el 18-08 después de que el cliente lo reportara—, pero **la pestaña de la
  barra inferior decía «CONOCER»**, y es la vía de entrada que más se usa. Se pulsaba una cosa y se
  aterrizaba en otra: eso es lo que hacía pensar que eran dos sitios distintos.
- **Se cambia la pestaña, no las otras cuatro.** El nombre oficial ya estaba decidido por el cliente;
  mover los cuatro sitios habría deshecho esa decisión cinco días después de tomarla.
- **«KNOWLEDGE» y no «CONOCER»:** al acortar un nombre se conserva la mitad que lo identifica.
  «CONOCER» no conserva ninguna, y además es un verbo entre cuatro sustantivos —INICIO, EVENTOS,
  LEGACY+, PERFIL—. Se descartó «LEGACY» a secas: la barra ya tiene LEGACY+ y dos pestañas que empiezan
  igual invitan a pulsar la equivocada.
- **No cabía, y se vio en el teléfono.** A `fontSize: 11` con `letterSpacing: 0.5` la etiqueta salía
  recortada como **«KNOWLED...»**. Se bajó a **10 con 0.1** y entra completa; comprobado con captura
  sobre el dispositivo, no calculado.
- **El estilo baja para las cinco etiquetas y no solo para esa:** `BottomNavigationBar` aplica un único
  `selectedLabelStyle`, y desigualarlas a mano se vería peor que el recorte que se quería evitar.
- **Comprobado el circuito entero:** la pestaña dice KNOWLEDGE, y al pulsarla el encabezado del destino
  dice «Legacy Knowledge» y su buscador «Buscar en Legacy Knowledge».
- **Alcance:** `presentation/screens/main_layout.dart` — la etiqueta y los dos estilos de la barra.
- **Verificado:** `flutter analyze` sin errores ni avisos y **179 pruebas** en verde.
- **Criterios de QA:**
  1. **Mirar la barra inferior:** las cinco etiquetas se leen enteras, ninguna con «...».
  2. **Pulsar KNOWLEDGE:** abre la sección y su encabezado dice «Legacy Knowledge».
  3. **Comparar con el home, el menú lateral y Legacy Plus:** los cinco sitios dicen lo mismo.
  4. **En un teléfono más estrecho que el de prueba** (1080 px de ancho): comprobar que sigue entrando.
  5. **Con el tamaño de letra del sistema aumentado:** mirar si alguna etiqueta se recorta.
  6. **Las otras cuatro pestañas:** siguen llevando a donde llevaban.

### [2026-08-20]: Se retira el carrito: no quedaba nada que pudiera entrar en él

- **Por qué:** desde que programas y libros de LSO se compran en su tienda (2026-08-19), **nada
  alimentaba el carrito**. Y los eventos de pago —lo único que quedaba con precio dentro de la app—
  **nunca pasaron por él**: se compran desde su propia ficha, con `event_payment_screen.dart` y
  `POST /api/payments/intent`. El carrito era una pantalla viva que solo podía decir «Tu carrito está
  vacío». Decisión del cliente del 2026-08-20.
- **Alcance (se retiran):**
  - `presentation/screens/cart/` — `cart_screen.dart`, `checkout_screen.dart`, `confirmation_screen.dart`.
  - `domain/providers/cart_provider.dart` y `domain/models/cart_item.dart`.
  - `main.dart` — las rutas `/cart`, `/checkout` y `/confirmation`, el `CartProvider` del árbol de
    providers y sus cuatro imports.
  - `presentation/screens/eventos/eventos_screen.dart` — el botón flotante del carrito.
  - `domain/models/program_model.dart` — `priceValue`, que existía solo para meter el precio al carrito.
  - `test/providers/carrito_un_elemento_test.dart` y las pruebas de `priceValue`.
- **El botón flotante de la agenda se queda**, ahora solo: al quitar el del carrito, la columna de dos
  botones sobra y el `Column` se sustituye por el botón suelto.
- **El icono de comprar en la ficha del libro pasa a «salir de la app»**, como ya estaba en el listado.
  Era el último carrito visible de la interfaz.
- **Lo que NO cambia: comprar un evento de pago.** Sigue igual, por su ficha y su pasarela. Este cambio
  no toca el pago de eventos ni la pasarela, que sigue bloqueada desde el 6 de agosto.
- **La alternativa que se descartó** era llevar los eventos de pago por el carrito. Se dejó porque el
  flujo del evento ya existe, está probado y no depende del carrito para nada: rehacerlo habría creado
  dos caminos de pago compitiendo justo sobre una pasarela bloqueada.
- **Si algún día vuelve a hacer falta un carrito** —varios eventos en una compra, por ejemplo— está en
  el historial: `git show 82759c4` trae la última versión, ya con un solo elemento y sin datos falsos.
- **Verificado:** `flutter analyze` sin errores ni avisos y **179 pruebas** en verde. Bajan 11 respecto
  a las 190 de ayer: 9 del carrito y 2 de `priceValue`, que se van con lo que probaban.
- **Criterios de QA:**
  1. **Abrir Eventos:** solo hay un botón flotante, el de la agenda, y abre la agenda.
  2. **Buscar el carrito por la app:** no hay icono ni pantalla en ningún sitio.
  3. **Comprar un evento de pago:** funciona igual que antes, desde la ficha del evento.
  4. **Un evento gratuito:** se inscribe igual.
  5. **Comprar un libro o un programa:** abre la tienda de LSO.
  6. **Recorrer la app entera buscando pantallas en blanco:** ninguna ruta quedó apuntando al carrito.

### [2026-08-19]: Los libros de LSO también llevan a su página; nada alimenta ya el carrito

- **Por qué:** los libros salen de la misma tienda de LSO que los programas —`category: "libros"` en la
  misma consulta—, se publican en dólares y se compran allí. Al carrito entraban como pesos y con 19%
  de IVA colombiano. Decisión del cliente del 2026-08-19: **de LSO solo se enlaza**.
- **Alcance:**
  - `data/services/graphql_service.dart` — la consulta de libros pide `link`.
  - `domain/models/book_model.dart` — `url`.
  - `domain/utils/abrir_en_lso.dart` — **nuevo**: abrir la página y el mensaje de cuando no se puede.
  - `presentation/screens/books/books_screen.dart` y `books/book_detail_screen.dart` — compran fuera.
  - `test/models/libro_va_a_lso_test.dart` — nuevo, 5 pruebas.
- **Un solo sitio para abrir la tienda.** Programas y libros compartían la misma lógica escrita dos
  veces; ahora es `abrirEnLso`, con su mensaje. Si mañana cambia el criterio —abrir dentro con un
  WebView, por ejemplo— se cambia una vez.
- **Los botones dicen a dónde llevan:** «Comprar en LSO» en la ficha, y en el listado el icono pasa de
  carrito a **salir de la app**. Un carrito prometía una compra que ocurre en otro sitio.
- **Lo agotado sigue agotado:** un libro sin existencias no deja pulsar, igual que antes.
- **Comprobado contra la tienda:** los **5 libros** publicados traen enlace, igual que los 14 programas.
- **Consecuencia, y hay que decidirla:** **ya no queda nada que meta algo en el carrito.** Los eventos
  de pago —lo único que debería llevar allí— **no lo usan**: tienen su propia pantalla
  (`event_payment_screen.dart`, con `POST /api/payments/intent`). Así que hoy el carrito está vivo pero
  vacío para siempre, y la pantalla de Eventos conserva un botón flotante que lo abre. Las dos salidas:
  llevar los eventos de pago por el carrito, o retirar carrito, checkout y confirmación y con ellos ese
  botón. No se toca ninguna sin decidirlo: la pasarela está bloqueada desde el 6 de agosto.
- **Verificado:** `flutter analyze` sin errores ni avisos y **190 pruebas** en verde (185 antes).
- **Criterios de QA:**
  1. **Abrir la Biblioteca y tocar el icono de un libro:** abre el navegador en su página de LSO.
  2. **Abrir la ficha de un libro y tocar «Comprar en LSO»:** lo mismo.
  3. **Un libro agotado:** el botón sigue sin poder pulsarse.
  4. **Volver a la app:** sigue donde estaba.
  5. **Abrir el carrito desde Eventos:** está vacío — conocido y pendiente de decidir.
  6. **Comprar un evento de pago:** sigue por su propia pantalla, sin pasar por el carrito.

### [2026-08-19]: Los programas de LSO llevan a su página, no al carrito

- **Por qué:** los programas son de LSO, se publican en dólares y tienen su propio proceso de
  inscripción. Meterlos al carrito de la app los sumaba **como si fueran pesos** y les aplicaba 19% de
  IVA colombiano. Decisión del cliente del 2026-08-19: la inscripción se hace en la tienda.
- **Alcance:**
  - `data/services/graphql_service.dart` — la consulta pide `link`.
  - `domain/models/program_model.dart` — `url`.
  - `presentation/screens/programs/program_detail_screen.dart` — «Inscribirme en LSO» abre esa página;
    se retira `_addToCart` y con él las dependencias del carrito.
  - `test/models/program_model_test.dart` — 2 pruebas más.
  - `test/screens/programa_va_a_lso_test.dart` — nuevo, 2 pruebas.
- **El botón dice a dónde lleva.** «Inscribirme» a secas, abriendo el navegador, parece que la app se
  fue sola; «Inscribirme en LSO» avisa antes de tocarlo.
- **Se abre fuera de la app** (`LaunchMode.externalApplication`): la inscripción pide cuenta en LSO y
  medios de pago que la app no tiene, así que conviene la sesión del navegador de verdad.
- **Si no se puede abrir, se dice.** Un toque sin respuesta parece que la app se colgó. El aviso
  nombra el sitio —lso.school— para poder buscarlo a mano. Comprobado contra la tienda: **los catorce
  programas publicados traen enlace**, así que el caso es raro, no imposible.
- **La ficha sigue igual:** imagen, precio en dólares, modalidad y duración se siguen mostrando en la
  app. Lo único que se va fuera es el acto de inscribirse.
- **Queda una pregunta abierta:** los **libros** salen de la misma tienda de LSO —`category: "libros"`
  en la misma consulta—, se pagan igual en dólares y **siguen yendo al carrito**, con el mismo problema
  de moneda y de IVA. Si también deben ir a su página, el carrito se queda sin nada que llevar y el
  flujo de pago de la app se puede retirar entero.
- **Verificado:** `flutter analyze` sin errores y **185 pruebas** en verde (181 antes).
- **Criterios de QA:**
  1. **Abrir un programa y tocar «Inscribirme en LSO»:** abre el navegador en la página de ese programa.
  2. **Comprobar que es el programa correcto**, no el listado.
  3. **Volver a la app:** sigue en la ficha, no se perdió.
  4. **El carrito no cambia** al hacerlo: sigue como estaba.
  5. **Un programa sin enlace** (hoy no hay ninguno): sale el aviso, no un toque mudo.
  6. **Los libros siguen yendo al carrito**, que es lo conocido y pendiente de decidir.

### [2026-08-19]: Las flechas de atrás vuelven a donde estabas

- **El problema:** la flecha del encabezado hace `pop()` si hay algo que desapilar, y si no cae a una
  ruta fija. A ocho pantallas de detalle se entraba con `context.go`, que **sustituye la pila entera**,
  así que nunca había nada que desapilar: la flecha no volvía, saltaba a otro sitio. Y ese sitio era
  `/home?tab=2` —**Comunidad**— vinieras de donde vinieras. Desde Comunidad, además, no pasaba nada
  visible al tocarla.
- **Se cambian ocho `go` por `push`**, que son los que llevan a una pantalla con flecha:
  asesoría (desde el home y desde Comunidad), programas (desde el home, desde un artículo), el
  asistente (desde el home y desde Legacy Knowledge), el detalle de un programa y «VER CARRITO».
- **No se tocan los que deben seguir siendo `go`:** las tres pestañas del menú inferior
  —Legacy Knowledge, Legacy+ y Perfil—, donde `go` es lo correcto porque sustituyen, y el botón de
  «ver mi credencial» tras un pago, que usa `go` a propósito para que atrás no devuelva a la pasarela.
- **El respaldo pasa de Comunidad a Inicio.** Solo salta cuando de verdad no se puede volver: al abrir
  una notificación o un enlace de fuera. Inicio es el sitio predecible; Comunidad era arbitrario.
- **Cómo reconocer una recaída:** si al tocar atrás acabas en el Inicio en vez de en la pantalla
  anterior, es que a esa pantalla se llegó con `go` en vez de `push`.
- **Alcance:** `widgets/custom_section_header.dart`, y los ocho puntos de navegación en
  `home/home_content_screen.dart`, `comunidad/comunidad_screen.dart`,
  `informandote/article_detail_screen.dart`, `informandote/informandote_screen.dart`,
  `programs/programs_screen.dart` y `programs/program_detail_screen.dart`.
  Nuevo: `test/widgets/flecha_atras_test.dart`, 2 pruebas.
- **Verificado:** `flutter analyze` sin errores y **181 pruebas** en verde.
- ✅ **Recorrido en el dispositivo el 2026-08-20: los siete criterios, en verde.** Se comprobó sobre el
  APK instalado contra producción; las flechas vuelven a la pantalla de origen desde las ocho rutas
  corregidas, y la vuelta desde una notificación cae en el Inicio, que ahí es lo correcto.
- **Criterios de QA:**
  1. **Inicio → el asistente → atrás:** vuelve al Inicio, no a Comunidad.
  2. **Legacy Knowledge → el asistente → atrás:** vuelve a Legacy Knowledge.
  3. **Inicio → Programas → un programa → atrás → atrás:** detalle, lista, Inicio.
  4. **Comunidad → Asesoría → atrás:** vuelve a Comunidad.
  5. **Un artículo → Programas → atrás:** vuelve al artículo.
  6. **Abrir la app desde una notificación** y tocar atrás: va al Inicio sin quedarse colgada.
  7. **Tras pagar, «ver mi credencial» → atrás:** no vuelve a la pasarela.

---

### [2026-08-19]: El carrito guarda un solo elemento, y ya no viene con la compra hecha

- **Dos cosas, y la primera no la pidió nadie:** `CartProvider` **arrancaba con tres artículos de
  prueba dentro** —«Programa: Gestión Patrimonial», «Asesoría Legal» y «SUMMIT Legacy 2025»—, con el
  comentario «Mock Data for initial design review». Cualquiera que abriera el carrito se encontraba una
  compra de 798 que no había pedido. Está así en producción.
- **Se compra de uno en uno**, por decisión del cliente del 2026-08-19. El carrito admite un elemento:
  añadir otro sustituye al que hubiera.
- **La sustitución se avisa, no se hace en silencio.** `addItem` devuelve lo que había antes y las tres
  pantallas que añaden —libro, detalle de libro y detalle de programa— lo dicen: «Se cambió X por Y:
  solo se puede comprar un elemento a la vez». Cambiar el carrito sin decirlo dejaría a alguien pagando
  algo distinto de lo que eligió, y enterándose en la pantalla de pago.
- **Volver a añadir lo mismo no cuenta como sustitución**, para no soltar un «se cambió X por X».
- **La pantalla del carrito no necesitó cambios:** ya tenía estado vacío y ya deshabilitaba el pago con
  el carrito vacío.
- **Sigue pendiente y no se toca:** el carrito suma en pesos lo que LSO publica en dólares y le aplica
  19% de IVA. El flujo de pago está fuera del plan por decisión del 18-08.
- **Alcance:**
  - `domain/providers/cart_provider.dart` — sin datos falsos, un elemento, `addItem` devuelve el anterior.
  - `presentation/screens/books/books_screen.dart`, `books/book_detail_screen.dart`,
    `programs/program_detail_screen.dart` — el aviso.
  - `test/providers/carrito_un_elemento_test.dart` — nuevo, 9 pruebas.
- **Verificado:** `flutter analyze` sin errores y **181 pruebas** en verde.
- **Criterios de QA:**
  1. **Abrir el carrito recién instalada la app:** está vacío, y el botón de pagar no se puede pulsar.
  2. **Añadir un programa:** queda uno.
  3. **Añadir después un libro:** el carrito tiene solo el libro, y el aviso dice qué se cambió.
  4. **Añadir dos veces el mismo:** sigue habiendo uno y el mensaje es el normal, sin «se cambió».
  5. **Mirar el total:** corresponde solo a lo que está dentro.
  6. **Quitar el elemento:** el carrito vuelve a estar vacío.

### [2026-08-19]: Los precios de los programas de LSO se muestran en dólares

- **Por qué:** LSO publica en dólares y su tienda devuelve solo la cifra —«$300», «$1.100», «$2.500»—
  sin decir de qué moneda. En la app esas tarjetas conviven con eventos en pesos colombianos, así que
  un «$300» suelto se lee como trescientos pesos. Salió al ejecutar F22.6 del plan de pruebas contra el
  GraphQL real, y lo confirmó el cliente el mismo día.
- **Alcance:**
  - `domain/models/program_model.dart` — `precioConMoneda`.
  - `presentation/screens/programs/programs_screen.dart` — la tarjeta lo usa.
  - `test/models/program_model_test.dart` — nuevo, 5 pruebas.
- **La moneda va delante** —«USD $300»— y no detrás: la tarjeta es estrecha y si recorta el final,
  «USD $30…» sigue diciendo que son dólares mientras que «$300 US…» puede quedarse en «$300».
- **Vive en el modelo y no en la pantalla** porque el precio ya se usa en dos sitios y mañana puede
  usarse en un tercero; así las tres superficies dicen lo mismo sin acordarse de nada.
- **Los programas sin precio siguen mostrando «Cotización».** La moneda no se antepone donde no hay
  cifra: hoy hay tres así de los catorce publicados, comprobado contra la tienda.
- **Lo que esto deja al descubierto y NO se toca:** al añadir un programa al carrito se guarda solo el
  número (`priceValue`), y el carrito lo pinta con `CurrencyFormatter` —formato colombiano—, le aplica
  19% de IVA y lo suma con eventos en pesos. **El flujo de pago está fuera del plan** por decisión del
  18-08; arreglarlo de verdad es meter moneda en el carrito, no cambiar un formato.
- **Verificado:** `flutter analyze` sin errores ni avisos nuevos y **170 pruebas** en verde (165 antes).
- **Criterios de QA:**
  1. **Abrir Escuela/Programas:** cada programa con precio dice «USD $…».
  2. **Un programa sin precio** (hoy «Propietarios y Familias Empresarias»): sigue diciendo
     «Cotización», sin moneda delante.
  3. **Comparar con lso.school:** la cifra coincide con la de la tienda.
  4. **Mirar la tarjeta en un teléfono estrecho:** la moneda se ve aunque el precio quede justo.
  5. **Añadir un programa al carrito:** conocido y pendiente — el carrito lo trata como pesos y le suma
     IVA. No reportar como nuevo.

### [2026-08-19]: La tarjeta del listado deja de anunciar como gratis lo que cuesta

Salió al ejecutar F12.20 del plan de pruebas.

- **El problema:** la tarjeta de la lista de eventos decidía qué precio enseñar **por el nombre de la
  categoría**: `isSummit ? 'Preventa hasta 30 jul' : 'Gratis'` y `isSummit ? 'ABIERTO' : 'GRATIS'`.
  Cualquier evento cuya categoría no fuera literalmente `summit` —una masterclass de pago, por ejemplo—
  salía rotulado **«Gratis»** y con la insignia **«GRATIS»** encima, costara lo que costara.
- **El dato correcto estaba a mano y se ignoraba.** `EventModel` trae `price`, `isFree` y un
  `priceLabel` ya compuesto con `CurrencyFormatter`, y `eventos_screen.dart` no mencionaba ninguno de
  los tres en todo el archivo.
- **Por qué existía:** cuando se escribió la tarjeta, el summit era el único evento de pago del
  catálogo, así que la categoría y el precio coincidían. Dejaron de coincidir en cuanto se creó el
  primero que no era un summit.
- **Se corrige leyendo el evento:** `esDePago = !event.isFree`. La nota bajo la fecha muestra
  `event.priceLabel` —«$ 150.000»— o «Gratis», y la insignia pasa a **PREVENTA** o **GRATIS**.
- **«PREVENTA» es la palabra que ya usa el detalle** del evento («PREVENTA ABIERTA»), para que quien
  abra la ficha lea lo mismo que vio en la lista.
- **Se retira una fecha escrita a mano.** «Preventa hasta 30 jul» seguía saliendo el 19 de agosto.
- **El summit se sigue viendo igual** —verde y con su insignia—, que era lo que no había que romper,
  pero ahora porque cuesta y no porque se llame así.
- **De paso desaparece un acoplamiento con el panel:** la tarjeta ya no depende de cómo se llame la
  categoría, así que renombrarla desde el panel no cambia lo que dice el precio. Queda pendiente el
  mismo patrón en `isLSO`, que sigue mirando la categoría y el título.
- **Alcance:**
  - `presentation/screens/eventos/eventos_screen.dart` — `_buildCompactEventCard`.
  - `test/screens/precio_evento_listado_test.dart` — nuevo, 4 pruebas.
- **Verificado:** `flutter analyze` sin errores ni avisos (los 48 `info` son anteriores y de otros
  archivos) y **165 pruebas** en verde (161 antes; 4 nuevas).
- **Criterios de QA:**
  1. **Crear un evento de pago que no sea summit** desde el panel y abrir la lista: muestra su precio,
     no «Gratis», y la insignia dice PREVENTA.
  2. **Un evento gratuito:** sigue diciendo «Gratis» y GRATIS.
  3. **El Legacy Summit:** se ve como siempre.
  4. **Buscar la nota «Preventa hasta 30 jul»:** ya no aparece en ninguna tarjeta.
  5. **Abrir un evento de pago desde la lista:** el detalle dice «PREVENTA ABIERTA», la misma palabra.
  6. **Un evento ya finalizado:** no muestra precio, solo la insignia FINALIZADO.

### [2026-08-18]: Se sanea el HTML al mostrarlo

- **Alcance:**
  - `domain/utils/sanitizar_html.dart` — nuevo. Sin dependencias de Flutter, como `busqueda_global`.
  - `test/utils/sanitizar_html_test.dart` — nuevo. 16 pruebas.
  - Los cuatro sitios que pintan HTML: `informandote/article_detail_screen.dart`,
    `informandote/video_detail_screen.dart`, `books/book_detail_screen.dart` y `chat/chatbot_screen.dart`.
- **Al mostrar y no al guardar, por decisión.** Sanear al escribir no arregla lo ya almacenado ni lo
  que llega de fuera, y deja el contenido mutilado en la base. Al mostrar se aplica siempre.
- **Antes de tocar nada se buscó dónde se interpreta HTML de verdad**, que resultó ser menos de lo que
  sugería el aviso general de "no hay sanitización":
  - **El panel no inyecta HTML en ningún sitio.** Cero usos de `innerHTML` o `bypassSecurityTrust`:
    Angular escapa por defecto en la interpolación.
  - **Foros, sinergias y chat se pintan con `Text`**, que no interpreta etiquetas. El `<script>` que
    el backend guarda tal cual —comprobado el mismo día— es **inerte** ahí.
  - Quedan **cuatro** `HtmlWidget`: artículo, video, libro y asistente.
- **En Flutter esto no es una defensa contra JavaScript:** no hay motor que lo ejecute, así que un
  `<script>` ya era inofensivo. Lo que sí evita es que un `<img src="http://…">` ajeno dispare una
  petición al pintar —delatando la IP de quien lee—, que un `<iframe>` cargue algo de fuera y que un
  enlace `javascript:` quede a un toque. Y deja el terreno hecho para cualquier superficie futura que
  sí interprete HTML.
- **El del asistente pinta también lo que escribe la propia persona**, así que sin sanear se puede
  inyectar HTML en su propia conversación.
- **El del video importa más desde hoy:** las descripciones vienen de YouTube, contenido de fuera
  aunque el canal sea nuestro.
- **Se quitan las etiquetas con su contenido y no solo la etiqueta.** Quitar solo `<style>` dejaría su
  cuerpo suelto como párrafo visible; hay una prueba de eso.
- **Se conserva el formato legible** —párrafos, negritas, listas, enlaces e imágenes normales—: la
  idea es que el contenido siga viéndose bien, no dejarlo en texto pelado.
- **Es idempotente**, cubierto por prueba: sanear dos veces da lo mismo, así que aplicarlo por
  duplicado en el futuro no rompe nada.
- **Verificado:** `flutter analyze` **sin errores** y **161 tests** (145 antes; 16 del saneador).
- **Criterios de QA:**
  1. **Abrir un artículo largo con formato:** se ve igual que antes —negritas, listas, enlaces—.
  2. **Abrir un video de YouTube:** su descripción se lee bien, con los saltos de línea.
  3. **Abrir el detalle de un libro:** su descripción se ve completa.
  4. **En el asistente, escribir `<b>hola</b>`:** no aparece en negrita ni desaparece el texto.
  5. **En el asistente, escribir `<script>alert(1)</script>`:** no pasa nada raro y el resto del
     mensaje se sigue leyendo.
  6. **Un contenido con imagen** sigue mostrándola.

### [2026-08-18]: Se retiran los restos del Participando anterior

Al reescribir Participando contra el proveedor quedaron tres archivos que ya no usaba nadie. Se
anotaron ese día como pendientes y se borran ahora.

- **Alcance:**
  - `presentation/screens/participando/event_detail_screen.dart` — borrado.
  - `domain/models/events_data.dart` — borrado (`EventsData` y `EventItem`).
  - `assets/data/events_data.json` — borrado.
  - `main.dart` — el comentario que advertía de no confundir las dos pantallas de detalle.
- **Se comprobó la cadena entera antes de borrar**, no archivo a archivo: `EventDetailScreen` no lo
  instanciaba nadie, `events_data.dart` solo lo importaba esa pantalla, y el JSON solo lo leía
  Participando, que ya no lo hace. Las únicas menciones restantes eran comentarios.
- **La entrada `assets/data/` del `pubspec.yaml` se queda:** en esa carpeta hay otros cuatro JSON.
- **El comentario de `main.dart` se reescribió en vez de borrarlo.** Advertía de no confundir la ruta
  `/evento` con la otra pantalla de detalle; ahora explica que esa otra ya no existe, que es la duda
  que le surgirá a quien vea el nombre en un commit viejo.
- **Se retiran además otros dos JSON de assets sin referencias**, encontrados al comprobar esto:
  `informandote_data.json` (11 KB) y `user_profile.json`. Viajaban dentro del APK sin que nadie los
  leyera. En `assets/data/` quedan los dos que sí se usan: `board_contacts.json`, que carga la pantalla
  de Comunidad, y `favorites_data.json`, que lee el proveedor de favoritos.
- ⚠️ **Un asset borrado no lo detectan ni el análisis ni los tests**, porque se carga por su ruta en
  tiempo de ejecución y falla ahí. Por eso se comprobó a mano: se buscó cada nombre en todo el
  proyecto y se revisó **cada llamada a `rootBundle.loadString`** una por una, que son cuatro.
- **Verificado:** `flutter analyze` **sin ningún error** y con los mismos 48 avisos previos, y **145
  tests**. Borrar un archivo que alguien importara habría salido como error de compilación.
- **Criterios de QA:**
  1. **La app compila e instala** sin fallos.
  2. **Participando abre** y muestra las inscripciones reales, igual que antes.
  3. **La pestaña Eventos y el detalle de un evento** siguen funcionando: son otra pantalla.
  4. **Tocar una notificación de evento** abre su detalle.
  5. **Comunidad carga sus contactos de junta**, que salen de `board_contacts.json`.
  6. **Favoritos abre** y muestra lo guardado: usa `favorites_data.json`.
  7. **Legacy Knowledge y el perfil** cargan con normalidad — eran los que usaban los dos JSON
     retirados **antes** de pasar a la API.

### [2026-08-18]: La sección de contenido se llama Legacy Knowledge en toda la app

Punto 1.2, el que faltaba de la tanda 1. **Decisión del cliente:** se queda «Legacy Knowledge» y
desaparece «Contenido de valor».

- **Alcance:**
  - `presentation/screens/home/home_content_screen.dart` — título de la tarjeta.
  - `presentation/widgets/custom_section_header.dart` — entrada del menú lateral.
- **Los otros dos sitios ya decían Legacy Knowledge** —el encabezado de la sección y Legacy Plus—, y
  el buscador que se añadió hoy dice «Buscar en Legacy Knowledge». Con estos dos, los cinco coinciden.
- **No se toca `register_screen.dart:188`**, que dice «para dar contenido de valor». Ahí es prosa
  —contenido que aporta valor—, no el nombre de la sección; cambiarlo la dejaría hablando raro.
- **Verificado:** `flutter analyze` sin issues.
- **Criterios de QA:**
  1. **Home:** la tarjeta dice «Legacy Knowledge».
  2. **Menú lateral:** la entrada dice «Legacy Knowledge».
  3. **Abrir la sección:** el encabezado dice lo mismo que la tarjeta desde la que se llegó.
  4. **El buscador** de la sección dice «Buscar en Legacy Knowledge».
  5. **Legacy Plus** sigue diciendo «Legacy Knowledge completo».
  6. **Recorrer la app** sin encontrar ya «Contenido de valor» como nombre de sección.

### [2026-08-18]: Los videos de YouTube entran en Contenido de Valor

Lado app del punto 1.4. El backend expone `GET /api/content/videos` con los canales de Legacy Network
y LSO; aquí se consumen como tercera fuente de la sección.

- **Alcance:**
  - `domain/models/video_canal_model.dart` — nuevo. Modelo y `toContentItem()`.
  - `data/services/video_canal_service.dart` — nuevo.
  - `data/config/api_constants.dart` — el endpoint.
  - `presentation/screens/informandote/informandote_screen.dart` — tercera fuente en el `Future.wait`.
- **La app no habla con YouTube.** Pide al backend, que ya trae los videos normalizados y cacheados.
  La clave de la API no puede viajar en el binario: los repositorios son públicos.
- **El canal es el autor.** `toContentItem()` pone el nombre del canal en `authorName`, así que estos
  videos ya no salen como «Autor desconocido» —es la mitad del punto 1.5 que dependía de este—.
- **La descripción se recorta a 160 caracteres para la tarjeta** y el texto completo queda en
  `fullContent` para el detalle: las de YouTube traen saltos de línea, emoji y enlaces sueltos que en
  una tarjeta se ven mal.
- **El servicio nunca lanza:** devuelve lista vacía ante cualquier fallo. La sección tiene otras dos
  fuentes y no puede quedarse en blanco porque YouTube esté caído.
- **Los videos van detrás del contenido propio y delante de los artículos de WordPress**, para que la
  sección no abra con material de terceros.
- **Verificado:** `flutter analyze` sin issues en los archivos nuevos y **145 tests**. Contra el
  backend local el endpoint devolvía 87 videos de los dos canales.
- **Criterios de QA:**
  1. **Abrir Contenido de Valor:** el listado trae videos, no solo artículos.
  2. **Filtro «Videos»:** salen decenas. **Antes había uno.**
  3. **Aparecen los dos canales**, Legacy Network y LSO.
  4. **Abrir un video:** reproduce y la firma es el nombre del canal, no «Autor desconocido».
  5. **Buscar una palabra del título de un video** lo encuentra.
  6. **Con el backend caído:** la sección sigue mostrando el contenido de WordPress.
  7. **Las miniaturas cargan**; ninguna tarjeta sale con el icono de imagen rota.

### [2026-08-18]: Participando muestra inscripciones reales, y los virtuales dan enlace

Puntos 2.5 y 2.3 de `reports/20260818_plan_ajustes.html`, lado app.

- **El problema:** Participando cargaba `assets/data/events_data.json` con `rootBundle` —eventos de
  ejemplo compilados dentro de la app— y **nunca consultó el backend**. No es que la inscripción a la
  masterclass fallara: esa pantalla no podía mostrar ninguna inscripción real, jamás.
- **Alcance:**
  - `presentation/screens/participando/participando_screen.dart` — reescrita contra `EventsProvider`.
  - `domain/models/registration_model.dart` — `eventIsVirtual`, `accessUrl` y `tieneEnlace`.
  - `presentation/screens/profile/mi_credencial_screen.dart` — enlace de sesión en vez de QR cuando el
    evento es virtual.
- **El servicio, el modelo y el proveedor ya existían y funcionaban.** `getMyRegistrations` estaba
  escrito y probado; solo lo usaba "Mi credencial". El trabajo estuvo en la pantalla.
- **El filtro Presencial/Virtual ahora filtra de verdad.** Antes comparaba contra un campo del JSON de
  ejemplo; ahora usa `eventIsVirtual`, que llega del backend desde la migración de hoy. Por eso 2.3 se
  hizo antes que 2.5: al revés habría tocado la pantalla dos veces.
- **Cuatro estados vacíos distintos**, porque significan cosas distintas y la anterior solo tenía uno
  ("Error loading data"): sin sesión, error de carga con reintento, sin ninguna inscripción, y ninguna
  que coincida con el filtro.
- **La tarjeta lleva a "Mi credencial", no al detalle del evento.** Es donde está el QR o el enlace,
  que es lo que busca quien entra aquí. El botón cambia de texto e icono según la modalidad.
- **Ni un evento terminado ni una inscripción sin pagar ofrecen acceso:** no hay nada a lo que entrar,
  y la inscripción impaga se marca con su etiqueta en la tarjeta.
- **Se añadió "deslizar para recargar"**, que la versión del JSON no necesitaba porque sus datos nunca
  cambiaban.
- ⚠️ **`participando/event_detail_screen.dart` queda huérfano.** Trabajaba con `EventItem`, del JSON
  estático, y ya no lo referencia nadie. No se borra en esta entrega; conviene decidirlo aparte junto
  con el propio `assets/data/events_data.json`.
- **Verificado:** `flutter analyze` sin issues en los archivos tocados y **145 tests** (sin cambios: no
  hay tests de widget de estas pantallas).
- **Criterios de QA:**
  1. **Sin sesión:** Participando invita a iniciar sesión, no muestra eventos de ejemplo.
  2. **Con sesión y sin inscripciones:** dice que todavía no te has inscrito a ninguno.
  3. **Inscribirse a un evento y abrir Participando:** aparece ahí. **Este es el caso que el cliente
     reportó.**
  4. **Deslizar hacia abajo** recarga la lista.
  5. **Filtro «Virtual»:** solo las masterclass; **«Presencial»:** solo los presenciales.
  6. **Buscar por título** filtra sobre tus inscripciones.
  7. **Un evento ya pasado** cae en "Eventos pasados" y no ofrece botón de acceso.
  8. **Una inscripción pendiente de pago** sale con su etiqueta y sin botón de acceso.
  9. **Tarjeta de un presencial:** el botón dice "Ver mi credencial" y lleva al QR.
  10. **Tarjeta de un virtual:** dice "Ver enlace de acceso" y lleva al enlace.
  11. **Mi credencial, evento virtual:** sale el botón "Entrar a la sesión", **no** un QR.
  12. **Mi credencial, evento presencial:** sale el QR, **no** un enlace.
  13. **Con un enlace mal escrito** desde el panel, tocar el botón avisa y no rompe la pantalla.
  14. **Sin backend:** Participando muestra el error con botón de reintentar.

### [2026-08-18]: Tanda 1 de los ajustes del cliente

Cinco de los seis puntos de la primera tanda de `reports/20260818_plan_ajustes.html`. **Falta 1.2**
—unificar «Contenido de Valor» y «Legacy Knowledge»—, que espera a que el cliente diga cuál se queda.

- **Alcance:**
  - `presentation/screens/home/home_content_screen.dart` — 2.1: subtítulo de la tarjeta de eventos y
    destacado semanal del perfil de empresa.
  - `presentation/screens/comunidad/comunidad_screen.dart` — 2.1: el tercer «webinars» suelto.
  - `data/services/graphql_service.dart` — 1.5: `author { node { name } }` en las dos consultas.
  - `domain/models/graphql_post_model.dart` — 1.5: campo `authorName`, lectura y paso a `ContentItem`.
  - `presentation/screens/programs/programs_screen.dart` — 3.1: la imagen del programa.
  - `presentation/screens/informandote/video_detail_screen.dart` — 1.3: el «me gusta».
  - `presentation/screens/informandote/informandote_screen.dart` — 1.1: el buscador.
  - `domain/utils/busqueda_global.dart` — 1.1: `coincide` y `palabrasDe`.
- **Tres de los cinco eran cableado, no funcionalidad nueva.** El autor ya se sabía leer en dos
  formatos pero la consulta nunca lo pedía; la imagen del programa llegaba hasta la app y se tiraba en
  el mapeo a `_LsoProgram`; y el «me gusta» del video estaba escrito y probado **en la pantalla de al
  lado**, la del artículo.
- **El «me gusta» del video no existía; «Guardar» sí funcionaba.** El cliente reportó los dos juntos.
  El me gusta se pintaba con `_buildStat`, que solo muestra el número y no responde al toque. Ahora usa
  el mismo camino que el artículo: consulta el estado al abrir, actualiza de forma optimista, revierte
  si la llamada falla y avisa si no hay sesión.
- **El video pasa a tener copia mutable del modelo** (`_video`), porque `widget.video` es inmutable y
  el contador cambia. Es el patrón que ya usaba `article_detail_screen`.
- **El buscador filtra en local y se acumula sobre el filtro de tipo:** con «Videos» activo y
  «gobierno» escrito salen solo los videos de gobierno. La pantalla ya descarga todo el contenido de
  golpe para poder filtrar por tipo, así que buscar no vuelve a la red.
- **La regla de coincidencia no se reimplementó.** Se extrajo `coincide` a `busqueda_global.dart`, que
  no depende de Flutter y ya tenía tests, y `filtrar` la usa también. Sin esto habría dos búsquedas con
  comportamientos que se separarían con el tiempo.
- **Una consulta vacía en `coincide` devuelve `true`, al revés que `filtrar`.** En `filtrar` una
  consulta vacía significa «no hay búsqueda, no devuelvas nada»; en el buscador de sección significa
  «no estás filtrando, deja pasar todo». Está cubierto por un test para que nadie lo «arregle».
- **El vacío del listado distingue los dos casos:** sin búsqueda dice que no hay contenido de ese tipo;
  con búsqueda, que nada coincide con lo escrito.
- **La imagen del programa lleva marcador de posición** del mismo alto cuando falta o falla la carga,
  para que el listado no quede irregular. No todos los programas tienen imagen en la tienda.
- **Verificado:** `flutter analyze` sin issues nuevos —los avisos que salen son `print` y un
  `BuildContext` asíncrono, todos anteriores— y **145 tests** (141 antes; 4 de `coincide`).
- **Criterios de QA:**
  1. **Home:** la tarjeta de eventos dice «Masterclass virtual en vivo y Legacy Summit presencial».
  2. **Home con perfil de empresa:** el destacado semanal ya no dice «webinar».
  3. **Comunidad:** el texto de la cinta ya no dice «webinars».
  4. **Abrir un artículo:** sale el nombre de quien firma, no «Autor desconocido».
  5. **Abrir un video:** ídem; si el contenido no trae autor, sigue saliendo el texto por defecto.
  6. **Video, tocar el pulgar:** se rellena y el contador sube; volver a tocarlo lo deshace.
  7. **Video sin sesión iniciada:** al tocar el pulgar avisa «Debes iniciar sesión para dar like».
  8. **Salir del video y volver a entrar:** el estado del me gusta se conserva.
  9. **Video, «Guardar»:** sigue funcionando y aparece en Favoritos.
  10. **LSO:** cada tarjeta muestra su fotografía.
  11. **LSO, programa sin imagen:** sale el emblema sobre fondo azul, no un hueco ni un icono roto.
  12. **Legacy Knowledge:** hay buscador bajo el encabezado.
  13. **Buscar «sesion» sin tilde** encuentra los títulos con «Sesión».
  14. **Buscar «summit liderazgo»** encuentra el título aunque las palabras no estén juntas.
  15. **Elegir «Videos» y escribir una palabra:** se acumulan los dos filtros.
  16. **Buscar algo inexistente:** dice «Nada coincide con "…"», no el mensaje de tipo.
  17. **La equis del buscador** limpia el texto y devuelve el listado completo.

### [2026-08-18]: La barra inferior del registro deja de tapar el formulario

En las capturas de iPhone de hoy (`docs/ios/error2_18-08-2026.jpeg`) la barra fija del registro
ocupaba un tercio de la pantalla: solo se veía el campo de contraseña. La causa es que "Acepto
Política de Privacidad y Habeas Data" competía por el ancho con el botón "Atrás" y con el de acción,
que tiene ancho fijo (`minimumSize: Size(120, 44)` más 20 de padding). En un iPhone estrecho al texto
le quedaban unos 55 px y se partía en siete líneas, y la barra crecía con él.

- **Alcance:**
  - `presentation/screens/register_screen.dart` — el `bottomNavigationBar` pasa de una `Row` a una
    `Column`: la casilla ocupa su propia fila y debajo van "Atrás" y el botón de acción.
  - Mismo archivo — colchones al final de los dos pasos del `Stepper`: 20 → 96 en *Persona* y
    80 → 120 en *Empresa*.
- **La casilla en su propia fila** es lo que baja la barra de siete líneas a dos. Darle más espacio
  sin sacarla de la fila solo habría añadido blanco a un contenedor que ya tapaba el formulario.
- **El colchón del paso *Persona* estaba mal desde antes:** con 20 px la fecha de nacimiento, que es
  el último campo, quedaba debajo de la barra. Nadie lo había reportado porque el campo se llena con
  el selector de fecha y no hace falta verlo para tocarlo.
- **Los dos colchones no son iguales a propósito:** la barra del paso *Empresa* lleva la casilla y es
  más alta que la del paso *Persona*.
- **El contenedor sigue en blanco sobre el tema oscuro**, que es como se ve en la captura. No se toca
  en esta entrega; queda como decisión de diseño pendiente.
- ⚠️ **El registro sigue fallando si se entra por la tercera opción del onboarding** ("Quiero ser
  miembro de junta o consejo"): manda `role=junta` y el enum `core.user_role` no lo tiene, así que
  Postgres responde `SQLSTATE 22P02` (`docs/ios/error_18-08-2026.jpeg`). Es un fallo aparte, del
  backend, y no se corrige aquí.
- **Verificado:** `flutter analyze lib/presentation/screens/register_screen.dart` sin issues. El
  cambio es de layout y no hay tests de widget de esta pantalla.
- **Criterios de QA:**
  1. **En un iPhone estrecho** (SE o similar), paso *Empresa*: la casilla del habeas data se lee en
     una sola línea, o dos como mucho, encima de "Atrás" y "Crear Cuenta". La barra no pasa de dos
     filas.
  2. **Tocar el texto** de la casilla, no solo el cuadro, la marca y la desmarca.
  3. **Paso *Persona*, bajar hasta el final:** la fecha de nacimiento queda por encima de la barra y
     se puede tocar sin que la tape.
  4. **Paso *Empresa*, bajar hasta el final:** los enlaces legales quedan separados del contenedor
     blanco, no pegados a él.
  5. **Con el teclado abierto** en cualquier campo la barra sube con él y sigue completa.
  6. **Paso *Persona*:** no aparece "Atrás" ni la casilla; el botón dice "Siguiente" y queda a la
     derecha.

### [2026-08-14]: La notificación de un mensaje abre su conversación

El lado app del aviso de chat que estrena el backend hoy. La push llega con `{type: "chat", id: la
conexión, title: quién escribe}` y antes de este cambio ese tipo era desconocido para la app: tocarla
llevaba a la bandeja de notificaciones, como cualquier novedad que no supiera resolver.

- **Alcance:**
  - `domain/utils/notificacion_destino.dart` — caso `chat`: lleva a
    `/individual-chat/<id>?title=<nombre>`.
  - `main.dart` — el aviso en primer plano y el manejo del toque distinguen el chat.
- **El chat es el único destino que no necesita red.** Los de evento y contenido resuelven la entidad
  antes de navegar porque esas pantallas la reciben por `extra`; la del chat solo necesita el id y
  carga el historial al abrirse. Por eso funciona con la app recién arrancada y sin conexión todavía.
- **El nombre viaja en la notificación** porque `/individual-chat/:id` espera el encabezado como
  parámetro; resolverlo en la app obligaría a pedir la lista entera de conversaciones para saber un
  nombre. Si llegara vacío, el encabezado dice "Chat" y la conversación se abre igual.
- **Un mensaje de chat no entra en la bandeja de novedades:** su sitio es la conversación, y anotarlo
  ahí lo dejaría contado dos veces, una en la bandeja y otra en el contador de no leídos.
- **Con la conversación abierta delante no salta ningún aviso:** el mensaje ya se está pintando por
  el WebSocket. En cualquier otra pantalla sí aparece, y ahora con un botón **Ver** que lleva a la
  conversación —sin él, el aviso obligaba a buscarla a mano—.
- ⚠️ **Nada de esto se puede probar en el emulador con push reales**: hace falta un teléfono con la
  app instalada y el backend nuevo desplegado. Los tests cubren la traducción de la notificación a
  ruta, que es donde estaba el fallo.
- **Verificado:** `flutter analyze` sin avisos nuevos y **141 tests** (139 antes; 2 del destino de
  chat).
- **Criterios de QA:**
  1. **App cerrada del todo:** recibir un mensaje, tocar la notificación. Abre esa conversación con
     el nombre de quien escribió en el encabezado.
  2. **App en segundo plano:** lo mismo, sin pasar por la bandeja.
  3. **En otra pantalla de la app:** aparece el aviso abajo con **Ver**; al pulsarlo, la conversación.
  4. **En esa misma conversación:** el mensaje entra solo en la lista y **no** aparece ningún aviso.
  5. **La bandeja de notificaciones** (`/notifications`) no acumula los mensajes de chat; los avisos
     de eventos y contenido siguen apareciendo ahí como antes.

### [2026-08-13]: La búsqueda global ya es global, y hay FAQ

Las dos piezas que le faltaban a la Fase 1 para cumplir el documento de alcance.

**Búsqueda global.** Antes la lupa solo miraba el contenido —artículos, videos, podcast—, así que
buscar un evento o a una persona no devolvía nada. Ahora alcanza **cinco fuentes**: contenido,
eventos, programas, sinergias y miembros, con los resultados agrupados por sección.

- **Alcance:**
  - `domain/models/resultado_busqueda.dart` — nuevo. Modelo común; guarda el objeto original porque
    cada pantalla de detalle lo recibe como `extra` de go_router.
  - `domain/utils/busqueda_global.dart` — nuevo. `normalizar`, `filtrar` y `agrupar`, sin depender de
    Flutter, igual que `event_filters.dart`. Es el único archivo a tocar si algún día el backend
    acepta búsquedas de verdad.
  - `data/services/busqueda_service.dart` — nuevo. Reúne las cinco fuentes.
  - `presentation/delegates/global_search_delegate.dart` — nuevo; sustituye a
    `content_search_delegate.dart`, que se retira.
- **Busca sin tildes:** "sesion" encuentra "Sesión de bienvenida". En un teclado móvil nadie escribe
  las tildes, así que sin esto la mitad de las búsquedas fallarían.
- **Por palabras sueltas, no por frase:** "summit liderazgo" encuentra "LEGACY SUMMIT 2026: Liderazgo
  y Trascendencia". Comparar la frase entera fallaba en el caso más común.
- **Si una fuente falla, las demás siguen.** Dos de las cinco son GraphQL de terceros (WordPress y
  lso.school). Antes un fallo de WordPress dejaba la lupa vacía con un error rojo; ahora cada fuente
  se pide por separado y la que falle aporta cero resultados.
- ⚠️ **Los miembros llevan al directorio, no a un perfil**: no existe pantalla de perfil de otra
  persona en la app.

**FAQ.** Cuatro secciones —cuenta y acceso, comunidad y foros, eventos, privacidad y
notificaciones— con 17 preguntas, buscador propio y enlace a Contáctenos cuando no hay respuesta.

- **Alcance:** `domain/models/faq_data.dart` y `presentation/screens/faq/faq_screen.dart`, nuevos;
  ruta `/faq`; accesos desde el menú de Perfil y desde la propia pantalla de Contáctenos.
- **Las respuestas describen lo que la app hace hoy**, no lo que se espera de ella: el chat es 1:1,
  los foros van con alias, el acceso con Apple solo aparece en iPhone. **Al cambiar una función hay
  que revisar esta lista**: una FAQ que promete algo que ya no ocurre hace más daño que no tenerla.
- **Al buscar, las coincidencias salen desplegadas.** Si hubiera que tocar cada una para ver si es la
  buena, el buscador no ahorraría nada.
- ⚠️ **Ninguna respuesta habla de precios, reembolsos ni plazos**, porque eso es política comercial y
  no está definida. Si el negocio la fija, es lo primero que habría que añadir.
- **Verificado:** `flutter analyze` limpio y **139 tests** (120 antes; 11 de la búsqueda y 8 del FAQ).
- **Criterios de QA:**
  1. **Lupa del Home**, buscar "legacy": salen resultados en varias secciones, no solo Contenido.
  2. Buscar **sin tildes** ("sesion", "cancun"): encuentra igual.
  3. Buscar **dos palabras en desorden** ("liderazgo summit"): encuentra el evento.
  4. Tocar un resultado de cada sección: abre la pantalla correcta y se puede volver.
  5. **Sin conexión**, abrir la lupa: no revienta; muestra lo que haya podido cargar.
  6. **Perfil → Preguntas frecuentes**: las cuatro secciones, y tocar una pregunta muestra su
     respuesta.
  7. En el FAQ, buscar "contrasena" sin tilde: aparece la pregunta ya desplegada.
  8. Buscar algo inexistente: ofrece el botón de Contáctenos y lleva a esa pantalla.

### [2026-08-13]: Pantalla Contáctenos, y build ad-hoc para el tercer dispositivo

- **Contáctenos** era la única pantalla del módulo de Autenticación del documento de alcance sin
  implementar. Tiene formulario —que deja constancia en el buzón de soporte y no obliga a salir de la
  app— y canales directos, que son los que sirven cuando el envío falla.
- **Alcance:**
  - `presentation/screens/contacto/contacto_screen.dart` — nueva.
  - `data/services/contacto_service.dart` — nuevo. Cliente HTTP inyectable, como `EventService`.
  - `main.dart` — ruta `/contacto`, **dentro del `ShellRoute`**: el mensaje lo firma el backend con
    el perfil autenticado, así que sin sesión no hay remitente.
  - Accesos en `profile_screen.dart` (menú) y `home_content_screen.dart` (tarjeta).
- **Al fallar el envío no se borra lo escrito** y se ofrece "Escribir por correo", que abre el
  cliente de correo con el asunto y el mensaje ya puestos. Reescribirlo entero sería la peor forma de
  enterarse de que no salió.
- **El servicio no hace `json.decode` a ciegas:** el backend responde texto plano en los 400 y JSON
  en el resto; decodificar siempre convertiría un motivo explicable en un `FormatException`.
- ⚠️ **No se puso teléfono ni WhatsApp**: no hay un número real en ninguna parte del proyecto. El que
  existe en `program_detail_screen.dart:17` es `wa.me/573000000000`, un relleno que **ya está en
  producción** y lleva a un número inventado. Hace falta el número bueno para las dos cosas.
- **Verificado:** `flutter analyze` limpio en los archivos tocados y **120 tests** en verde (117
  previos + 3 nuevos de `contacto_service_test.dart`: cabecera y cuerpo del envío, el 400 de texto
  plano y el 500 sin cuerpo).
- **Build ad-hoc `1.0.0+16`** para el tercer dispositivo de pruebas registrado hoy. El perfil nuevo
  se validó antes de compilar: certificado idéntico al `dist_cert.pem` que tenemos (`b4e2bfe7…`),
  `get-task-allow: false` y 3 dispositivos; y después se comprobó el `embedded.mobileprovision`
  **dentro del `.ipa`**, que es lo único que demuestra que se usó el perfil nuevo y no el del secreto
  anterior. Artefacto `legacy-ios-adhoc-19`, copia en `docs/ios/build/`.
- **Criterios de QA:**
  1. **Perfil → Contáctenos** y **Home → tarjeta Contáctenos**: ambas abren la pantalla.
  2. Enviar un mensaje: aparece la confirmación y llega a `soporte@legacynetworkco.com`.
  3. **Enviar con el mensaje vacío**: avisa sin llamar al servidor.
  4. **En modo avión**: muestra el error, **conserva el texto** y el botón "Escribir por correo" abre
     el cliente de correo con todo relleno.
  5. **"Escribir otro mensaje"** tras enviar deja el formulario limpio.
  6. La app instalada en el **dispositivo nuevo** abre y permite iniciar sesión.

### [2026-08-12]: La app de iOS estaba registrada en Firebase con el bundle de ejemplo

- **El problema:** Firebase tenía la app de Apple como `com.example.legacyApp` —el identificador que
  trae Flutter al crear un proyecto— mientras la app se compila como `co.legacynetwork.legacyapp`.
  Y lo que de verdad manda es `lib/firebase_options.dart`, porque `main.dart` inicializa con
  `DefaultFirebaseOptions.currentPlatform` y no con el `.plist`: **las notificaciones de iOS se
  registraban contra una app que no era la instalada**. En Android nunca falló, que es donde se
  probaban.
- **Un segundo fallo, encontrado al verificar lo anterior:** el inicio de sesión con Google llamaba a
  `GoogleSignIn.instance.initialize()` **sin `serverClientId`**. Ese parámetro decide el `aud` del
  idToken; sin él, en iOS el token sale a nombre del cliente de iOS y en Android ni se emite. El
  backend lo valida con `idtoken.Validate(ctx, idToken, cfg.firebase.google_client_id)`, que es el
  cliente **web** (`…l1fkjhhnr998…`), así que **cualquier token que llegara se rechazaba**.
- **Alcance:**
  - `ios/Runner/GoogleService-Info.plist` — el descargado de la app real.
  - `ios/Runner/Info.plist` — el `REVERSED_CLIENT_ID` del esquema de URL cambia con la app nueva; sin
    tocarlo, el acceso con Google en iOS dejaría de volver a la aplicación.
  - `lib/firebase_options.dart` — `appId` e `iosBundleId` de la app real.
  - `lib/domain/providers/auth_provider.dart` — `serverClientId` con el cliente web.
- **Queda `com.example.legacyApp.RunnerTests`** en el proyecto de Xcode. Es el target de pruebas, no
  se distribuye y no afecta.
- **Verificado:** `flutter analyze` sin problemas en los archivos tocados y **117 tests** pasan. Lo
  demás solo se puede comprobar en un dispositivo real.
- ⚠️ **Falta la clave APNs en Firebase.** Sin ella, iOS no recibe notificaciones aunque todo lo
  anterior esté bien. Se comprueba en Configuración del proyecto → Cloud Messaging, sección de la app
  de Apple. La clave se crea en el portal de Apple marcando "Apple Push Notifications service" y se
  sube con su Key ID y el Team ID `87LBVBLK8T`. **La `AuthKey_H4DGAZR68T.p8` que ya existe es la de
  App Store Connect API**, para subir builds, y no sirve para esto salvo que se creara con esa
  casilla marcada.
- **Criterios de QA** (hace falta un build nuevo de iOS y un iPhone real):
  1. **Publicar un evento** desde el panel con la app iOS en segundo plano: la notificación llega.
  2. **Tocarla** abre el evento, no la bandeja.
  3. **Con la app cerrada del todo**, repetir: también llega y navega.
  4. **Iniciar sesión con Google** en iOS: entra y vuelve a la app.
  5. **Iniciar sesión con Google en Android**, que antes tampoco podía funcionar: entra igual.
  6. **En Android**, las notificaciones siguen llegando como hasta ahora.

### [2026-08-12]: Los datos del participante y el método de pago ya viajan

- **Por qué:** el formulario de "Datos del Participante" se validaba desde el 2026-08-05 y **se
  tiraba**; ninguna ruta los aceptaba. Y el selector de tarjeta o PSE no cambiaba nada. Ver la
  bitácora del backend para la migración y el cifrado.
- **Alcance:**
  - `lib/data/services/event_service.dart` — `registerToEvent` acepta el contacto del participante.
    Sin datos **no manda cuerpo**: el backend solo lo lee si llega como JSON.
  - `lib/data/services/payment_service.dart` — `createPaymentIntent` acepta `paymentMethod`.
  - `lib/domain/providers/events_provider.dart` y `event_payment_screen.dart` — los pasan.
  - `test/services/datos_participante_test.dart` — 5 casos.
- **Los campos en blanco no se envían**, en vez de mandarlos vacíos: ausente significa "usa los del
  perfil", y es más claro que una cadena vacía.
- **Verificado:** `flutter analyze` limpio y **117 tests** pasan.
- **Criterios de QA** (hace falta el backend con la migración aplicada):
  1. **Comprar un evento de pago** editando los tres campos: los valores nuevos son los que quedan
     registrados, no los del perfil.
  2. **Elegir PSE** antes de pagar y comprobar con soporte que quedó registrado.
  3. **Dejar los campos como vienen** prellenados: se guardan igual.
  4. **Un evento gratuito** sigue inscribiendo sin pasar por esta pantalla.

### [2026-08-12]: Los documentos legales publicados, alcanzables desde la app

- **Por qué:** las dos tiendas exigen poder llegar a los términos y a la política desde la
  aplicación, y la app **no enlazaba ninguno de los dos**. El registro pedía aceptar "la política de
  privacidad y habeas data vigente" sin dar forma de leerla, y `legal_notice_screen.dart` mostraba un
  texto propio de tres secciones titulado "Términos y Condiciones" que no es el documento real —el
  publicado tiene dieciséis—.
- **Alcance:**
  - `lib/data/config/documentos_legales.dart` — nuevo. Las dos URL en un solo sitio y el ayudante
    para abrirlas; devuelve `false` si no se pudo abrir, en vez de dejar el toque sin respuesta.
  - `lib/presentation/widgets/documentos_legales_enlaces.dart` — nuevo. Los dos enlaces.
  - `lib/presentation/screens/register_screen.dart` — enlaces bajo las casillas de aceptación.
  - `lib/presentation/screens/legal_notice_screen.dart` — el texto embebido pasa a presentarse como
    un resumen, con los documentos completos enlazados y declarados como los que rigen.
  - `test/screens/documentos_legales_test.dart` — 5 casos.
- **El texto de las casillas no se tocó.** Lo redacta el equipo de contenido; aquí solo se añade el
  acceso a los documentos.
- **Verificado:** `flutter analyze` limpio; **112 tests** pasan (107 previos + 5).
- **Criterios de QA:**
  1. **En el registro**, tocar "Términos y condiciones" abre el documento de la app en el navegador
     —no el de la web corporativa— y "Política de privacidad" abre el suyo.
  2. **Volver a la app** desde el navegador conserva lo que ya se había escrito en el formulario.
  3. **En Perfil › Avisos legales**, ambos enlaces funcionan y se lee que el texto es un resumen.
  4. **En modo avión**, tocar un enlace muestra el aviso de que no se pudo abrir, sin cerrar la app.

---

### [2026-08-12]: Tocar una notificación abre la novedad, no la bandeja

- **Por qué:** el backend manda `{type, id}` desde que existen los avisos —`event` al publicar un
  evento, `content` al publicar contenido (`handler/http/avisos.go`)— y la app los recibía y los
  ignoraba: `main.dart` hacía siempre `push('/notifications')`. Quien tocaba el aviso de un evento
  aterrizaba en una lista y tenía que buscarlo a mano.
- **Alcance:**
  - `lib/domain/utils/notificacion_destino.dart` — nuevo. `resolverNovedad()` traduce el `{type,
    id}` a ruta y entidad; `abrirNovedad()` navega. **La entidad se resuelve antes de navegar**
    porque las pantallas de detalle reciben el objeto entero por `extra`: empujar la ruta con un id
    reventaría en el cast de `state.extra`.
  - `lib/main.dart` — el listener de `onMessageOpenedApp` usa el resolvedor; se añade
    `getInitialMessage()`, que **no existía**, y sin el cual abrir la app desde una notificación
    con la app cerrada del todo no navegaba a ninguna parte; y se registra la ruta `/evento`.
  - `test/utils/notificacion_destino_test.dart` — 10 casos.
- **Cuidado con los dos modelos de evento.** `/evento` abre `EventPurchaseDetailScreen`, que es el
  detalle de los eventos de la API (`EventModel`). `EventDetailScreen`, la de "Participando",
  trabaja con `EventItem` y se alimenta del **JSON estático** `assets/data/events_data.json`, así
  que no sirve para un evento notificado por el backend. El primer intento usó esa y falló al
  compilar.
- **Si algo no se puede abrir se abre la bandeja**, como antes: sin red, contenido borrado, o un
  `type` que esta versión de la app todavía no conozca. Nunca deja de abrir algo.
- **Verificado:** `flutter analyze` sin errores ni warnings; **107 tests** pasan (97 previos + 10
  nuevos). Los 10 cubren los tres destinos reales y los seis modos de fallo, porque probar esto a
  mano exige enviar notificaciones push a un teléfono.
- **Criterios de QA** (hacen falta dos teléfonos o una cuenta de administrador y otra de usuario):
  1. **Publicar un evento** desde el panel y, con la app **en segundo plano**, tocar la
     notificación: debe abrirse el detalle de ese evento, no la bandeja.
  2. **Publicar contenido de tipo vídeo** y tocar su notificación: debe abrirse el reproductor.
  3. **Publicar contenido de texto**: debe abrirse el artículo.
  4. **Con la app cerrada del todo** (deslizada fuera del multitarea), repetir el paso 1. Este es el
     caso que antes no navegaba nunca.
  5. **En primer plano**, con la app abierta, la notificación sigue mostrando el aviso arriba sin
     saltar de pantalla de golpe.
  6. **Modo avión**: tocar una notificación de evento debe abrir la bandeja, sin pantalla en blanco
     ni cierre de la app.

---

### [2026-08-12]: Seis pantallas y diálogos que no permitían desplazarse

- **Por qué:** en la selección de tipo de perfil del registro, la tercera opción —"Quiero ser
  miembro de junta o consejo"— quedaba fuera de la pantalla en un iPhone con notch y no había forma
  de llegar a ella (`docs/ios/error_regsitro.jpeg`). La causa es un `Column` sin scroll, agravado
  por un `Spacer()` que forzaba a ocupar toda la altura. Al buscar el mismo patrón aparecieron
  cinco casos más; en los diálogos el disparador es el teclado, que reduce el alto disponible a la
  mitad.
- **Alcance:**
  - `lib/presentation/screens/profile_selection_screen.dart` — `SingleChildScrollView`; el
    `Spacer()` pasa a `SizedBox`, obligatorio porque un `Expanded` dentro de un scroll lanza
    excepción por constraints infinitas.
  - `lib/presentation/widgets/eventos/rating_dialog.dart` — `SingleChildScrollView`, como ya lo
    tenía su gemelo `event_survey_dialog.dart`.
  - `lib/presentation/screens/login_screen.dart` — la hoja de "Ciberseguridad Avanzada" mide unos
    700 px y no cabe en un iPhone SE.
  - `lib/presentation/widgets/perfil/eliminar_cuenta_dialog.dart`,
    `lib/presentation/screens/forums/forums_list_screen.dart`,
    `lib/presentation/widgets/moderacion/menu_moderacion.dart` — `scrollable: true`. `AlertDialog`
    **no** desplaza su `content` por defecto: lo mete en un `Flexible` que lo comprime.
  - `lib/presentation/screens/payment_callback_screen.dart` — solo desbordaba con la fuente
    ampliada por accesibilidad.
- **Sin cambios de comportamiento:** ninguna lógica, ruta ni llamada a la API se tocó; el contenido
  que ya cabía se sigue viendo igual.
- **Verificado:** `flutter analyze` sin errores ni warnings (los `info` son previos) y los 97 tests
  pasan.
- **Criterios de QA** (conviene un iPhone SE o el simulador de uno, que es donde se ve):
  1. **Registro:** abrir "Crear cuenta" y comprobar que se puede desplazar hasta la tercera
     tarjeta, "Quiero ser miembro de junta o consejo", y que entra al formulario con ese rol.
  2. **Login:** tocar el aviso de seguridad y comprobar que el texto completo y el botón
     "Entendido" son alcanzables.
  3. **Calificar una charla:** abrir el diálogo, tocar el campo de comentarios y comprobar que con
     el teclado abierto se llega al botón "Enviar Calificación".
  4. **Eliminar cuenta:** en Perfil, con el teclado abierto, el campo donde se escribe ELIMINAR
     debe seguir visible.
  5. **Foros:** en una cuenta sin alias, el diálogo de alias debe dejar ver el error y el botón con
     el teclado abierto.
  6. **Bloquear a alguien:** con el tamaño de fuente del sistema al máximo (Ajustes › Pantalla ›
     Tamaño del texto), el diálogo de confirmación debe poder desplazarse.
  7. **Ninguna franja amarilla de overflow** en las seis pantallas anteriores.

---

### [2026-08-11]: Las imágenes de los foros pasan a pedirse bajo `/api/`

- **Por qué:** la subida de imágenes de los foros estaba rota de las dos puntas. El backend nunca
  registró la ruta (arreglado hoy, ver su bitácora), y la app pedía `{host}/images/...` **sin
  `/api/`**, que en producción no llega al backend: HAProxy solo enruta ese prefijo. Es exactamente
  lo que ya había pasado con `/social-login`.
- **Alcance:**
  - `lib/data/config/api_constants.dart` — `imageUploadEndpoint` y el ayudante `imageUrl(name)`.
    Las URLs dejan de estar escritas a mano en la pantalla.
  - `lib/presentation/screens/forums/forum_thread_screen.dart` — subida (línea 90) y visualización
    (línea 389) pasan a usar esas constantes.
- **Compatibilidad:** el backend responde en las dos formas, así que los builds ya instalados —el
  `1.0.0+12` que está en TestFlight— **siguen funcionando** en cuanto se despliegue el backend, sin
  necesidad de actualizar la app.
- **Verificado:** `flutter analyze` sobre los dos archivos no reporta errores ni warnings; los 5
  avisos de nivel `info` que salen son de estilo y anteriores a este cambio.
- ⚠️ **No se instaló en el teléfono**: este cambio depende del backend desplegado. Instalarlo antes
  daría el mismo 404 de siempre y no probaría nada.
- **Criterios de QA** (después de desplegar el backend):
  1. **Adjuntar una imagen** a un mensaje de foro: se sube sin error y aparece en el hilo.
  2. **La imagen se ve desde otra cuenta** y sigue viéndose al reabrir la app.
  3. **En el emulador Android**, donde la URL base es `10.0.2.2`, la imagen también carga.
  4. **Un build antiguo** (el `1.0.0+12` de TestFlight) sigue subiendo y viendo imágenes.

---

### [2026-08-10]: Declaración de cifrado y build 1.0.0+12 para TestFlight

- **`ITSAppUsesNonExemptEncryption = false`** en `ios/Runner/Info.plist`. Sin esta clave, cada build
  queda en **Missing Compliance** en App Store Connect y no se puede instalar desde TestFlight ni
  enviar a revisión hasta responder el cuestionario a mano, **en cada subida**.
- **Por qué `false`, comprobado antes de declararlo:** la app **no implementa cifrado propio**. No
  hay ninguna librería de criptografía en `pubspec.yaml` ni código que cifre en `lib/`; solo usa
  HTTPS y `flutter_secure_storage`, que delega en el Keychain de iOS. El AES-256 del proyecto
  (`security.CryptoService`) vive en el **backend**, no en el binario que se distribuye, y la
  exención se evalúa sobre lo distribuido.
  **Es una declaración legal, no un ajuste técnico:** si algún día la app cifra por su cuenta, deja
  de ser cierta y hay que revisarla.
- **`pubspec.yaml` a `1.0.0+12`.** El `+11` ya está usado en TestFlight y el `+10` se quedó
  desalineado desde el 06-ago. Lanzar el workflow sin indicar número usaba el de `pubspec`, así que
  la desalineación era una trampa: ahora coinciden.
- **Este build es el primero que incluye** eliminar cuenta, bloquear y reportar personas, y los
  arreglos del registro por correo y del alias.
- **Criterios de QA (en el iPhone, desde TestFlight):**
  1. **El build aparece instalable**, sin quedarse en *Missing Compliance*.
  2. **La app instala y arranca.**
  3. **Registrarse con correo** funciona y llega el correo de verificación.
  4. **Login con Apple y con Google** siguen funcionando.
  5. **Llegan las notificaciones push** (`aps-environment: production`).
  6. **Bloquear desde un chat** oculta la conversación; **desbloquear** la devuelve con sus mensajes.
  7. **Reportar** exige motivo y el reporte aparece en el panel.
  8. **Eliminar mi cuenta** funciona y permite volver a registrarse con el mismo correo.
  9. **iOS no pide permiso de micrófono** en ningún momento.

### [2026-08-10]: Bloquear y reportar personas (directriz 1.2 de Apple)

- **Por qué:** Apple exige, para toda app con contenido generado por usuarios, poder **reportar y
  bloquear desde la propia app**. La app tiene chat 1:1, foros y publicaciones, y no había nada.
  Mensajería directa entre desconocidos sin bloqueo es uno de los rechazos más frecuentes de la
  App Store. **La API ya estaba; esto es la parte que Apple realmente mira.**
- **Alcance:**
  - `data/models/blocked_user_model.dart`, `data/services/block_service.dart`,
    `domain/providers/block_provider.dart` (nuevos), y los tres endpoints en `api_constants.dart`.
  - `presentation/widgets/moderacion/menu_moderacion.dart` (nuevo) — **una sola pieza** para las dos
    acciones. Tenerlas duplicadas por pantalla acabaría con textos distintos según por dónde se
    entre.
  - `presentation/widgets/moderacion/reportar_usuario_dialog.dart` (nuevo) — cinco motivos
    predefinidos más "Otro": quien acaba de recibir un mensaje desagradable no siempre quiere
    redactar nada, pero un reporte sin motivo no le sirve a quien lo revisa.
  - `presentation/screens/profile/usuarios_bloqueados_screen.dart` (nuevo) + ruta
    `/cuentas-bloqueadas` y entrada en el perfil.
  - `individual_chat_screen.dart` — menú en el encabezado; `community_members_screen.dart` — con
    pulsación larga sobre cada miembro.
  - `custom_section_header.dart` — parámetro opcional `trailing`. Opcional a propósito: el resto de
    pantallas que usan este encabezado no cambian.
  - `chat_provider.dart` — `otherUserIdOf`: la pantalla de chat solo recibía el id de la
    conversación y el título, y para bloquear hace falta saber a quién.
  - `Tests`: `test/screens/moderacion_test.dart` (6 casos). La suite pasa de 91 a **97**.
- **Se puede bloquear desde el directorio, no solo desde el chat.** Si únicamente se pudiera desde
  una conversación, para bloquear a alguien habría que abrir primero un chat con esa misma persona.
- **El diálogo dice qué pasa con los mensajes: no se borran.** Al desbloquear, la conversación
  vuelve tal como estaba. Prometer un borrado que no ocurre sería engañar, y quien bloquea a veces
  necesita conservar lo que le escribieron.
- **Reportar y bloquear son cosas distintas y el diálogo lo dice.** Confundirlas dejaría a alguien
  esperando que el acoso pare solo por haber reportado.
- **Si el reporte falla, el diálogo NO se cierra.** Lo peor sería que alguien creyera haber
  denunciado a quien le acosa cuando el reporte no llegó.
- **Si las conexiones aún no están cargadas, el menú del chat no aparece:** es preferible que falte
  un momento a ofrecer bloquear a quien no es.
- `flutter analyze` sigue en los mismos **48** avisos de estilo: los archivos nuevos no añaden
  ninguno.
- **Criterios de QA:**
  1. **Desde un chat**, el menú del encabezado ofrece reportar y bloquear.
  2. **Al bloquear**, se pide confirmación, se sale de la conversación y esta desaparece de la lista.
  3. **La otra persona tampoco ve la conversación** ni puede escribir.
  4. **Desde el directorio de la comunidad**, mantener pulsado a un miembro abre el mismo menú, y al
     bloquear desaparece de la lista.
  5. **Perfil › Cuentas bloqueadas** lista a los bloqueados; con ninguno, sale el mensaje vacío.
  6. **Desbloquear** devuelve a la persona al directorio y **la conversación reaparece con sus
     mensajes**.
  7. **Reportar exige motivo:** el botón está deshabilitado hasta elegir uno o escribirlo.
  8. **Si falla el envío del reporte**, el diálogo sigue abierto y muestra el error.
  9. **Reportar no bloquea:** tras reportar se sigue pudiendo escribir, y el diálogo lo avisa.
  10. **Cerrar sesión y entrar con otra cuenta** no arrastra la lista de bloqueados de la anterior.

### [2026-08-10]: Se retira el permiso de micrófono de iOS

- **El problema:** `ios/Runner/Info.plist` declaraba `NSMicrophoneUsageDescription` con el texto
  "para grabar videos", y **la app no graba nada**. Verificado: las únicas dependencias que tocan
  medios son `image_picker` (foto de perfil) y `qr_flutter`, que **genera** códigos QR, no los
  escanea —el escaneo lo hace el panel administrativo—.
- **Por qué importa para publicar:** un permiso declarado sin uso genera observaciones en la revisión
  de Apple, aparece en la ficha de privacidad de la App Store y obliga a justificarlo en el
  cuestionario *App Privacy*. Pedir el micrófono sin usarlo es de las cosas que un revisor mira.
- **Alcance:** `ios/Runner/Info.plist` — se elimina la clave y su descripción. Quedan
  `NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription`, ambos justificados por la foto de
  perfil.
- **Sin cambios de código.** `flutter analyze` sigue en los mismos 48 avisos de estilo, ninguno nuevo.
- **Criterios de QA (en el iPhone, con un build nuevo):**
  1. **La foto de perfil sigue funcionando** desde la cámara y desde la galería: son los dos permisos
     que se conservan.
  2. **iOS no pide micrófono** en ningún momento del uso de la app.
  3. **En Ajustes → Legacy**, el micrófono ya no aparece en la lista de permisos de la app.
  4. **El QR de asistencia a un evento se sigue mostrando** correctamente: lo genera la app, no
     necesita cámara ni micrófono.

### [2026-08-06]: Eliminar mi cuenta desde la app

- **Es requisito de tienda, no una mejora.** App Store lo exige desde junio de 2022 (directriz
  5.1.1(v)) y Google Play también: sin esta opción **la app no se puede publicar**. Hasta ahora el
  perfil solo ofrecía cerrar sesión.
- **Alcance:**
  - `lib/presentation/widgets/perfil/eliminar_cuenta_dialog.dart` (nuevo) — diálogo que **exige
    escribir ELIMINAR**, no un simple "¿seguro?": la acción no se deshace y un toque accidental en
    la lista del perfil no debería bastar. Se acepta en minúsculas: se comprueba la palabra, no el
    teclado.
  - **Dice lo que NO se borra.** Avisa de que las inscripciones y los mensajes se conservan sin
    nombre, porque forman parte del historial de otras personas y de eventos ya pagados. Prometer un
    borrado total y conservar registros sería engañar.
  - `auth_service.dart` — `deleteAccount(token)`: llama a `DELETE /api/me` **sin enviar ningún
    identificador**, que el servidor toma del token. Mandarlo permitiría borrar la cuenta ajena.
  - `auth_provider.dart` — cierra la sesión **solo si el servidor confirma**; si falla, no se toca
    nada local y el error sube a la pantalla.
  - `profile_screen.dart` — nueva entrada "Eliminar mi cuenta" bajo "Cerrar sesión".
  - `Tests`: `test/screens/eliminar_cuenta_test.dart` (6 casos). La suite pasa de 85 a **91**.
- **Criterios de QA:**
  1. **No se borra de un toque:** el botón nace deshabilitado y solo se activa al escribir
     `ELIMINAR`. Escribir otra cosa no lo habilita.
  2. **Se avisa de lo que se conserva:** el diálogo menciona inscripciones y mensajes.
  3. **Al confirmar**, la app vuelve al login y ya no se puede entrar con esas credenciales.
  4. **Si el servidor falla**, aparece el error y **el diálogo NO se cierra**: lo peor sería que
     alguien creyera que su cuenta se borró cuando sigue existiendo.
  5. **Volver a registrarse** con el mismo correo funciona y da una cuenta nueva y vacía.
  6. **Dejan de llegar notificaciones push** a ese dispositivo.

### [2026-08-06]: El workflow de iOS funciona — build 1.0.0+11 en TestFlight

- **`UPLOAD SUCCEEDED with no errors`.** Primera vez que se genera y publica un build de iOS de este
  proyecto, y se hizo **sin ningún Mac**: todo en runners de GitHub, gratuitos por ser el
  repositorio público.
- **Compilado con Xcode 26.6 / SDK iOS 26.5.** El runner tuvo que pasar de `macos-15` a `macos-26`
  porque Apple **rechaza en la validación** cualquier app construida con un SDK anterior al de iOS
  26. El `.ipa` se generaba y firmaba bien; lo rechazaban al recibirlo.
- **Ocho ejecuciones hicieron falta**, y cada fallo fue distinto y real. Están todos tabulados en
  `DESPLIEGUE.md`, sección "Si falla", porque volverán a aparecer al renovar credenciales o cuando
  Apple suba el mínimo de Xcode. Los dos más traicioneros:
  - `MAC verification failed ... (wrong password?)` cuando la contraseña era correcta: sobraba un
    `\n` al final del secreto.
  - `does not support provisioning profiles` en Firebase y GoogleSignIn: los ajustes de firma
    pasados por línea de comandos a `xcodebuild` se aplican a **todos** los targets, y los Swift
    Packages no los admiten. La firma va en `ExportOptions.plist`.
- **Credenciales creadas, ambas desde Windows:** certificado de distribución (CSR con OpenSSL +
  portal web) y provisioning profile "Legacy App Store CI". Apple **no permite crear ninguna de las
  dos con una clave de API** —responde 403 incluso con rol Admin—, así que viven como secretos.
  Los archivos quedaron en `docs/ios/`, fuera de git.
- **Seis secretos** en el repositorio: los tres de App Store Connect más `APPLE_DIST_CERT_P12`,
  `APPLE_DIST_CERT_PASSWORD` y `APPLE_PROVISIONING_PROFILE`.
- **Caducidades a vigilar:** el certificado y el perfil, ambos el **2027-08-06**.
- **Criterios de QA (en el iPhone, con el build de TestFlight):**
  1. **Responder el cuestionario de cifrado** en App Store Connect, o el build queda en *Missing
     Compliance* y no se puede instalar.
  2. **La app instala y arranca** desde TestFlight.
  3. **Llegan las notificaciones push.** Es lo que desbloquea el `aps-environment: production`
     corregido hoy: con `development` no habrían llegado nunca en un build distribuido.
  4. **El login con Apple funciona**, que es lo que desbloquea el entitlement añadido hoy.
  5. **El login con Google sigue funcionando**, que convive con él en la misma pantalla.

### [2026-08-06]: Workflow de iOS — dos fallos reales y cómo se resolvieron

Las dos primeras ejecuciones fallaron. Queda anotado porque ninguno de los dos fallos se puede
anticipar desde Windows y volverán a aparecer en cualquier proyecto Flutter que se compile en CI.

**1ª ejecución — `flutter analyze` tumbó el build antes de compilar.** En macOS, `flutter pub get`
resuelve en `build/` los Swift Packages de los plugins de iOS y macOS, y eso arrastra el código de
**ejemplo** de cada plugin. El analizador se puso a revisarlo y encontró errores por dependencias
que ese ejemplo usa y nosotros no (`flutter_local_notifications`). En Windows no ocurre, porque ahí
no se resuelven los paquetes de iOS: por eso pasaba en local y solo fallaba en el runner.
→ **Arreglo:** `analyzer: exclude: [build/**]` en `analysis_options.yaml`.

**2ª ejecución — falló al exportar el IPA**, con el archive ya correcto:
`No signing certificate "iOS Distribution" found` y `Cloud signing permission error`. Xcode había
creado por cloud signing un certificado de **desarrollo**; para exportar con `method: app-store`
hace falta uno de **distribución**, y **Apple no permite crearlo con una clave de API**: responde
`403 You are not allowed to perform this operation` incluso con rol Admin —comprobado, la clave
puede listar usuarios de la cuenta, que es privilegio exclusivo de Admin—.
→ **Arreglo:** el certificado se generó una vez desde Windows (CSR con OpenSSL, firmado en el portal
web de Apple) y viaja como secreto en un `.p12`; el workflow lo importa en un llavero temporal.
Los provisioning profiles sí los sigue creando Xcode con la clave de API: eso nunca falló.

- **Alcance:** `analysis_options.yaml`, `.github/workflows/ios-testflight.yml` (paso nuevo
  "Importar el certificado de distribucion"), y `DESPLIEGUE.md` con el procedimiento completo,
  incluido cómo renovar el certificado cuando caduque **el 2027-08-06**.
- **Dos secretos nuevos:** `APPLE_DIST_CERT_P12` y `APPLE_DIST_CERT_PASSWORD`, ya cargados.
- **`set-key-partition-list` es imprescindible** en el paso del llavero: sin él, `codesign` pide
  confirmación interactiva y el job se cuelga hasta agotar el tiempo.
- **Verificado:** el certificado emitido es `Apple Distribution: LEGACY NETWORK SAS (87LBVBLK8T)`,
  y su modulus coincide con la clave privada generada en local, así que el par es válido.
- **Pendiente:** la ejecución con todo esto en su sitio. Los pasos 1 a 6 ya pasaron en verde en la
  segunda ejecución; falta confirmar del 7 en adelante.

### [2026-08-06]: Sign in with Apple y preparación de la primera compilación en CI

- **Alcance:**
  - `ios/Runner/Runner.entitlements` y `RunnerDebug.entitlements` — se añade
    `com.apple.developer.applesignin`. La app llama a `SignInWithApple.getAppleIDCredential`
    (`auth_provider.dart:256`) y **sin el entitlement esa llamada falla en ejecución**; además, al
    ofrecer login con Google, la directriz **4.8** obliga a ofrecer también Sign in with Apple o la
    revisión lo rechaza. Se pone en las dos configuraciones: si solo estuviera en Release, fallaría
    al probar desde Xcode y parecerían dos fallos distintos.
  - **El orden se respetó:** la capability `APPLE_ID_AUTH` **ya estaba habilitada** en el App ID
    —verificado consultando la API de App Store Connect—, que es el requisito previo para que la
    firma no falle.
  - `event_purchase_detail_screen.dart` y `forums_screen.dart` — se retiran **5 imports sin usar**.
    Eran los únicos `warning` del proyecto y **habrían abortado el workflow** en su paso de
    análisis, antes siquiera de compilar.
  - `.github/workflows/ios-testflight.yml` — el análisis pasa a `flutter analyze --no-fatal-infos`.
    Los errores y los warnings siguen tumbando el build, que es la barrera que interesa; los 48
    avisos de nivel `info` que arrastra el proyecto son de estilo, y bloquear por ellos dejaría el
    workflow inutilizable hasta limpiarlos todos.
- **Verificado en local, que es lo que hará el CI:**
  - `flutter analyze --no-fatal-infos` → **exit 0** (48 infos, 0 warnings, 0 errores).
  - `flutter test` → **exit 0, 85 tests**.
  - Ambos archivos de entitlements siguen siendo plist válidos.
- **Criterios de QA:**
  1. **El workflow llega a compilar:** los pasos de análisis y tests deben pasar en verde en la
     primera ejecución. Antes de este cambio, habrían fallado por los 5 imports.
  2. **Login con Apple funciona** en un dispositivo real con el build de TestFlight. Es lo que el
     entitlement desbloquea.
  3. **El login con Google sigue igual**, que es lo que convive con él en la misma pantalla.

### [2026-08-06]: El proyecto iOS decía 13.0 y los Pods exigían 15.0

- **El problema:** `IPHONEOS_DEPLOYMENT_TARGET = 13.0` en las tres configuraciones del proyecto,
  contra `platform :ios, '15.0'` en el `Podfile`. Compilar con esa contradicción da avisos y puede
  fallar al enlazar, porque las dependencias se construyen para una versión mínima superior a la de
  la app.
- **Se subió el proyecto, no se bajó el Podfile**, porque bajarlo **no era posible**: los pods
  `firebase_core` y `firebase_messaging` instalados (Firebase iOS SDK **12.15.0**) declaran
  `"ios": "15.0"` como mínimo. Volver a 13.0 exigiría degradar Firebase.
- **Alcance:**
  - `ios/Runner.xcodeproj/project.pbxproj` — las **tres** configuraciones a `15.0`.
  - `ios/Flutter/AppFrameworkInfo.plist` — `MinimumOSVersion` a `15.0`; era el tercer sitio donde se
    declaraba y también decía 13.0.
  - El `Podfile` ya estaba en `15.0` y su `post_install` fuerza `15.0` en todos los pods: no se
    tocó.
- **Impacto en usuarios: prácticamente nulo.** iOS 15 es compatible con **los mismos modelos** que
  iOS 13 —del iPhone 6s en adelante—, así que no queda ningún dispositivo fuera; solo quedarían
  fuera usuarios que tengan un iPhone compatible y no lo hayan actualizado nunca.
- **Sin verificar con Xcode**: hecho desde Windows. Sí se comprobó que los plist siguen siendo
  válidos y que el diff son cuatro líneas.
- **Criterios de QA (requieren macOS):**
  1. **`pod install` sin avisos** de deployment target incompatible.
  2. **`flutter build ios` compila** sin errores.
  3. **La app arranca** en un dispositivo con iOS 15 o superior.
  4. **App Store Connect** acepta el build sin quejarse de la versión mínima.

### [2026-08-06]: iOS pedía el APNs de pruebas, así que las push no llegarían en TestFlight

- **El problema:** `Runner.entitlements` declaraba `aps-environment = development` para **las tres**
  configuraciones. Con ese valor iOS entrega un token del APNs **sandbox**, que no sirve en builds
  distribuidos: las notificaciones funcionarían con el dispositivo conectado por cable y **no
  llegarían** ni por TestFlight ni por App Store. Con las push ya operativas en Android desde hoy,
  esto dejaba fuera a todos los usuarios de iPhone.
- **Alcance:**
  - `ios/Runner/Runner.entitlements` → `production`. Lo usan **Release y Profile**, que son las
    configuraciones que se distribuyen.
  - `ios/Runner/RunnerDebug.entitlements` (nuevo) → `development`, para que los builds lanzados
    desde Xcode sigan usando el APNs de pruebas.
  - `ios/Runner.xcodeproj/project.pbxproj` — **una sola línea**: la configuración Debug apunta al
    archivo nuevo. Release y Profile siguen igual.
  - `ios/Runner/Info.plist` — `UIBackgroundModes: [remote-notification]`. La app **ya registra**
    `FirebaseMessaging.onBackgroundMessage` (`main.dart:84`) y sin esta clave iOS nunca lo ejecuta.
    Las notificaciones con alerta se mostraban igual —de eso se encarga el sistema—; lo que no
    ocurría era el procesamiento de los datos que las acompañan.
  - **Sin verificar con Xcode**: se hizo desde Windows, así que no hay build de iOS que lo respalde.
    Sí se comprobó que los tres archivos siguen siendo plist válidos y que el cambio en el proyecto
    es exactamente una línea.
- **Requisito que no está en el código:** en la consola de Firebase, el proyecto `app-legacy-848f1`
  necesita una **clave de APNs (.p8)** subida, o certificados de **producción**. Sin eso, el
  entitlement correcto no basta y las push seguirán sin llegar en iOS.
- **Criterios de QA (requieren macOS con Xcode):**
  1. **Compila:** `flutter build ios` termina sin errores de firma. Es lo primero, porque el cambio
     toca el proyecto Xcode.
  2. **Debug sigue en sandbox:** con la app lanzada desde Xcode, el log de FirebaseMessaging **no**
     debe mostrar el aviso de entorno APNs incorrecto.
  3. **TestFlight:** subir un build y comprobar que **llega** una notificación enviada desde el
     panel a "todos". Es la prueba que justifica el cambio; antes no llegaba.
  4. **Aviso automático:** crear un evento desde el panel y comprobar que el iPhone lo recibe, igual
     que ya hace Android.
  5. **Segundo plano:** con la app cerrada, la notificación debe aparecer en el centro de
     notificaciones.
- **Sigue pendiente y no se tocó:** `IPHONEOS_DEPLOYMENT_TARGET = 13.0` en el proyecto contra
  `platform :ios, '15.0'` en el `Podfile`.

### [2026-08-05]: La vuelta desde la pasarela de pagos ya llega a la app

- **Alcance:**
  - `Android`: `AndroidManifest.xml` — nuevo `intent-filter` con `VIEW` + `BROWSABLE` y
    `scheme="legacyapp"`, `host="app"`, más `flutter_deeplinking_enabled`. **El esquema no estaba
    declarado**: CredibanCo redirigía a `legacyapp://…` y el navegador no encontraba ninguna
    aplicación que lo atendiera, así que el usuario se quedaba en una pantalla de error **después de
    haber pagado** y el cobro no se confirmaba nunca.
  - `iOS`: `Info.plist` — `CFBundleURLSchemes` con `legacyapp` (solo estaba el de Google Sign-In) y
    `FlutterDeepLinkingEnabled`.
  - **El host `app` no es decorativo:** Flutter enruta por el **path** de la URI, y
    `legacyapp://payment-callback` deja el path vacío, así que el router nunca llegaría a
    `/payment-callback`. La URL de retorno pasa a ser `legacyapp://app/payment-callback`.
  - `Callback`: `payment_callback_screen.dart` — ahora envía la cabecera `Authorization`
    (`/api/payments/verify` está bajo `AuthMiddleware`, así que **la llamada anterior siempre
    respondía 401**), lee `tx_id`, traduce cada estado de la pasarela a un mensaje con lo que el
    usuario puede hacer, recarga las inscripciones tras un pago aprobado y ofrece ir a "Mi
    credencial" en vez de solo al inicio.
  - `Router`: `/payment-callback` lee `tx_id` (antes `order_id`, que el backend nunca enviaba);
    se aceptan los nombres antiguos por si llega un enlace viejo.
  - `Pantalla de espera`: al abrir la pasarela la app ya no salta a `/eventos` —el usuario volvía y
    aterrizaba en el listado como si no hubiera pasado nada—, sino que queda una pantalla que
    explica el estado y enlaza a "Mi credencial".
- **Criterios de QA:**
  1. **El esquema está registrado:** `adb shell dumpsys package co.legacynetwork.legacyapp` debe
     mostrar `Scheme: "legacyapp"` con `Authority: "app"`.
  2. **El enlace abre la app:**
     `adb shell am start -a android.intent.action.VIEW -d 'legacyapp://app/forgot-password'` debe
     abrir "Recuperar Contraseña", no la pantalla inicial. Confirma que el enrutado por path va.
  3. **Pago real:** con sesión iniciada, pagar un evento y volver → debe aparecer la pantalla de
     verificación y luego el resultado, no el listado de eventos.
  4. **Tras aprobarse:** la inscripción deja de estar "PENDIENTE DE PAGO" en el detalle del evento y
     el QR aparece en "Mi credencial", sin reiniciar la app.
  5. **Pago rechazado:** mensaje explicando que el cupo sigue reservado y se puede reintentar.
  6. **Sesión caducada al volver:** el usuario acaba en el login; el pago **no** queda confirmado
     hasta que vuelva a entrar. Es la limitación que resuelve el webhook, todavía pendiente.

### [2026-08-05]: Datos del participante obligatorios, y el pago deja de enviar usuario e importe libre

- **Alcance:**
  - `Obligatoriedad`: `event_payment_screen.dart` — los tres datos del participante son requisito
    para continuar. La validación ya existía; ahora además las etiquetas llevan `*`, aparece un
    aviso al pie si falta algo, y tras el primer intento fallido los errores se refrescan mientras
    el usuario escribe (`autovalidateMode.onUserInteraction`) en vez de esperar a que vuelva a
    pulsar.
  - `Pago`: `payment_service.dart` deja de enviar la cabecera `X-User-ID` —el backend toma el
    usuario del token— y traduce los rechazos del servidor: **409** "el precio cambió, vuelve a
    abrir el evento", **400** evento gratuito, **404** evento inexistente, **401** sesión expirada.
    Antes se mostraba el cuerpo crudo de la respuesta.
  - `checkout_screen.dart` (carrito): mismo cambio de firma.
  - `Tests`: 3 casos nuevos en `event_payment_screen_test.dart` (10 en total).
- **Criterios de QA:**
  1. **Los tres campos son obligatorios:** vaciar cualquiera de ellos y pulsar *PROCEDER AL PAGO* →
     no debe abrirse la pasarela ni reservarse el cupo, y sale el aviso "Completa los datos del
     participante para continuar".
  2. **Un solo campo vacío basta para detener el flujo:** con nombre y correo puestos y el teléfono
     en blanco, tampoco continúa.
  3. **Se ven marcados:** las etiquetas muestran `Nombre Completo *`, `Email *` y `Teléfono *`.
  4. **Corregir desbloquea:** al completar el campo que faltaba, el error desaparece solo y el botón
     ya lleva a la pasarela.
  5. **Correo con errata:** `johan.example` → "Ese correo no parece válido", y no continúa.

### [2026-08-05]: El botón del evento ignoraba la inscripción, y "Recordarme" no aplicaba al login social

- **Alcance:**
  - `Botón del detalle`: `lib/presentation/widgets/eventos/event_action_button.dart` (nuevo),
    enganchado en `event_purchase_detail_screen.dart`. La pantalla decidía con
    `event.actionStatus == 'registered'`, pero **`action_status` es una columna del EVENTO**, igual
    para todos los usuarios, y el backend solo devuelve `register` o `buy`. La condición **no se
    cumplía nunca**: el mensaje "YA ESTÁS REGISTRADO" era código inalcanzable y quien ya estaba
    inscrito seguía viendo "Reservar cupo". Ahora se decide con la inscripción real, de
    `GET /api/me/registrations`.
  - `Provider`: `registerUserToEvent` parcheaba el evento en memoria con `actionStatus:
    'registered'`; el efecto se perdía al recargar el listado, porque el backend devuelve siempre el
    valor de la tabla. Ahora recarga las inscripciones reales. Nuevos `registrationFor(eventId)` y
    `registrationsLoaded`, este último para no ofrecer reservar un cupo mientras aún no se sabe si
    el usuario lo tiene.
  - `"Recordarme"` (acceso con correo y contraseña): la sesión **sí se guardaba**; lo que fallaba
    era al recuperarla. El token del backend **dura 24 horas** (`auth_service.go:54`) y no hay
    refresh token, y `checkLoginStatus` lo restauraba **sin comprobar la caducidad**: al día
    siguiente `isAuthenticated` era `true`, el splash llevaba a `/home` y todas las llamadas
    respondían 401. `fetchProfile` se tragaba ese 401 con un `debugPrint` y dejaba el token muerto
    en el dispositivo. Desde fuera, "la sesión recordada no sirve". Ahora
    `AuthProvider.tokenCaducado` lee el claim `exp` sin llamar al servidor y limpia la sesión, de
    modo que el usuario aterriza en el login. El borrado se unifica en `_borrarDatosPersistidos`,
    que además limpia `user_alias`, que se quedaba.
  - **Límite que sigue en pie:** "Recordarme" no puede durar más de 24 horas mientras el backend no
    emita un refresh token. Alargar `tokenDuration` sin más no es la solución: un token robado
    valdría lo mismo que dure.
  - `Casilla`: el `Checkbox` vivía dentro de un `GestureDetector` que alternaba el mismo estado, de
    modo que el comportamiento dependía de si el dedo caía sobre la casilla o sobre el texto. Ahora
    hay un único `InkWell` y la casilla lleva colores explícitos: sin ellos quedaba casi invisible
    sobre el fondo oscuro de esa pantalla.
  - `Tests`: `event_action_button_test.dart` (4 casos) y `login_recordarme_test.dart` (4 casos).
- **Criterios de QA:**
  1. **Evento ya inscrito:** abrir el evento gratuito en el que ya estás inscrito → debe decir
     **"YA ESTÁS REGISTRADO"** y ofrecer **"Ver mi credencial"**. Antes salía "Reservar cupo gratis".
  2. **Persiste al recargar:** volver atrás, tirar para recargar el listado y entrar de nuevo; debe
     seguir diciendo que estás registrado. Ese era el fallo del parche en memoria.
  3. **Evento no inscrito:** otro evento debe seguir ofreciendo reservar con normalidad.
  4. **Recién reservado:** al reservar un cupo gratis, el botón cambia solo, sin salir de la
     pantalla.
  5. **Pendiente de pago:** un evento de pago con el cupo reservado muestra "CUPO RESERVADO ·
     PENDIENTE DE PAGO" y el botón **Completar pago**.
  6. **Recordarme con correo:** marcar la casilla, entrar con correo y contraseña, **cerrar la app
     por completo** y reabrirla → debe entrar directo, sin pedir credenciales. **Ojo: reinstalar la
     app borra el almacén cifrado, así que la prueba solo vale sin reinstalación de por medio.**
  7. **Sesión caducada:** pasadas 24 horas desde el acceso, reabrir la app debe llevar **al login**,
     no a una pantalla de inicio donde todo falle en silencio. Este era el fallo.
  8. **Sin recordarme:** desmarcar, entrar, cerrar la app y reabrirla → debe pedir credenciales otra
     vez.
  9. **La casilla responde:** tocar la casilla y también el texto "Recordarme"; en ambos casos debe
     alternar, y el tilde debe verse en dorado sobre el fondo oscuro.

### [2026-08-05]: "Mi credencial" — los QR de todos los eventos inscritos

- **Alcance:**
  - `Pantalla nueva`: `lib/presentation/screens/profile/mi_credencial_screen.dart` y la ruta
    `/mi-credencial`. **El botón "Mi credencial" del perfil tenía `onTap: () {}`**: no hacía nada,
    pese a que su subtítulo prometía "QR de acceso a eventos".
  - `Modelo y servicio`: `registration_model.dart` (nuevo) y `getMyRegistrations` contra
    `GET /api/me/registrations`; `loadMyRegistrations` en `EventsProvider`.
  - `Agenda`: el botón flotante mostraba **siempre el QR del primer taller** de la agenda y solo
    existía si la agenda tenía algo. Como inscribirse a un evento **no** llena la agenda —eso lo
    hace añadir talleres uno a uno—, una inscripción válida podía quedarse sin ninguna forma de
    enseñarse. Ahora el botón lleva a "Mi credencial" y se ofrece siempre.
  - `Código retirado`: `qr_attendance_dialog.dart`, `getRegistrationQr` y `getRegistration`. Solo se
    usaban entre sí, y `getRegistration` era un alias de `registerToEvent`, es decir, **un `POST` de
    escritura usado para leer**.
  - `Tests`: `test/screens/mi_credencial_screen_test.dart` (nuevo, 7 casos).
- **Criterios de QA:**
  1. **El botón ya responde:** Perfil → **Mi credencial** abre la pantalla. Antes no pasaba nada.
  2. **Todos los eventos:** aparece una tarjeta con QR por **cada** evento inscrito, no solo uno.
  3. **Pendiente de pago:** un evento de pago sin pagar muestra "Pendiente de pago" y **no** enseña
     QR; el texto explica que el cupo está reservado.
  4. **Sin eventos:** mensaje "Todavía no tienes eventos" con la explicación, no una pantalla en
     blanco.
  5. **Sin conexión:** mensaje de error y el gesto de tirar para recargar debe funcionar igual.
  6. **Asistencia:** tras el check-in, la tarjeta muestra "Asistencia registrada" en verde.
  7. **Orden:** los eventos ya pasados van al final, bajo el título "Eventos pasados".
  8. **Desde la agenda:** el botón flotante dice "Mi credencial" y lleva a la misma pantalla, exista
     o no agenda.

### [2026-08-05]: Datos del participante prellenados al reservar cupo

- **Alcance:**
  - `Pantalla`: `lib/presentation/screens/eventos/event_payment_screen.dart` — los tres campos de
    "Datos del Participante" **no tenían `controller` ni `initialValue`**: lo que se veía
    ("Juan Perez Garcia", "juan.perez@email.com", "+57 300 123 4567") eran los `hintText`, de modo
    que el formulario era decorativo y nada de lo escrito se leía. Ahora llevan controladores
    reales, se prellenan con el perfil del usuario en `didChangeDependencies` —una sola vez, para
    no pisar una corrección del usuario— y se validan. `_formKey` se declaraba desde siempre y
    nunca se llamaba a `validate()`; ahora sí, antes de proceder al pago.
  - `Provider`: `lib/domain/providers/auth_provider.dart` — nuevo `phone`, que `GET /api/me` ya
    devolvía y `fetchProfile` descartaba, y `fullName`, que une nombre y apellido sin dejar espacios
    sobrantes si falta alguno. Ambos se persisten y **se borran al cerrar sesión**, para que el
    siguiente usuario no vea el teléfono del anterior.
  - `Tests`: `test/screens/event_payment_screen_test.dart` (nuevo) — 5 casos.
  - **Sin cambios en el backend.**
- **Criterios de QA:**
  1. **Prellenado:** abrir un evento de pago → *Reservar cupo* → los tres campos llegan con el
     nombre, el correo y el teléfono de la cuenta.
  2. **Perfil incompleto:** con un usuario sin teléfono, ese campo queda **vacío**, no con el texto
     de ejemplo. El gris que se ve es el `hint`, no un valor: si se envía, el campo va vacío.
  3. **Editable:** cambiar el nombre a otro participante y comprobar que el texto se conserva al
     desplazar la pantalla.
  4. **Validación:** vaciar los tres campos y pulsar *PROCEDER AL PAGO*; deben salir los tres
     mensajes y **no** debe abrirse la pasarela.
  5. **Correo con errata:** escribir `johan.example` (sin arroba) → "Ese correo no parece válido".
  6. **Tras cerrar sesión** y entrar con otra cuenta, los campos traen los datos de la **nueva**
     cuenta.
- **Advertencia:** estos datos **todavía no viajan a ninguna parte** — ni
  `/api/payments/intent` ni `/api/events/{id}/register` los aceptan. El análisis completo del flujo
  de pago, con los otros siete fallos encontrados y sin corregir, está en
  `reports/20260805_flujo_pago_eventos.md`.

### [2026-08-05]: Encuesta general del evento (eventos, fase 3)

- **Alcance:**
  - `Constantes`: `lib/data/config/api_constants.dart` — `eventSurveyEndpoint` y
    `myEventSurveyEndpoint`. Verificado contra las rutas que registra `main.go` con la skill
    `verificar-contratos-api`.
  - `Modelo`: `lib/domain/models/event_survey_model.dart` (nuevo) — `EventSurveyModel` y
    `EventSurveyException`. **`toJson` omite las preguntas sin responder en vez de mandarlas como
    `0`:** el backend distingue `null` de una nota baja, y un `0` rompería el `CHECK` de la tabla,
    que exige entre 1 y 5. Un "no lo recomendaría" sí viaja, como `false`.
  - `Servicio`: `lib/data/services/event_service.dart` — `submitEventSurvey` y `getMyEventSurvey`.
    A diferencia de `submitWorkshopRating`, que devuelve un `bool` y borra el motivo del fallo,
    aquí se lanza `EventSurveyException` con el motivo traducido del código HTTP, porque "no estás
    registrado" y "ya opinaste" piden mensajes distintos en pantalla.
  - `Provider`: `lib/domain/providers/events_provider.dart` — `loadMyEventSurvey`,
    `submitEventSurvey`, `mySurveyFor` y `hasCheckedSurvey`. **Un 409 se trata como éxito:** el
    objetivo del usuario está cumplido, así que se recarga su respuesta y se le muestra, en vez de
    darle un error por algo que ya hizo.
  - `Pantalla`: `lib/presentation/widgets/eventos/event_survey_dialog.dart` y
    `event_survey_button.dart` (nuevos), enganchados en
    `lib/presentation/screens/eventos/event_purchase_detail_screen.dart`. En un evento terminado el
    botón de "reservar cupo" no tiene sentido y se sustituye por el de la encuesta.
  - `Tests`: `test/models/event_survey_model_test.dart` y `test/screens/event_survey_test.dart`
    (nuevos) — 16 casos.
- **Criterios de QA:**
  1. **Solo en eventos pasados:** abrir un evento de **Próximos** debe seguir mostrando "Reservar
     cupo"; uno de **Pasados**, el botón **Califica este evento**.
  2. **Formulario:** el diálogo pide la calificación general (obligatoria, marcada con `*`) más
     organización, contenido, conferencistas, si lo recomendaría y un comentario libre.
  3. **Sin calificación general:** pulsar *Enviar opinión* sin marcar estrellas muestra "Danos al
     menos tu calificación general" y **no** llama al backend.
  4. **Envío correcto:** con la sesión de alguien registrado, enviar → mensaje verde "¡Gracias por
     tu opinión!" y el diálogo se cierra.
  5. **Al reabrir:** el botón pasa a **Ver tu opinión** y el diálogo muestra lo respondido en
     estrellas, sin formulario.
  6. **Sin registro previo:** con la sesión de alguien que no se inscribió, enviar debe mostrar
     "Solo pueden opinar quienes se registraron en el evento", no un error genérico.
  7. **Comentario en blanco:** escribir solo espacios y enviar; la encuesta se guarda sin
     comentario, y al reabrir no aparece el recuadro gris del comentario.
  8. **Sesión caducada:** con el token vencido debe decir que hay que volver a iniciar sesión.

### [2026-08-05]: Release 1.0.0+9 — endurecimiento previo a la publicación

- **Alcance:**
  - `Versión`: `pubspec.yaml` — `1.0.0+8` → `1.0.0+9`. El `+8` ya se usó y Play rechaza un
    `versionCode` repetido.
  - `Tráfico sin cifrar`: `android/app/src/main/AndroidManifest.xml` pierde
    `usesCleartextTraffic="true"`, y `android/app/src/debug/AndroidManifest.xml` lo gana. **No es
    un simple borrado:** quitarlo a secas habría roto el desarrollo local, porque
    `config.json.develop` apunta el emulador a `http://10.0.2.2:8080`. Con el atributo en el
    *source set* de debug, el release queda HTTPS de punta a punta y la depuración sigue igual.
  - `Configuración`: `assets/config/config.json.prod` — sus dos endpoints GraphQL
    (`app.legacynetworkco.com/lso-api` y `/content-api`) respondían **404** con la página de
    mantenimiento de Cloudways. Se alinean con los que sí responden 200 y son los que usa el
    `config.json` activo: `lso.school/graphql` y `legacynetworkco.com/graphql`. Copiar el `.prod`
    sobre el activo dejaba cursos y noticias en blanco.
  - `Tests`: `test/widget_test.dart` — se sustituye la plantilla de contador de `flutter create`
    (buscaba un `0` y un botón `+` inexistentes, y fallaba desde siempre) por tres casos sobre
    `MyApp`: que pinta la ruta inicial del `GoRouter` recibido, que navega al cambiar de ruta y
    que aplica `AppTheme.lightTheme` con la cinta de debug oculta.
  - `Documentación`: `DESPLIEGUE.md` — se retira la discrepancia del `package_name` del `Appfile`,
    resuelta el 2026-08-04, y se reescribe el apartado de cleartext para reflejar el nuevo reparto
    entre `main/` y `debug/`.
  - **Sin cambios en el backend ni en el panel.**
- **Criterios de QA:**
  1. **Suite verde:** `flutter test` → 38 de 38. Antes eran 35 de 36, con `widget_test.dart` en rojo.
  2. **Análisis:** `flutter analyze` → 49 avisos, todos de nivel `info` y preexistentes; ningún
     `error` ni `warning`.
  3. **Release sin cleartext:** tras `./compilar_android.sh`, buscar `usesCleartextTraffic` en
     `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`
     no debe dar ninguna ocurrencia.
  4. **Debug con cleartext:** tras `flutter build apk --debug`, el manifest fusionado equivalente
     de `debug/` **sí** debe llevar `usesCleartextTraffic="true"`.
  5. **Desarrollo local intacto:** copiar `config.json.develop` sobre `config.json`, levantar el
     backend y correr en emulador Android; el login contra `http://10.0.2.2:8080` debe responder.
  6. **Artefacto:** el `.aab` declara `versionCode 9`, `versionName 1.0.0` y `applicationId`
     `co.legacynetwork.legacyapp`; `jarsigner -verify` responde `jar verified`. El aviso sobre la
     cadena de certificados es el esperado en un keystore de upload autofirmado.
  7. **Cursos y noticias:** en la app compilada, las secciones que consumen los GraphQL externos
     deben traer contenido, no quedarse vacías.

### [2026-08-05]: Búsqueda y filtro por categoría en eventos (eventos, fase 2b, opción A)
- **Alcance:**
  - `Filtros`: `lib/domain/utils/event_filters.dart` (nuevo) — `eventsForTab`, `categoriesOf` y `applyEventFilters` como funciones puras, más las constantes `EventTab` y `kTodasLasCategorias`. **Todo se resuelve en el cliente** sobre la lista ya cargada: `GET /api/events` devuelve todos los eventos, no acepta parámetros y no tiene paginación, así que la lista completa ya está en memoria. Si el backend llegara a aceptar `q`, `category`, `from` y `to` (opción B), este archivo es el único punto a reemplazar.
  - `Pantalla`: `lib/presentation/screens/eventos/eventos_screen.dart` — campo de búsqueda bajo la cabecera y fila de categorías bajo las pestañas. La búsqueda mira título, categoría, lugar, conferencista y fecha mostrada, sin distinguir mayúsculas. Las categorías se derivan de los eventos de la pestaña activa, se ocultan si hay menos de dos y se reinician a "Todas" al cambiar de pestaña, porque una categoría de otra pestaña dejaría el listado vacío sin motivo aparente. El estado vacío distingue "no hay nada en esta sección" de "ningún evento coincide con la búsqueda", y en el segundo caso ofrece **Quitar filtros**.
  - `Tests`: `test/utils/event_filters_test.dart` (nuevo) — 15 casos sobre pestañas, categorías y búsqueda, con los mismos tres eventos que hay hoy en producción.
  - **Sin cambios en el backend.**
- **Criterios de QA:**
  1. **Búsqueda por título:** en Eventos, escribir `networking` y comprobar que en Pasados queda solo *Coffee & Networking: CDMX 2026*.
  2. **Búsqueda por lugar y por conferencista:** buscar `méxico` debe encontrar el Coffee & Networking; buscar el nombre de un conferencista debe encontrar su evento aunque no aparezca en el título.
  3. **Filtro por categoría:** la fila de categorías muestra las de la pestaña activa. Al elegir una, solo quedan esos eventos; "Todas" restablece.
  4. **Combinación:** con una categoría elegida, escribir texto acota dentro de esa categoría.
  5. **Sin resultados:** una búsqueda sin coincidencias muestra "Ningún evento coincide con la búsqueda" y el botón **Quitar filtros**, que devuelve el listado completo.
  6. **Cambio de pestaña:** al cambiar de pestaña la categoría vuelve a "Todas" y el listado no aparece vacío.
  7. **Limpiar:** la X del campo de búsqueda borra el texto y restaura el listado.
  8. **Una sola categoría:** si la pestaña activa tiene eventos de una única categoría, la fila de filtros no se muestra.

### [2026-08-05]: Histórico de eventos en la pestaña "Pasados" (eventos, fase 2a)
- **Alcance:**
  - `Modelo`: `lib/domain/models/event_model.dart` — nuevos `startDate` y `endDate` con la fecha sin formatear. `date` llegaba ya convertida a `dd/MM/yyyy`, así que no había forma de comparar ni ordenar. Nuevo `isPast`: un evento es pasado cuando su último día (`end_date`, o `start_date` si no lo hay) quedó atrás; los de hoy siguen en "Próximos" toda la jornada y los que llegan sin fecha utilizable nunca se ocultan. **Las fechas no se convierten a hora local a propósito:** el backend guarda `start_date`/`end_date` como `date` y las serializa a medianoche UTC, de modo que convertirlas en un huso negativo mostraría el día anterior.
  - `Pantalla`: `lib/presentation/screens/eventos/eventos_screen.dart` — "Pasados" deja de estar cableada a lista vacía (`filteredEvents = []; // No past events for now`) y "Próximos" deja de incluir los eventos ya terminados, que hasta ahora aparecían mezclados. El histórico se ordena del más reciente al más antiguo (el backend los devuelve por categoría y fecha ascendente). Un evento finalizado muestra la insignia **FINALIZADO** en gris en vez de "ABIERTO"/"GRATIS" y oculta la nota de preventa.
  - `Provider`: `lib/domain/providers/events_provider.dart` — `registerUserToEvent` reconstruía el `EventModel` a mano y descartaba los campos que no listaba (lugar, conferencista, horario, y ahora también las fechas: un evento pasado habría vuelto a "Próximos" al registrarse). Se reemplaza por un `copyWith`.
  - `Tests`: `test/models/event_model_test.dart` (nuevo) — 9 casos sobre el criterio de fechas y sobre `copyWith`.
  - **Sin cambios en el backend:** `GetEvents` ya devolvía todos los eventos sin filtro de fecha; el histórico se descartaba en el cliente.
- **Criterios de QA:**
  1. **Histórico visible:** abrir Eventos → pestaña **Pasados**. Con los datos de producción de hoy deben verse **dos** eventos: *Coffee & Networking: CDMX 2026* (12/04/2026) primero y *Planificación Patrimonial en la Era Digital* (20/03/2026) después. Antes la pestaña salía siempre vacía.
  2. **Próximos ya no mezcla:** la pestaña **Próximos** debe mostrar **solo** *LEGACY SUMMIT 2026* (15/10/2026). Antes aparecían los tres.
  3. **Orden del histórico:** el más reciente arriba.
  4. **Insignia:** las tarjetas de Pasados muestran `FINALIZADO` en gris, sin "ABIERTO" ni la línea de preventa.
  5. **Evento de hoy:** si se crea desde el panel un evento con fecha de hoy, debe salir en **Próximos**, no en Pasados, durante todo el día.
  6. **Sin regresión al registrarse:** registrarse a un evento desde el detalle y volver al listado; la tarjeta debe conservar fecha y lugar, y el evento no debe cambiar de pestaña.
  7. **Mis registros:** la pestaña sigue mostrando los eventos con registro o recordatorio, sin cambios.

### [2026-08-04]: Login con Google operativo y contraseña del registro social
- **Alcance:**
  - `Firebase`: `android/app/google-services.json` — sustituido por el descargado de la consola. El anterior estaba editado a mano: declaraba el paquete `co.legacynetwork.legacyapp` reusando el app id que Firebase tiene asociado a `com.legacynetworkco.app`, y no existía ningún cliente OAuth de Android para la firma de release. De ahí el `GoogleSignInException [16] Account reauth failed`.
  - `Endpoints`: `lib/data/config/api_constants.dart` (nuevas constantes `socialLoginEndpoint` y `resendVerificationEndpoint`) y `lib/data/services/auth_service.dart` — se llamaba a `/api/auth/social-login` (404 en el backend) y a `/api/resend-verification` (405 en nginx).
  - `Registro social`: `lib/presentation/screens/register_screen.dart` — el formulario pide y valida una contraseña, pero se enviaba `password: null` cuando el registro venía de Google. La cuenta quedaba sin `password_hash` y el login por correo la rechazaba como "Credenciales inválidas".
  - `Publicación`: `android/fastlane/Appfile` — `package_name` alineado con el `applicationId` real (`co.legacynetwork.legacyapp`).
- **Criterios de QA:**
  1. **Sin error de firma:** con el APK de release instalado, pulsar "Iniciar sesión con Google" y elegir una cuenta no debe producir `GoogleSignInException` ni el código 16. Requiere que la huella SHA-1 de la keystore de release esté registrada en Firebase.
  2. **Cuenta nueva:** con un correo no registrado, el flujo debe llevar al formulario de registro con el correo y el nombre ya rellenados y el campo de correo en solo lectura.
  3. **Contraseña guardada:** completar ese registro escribiendo una contraseña y, al terminar, cerrar sesión e **iniciar sesión con ese correo y esa contraseña**. Debe entrar. Antes de este cambio fallaba siempre.
  4. **Doble vía:** la misma cuenta debe poder entrar tanto con Google como con correo y contraseña.
  5. **Cuenta existente:** con un correo ya registrado, el login con Google debe entrar directamente sin pasar por el formulario.
  6. **Reenvío de verificación:** comprobar que la pantalla de verificación de correo reenvía el mensaje sin error de conexión.

---

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
