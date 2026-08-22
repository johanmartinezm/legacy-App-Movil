# Plan de trabajo: revisión de QA de Diana Uribe (LSO)

Fuente: `docs/Experiencia APP Diana Uribe.docx`, recibido el 22-08-2026, con
`docs/Libros - LSO.xlsx` como material de apoyo para uno de los puntos. Las dos imágenes
adjuntas al docx no se revisaron.

Cada punto de Diana quedó clasificado en una de cuatro categorías: ya arreglado, ya
conocido, técnico por investigar, o producto/contenido. Los dos primeros no necesitan
trabajo nuevo aquí; se listan para que quede constancia de que se revisaron y por qué no
generan una tarea.

## Ya arreglado el mismo 22-08, antes de que llegara este documento

- **«Al escribir en el chat no se ve la letra, está muy clara»** y **«las opciones de los
  botones del asistente no se pueden leer».** Es el bug de tema claro del Asistente
  (`chatbot_screen.dart`): el `TextField` no fijaba color de texto y heredaba el blanco
  del tema global forzado a oscuro, así que se escribía en blanco sobre un fondo blanco.
  Arreglado y probado en el teléfono el 22-08. Falta que llegue a producción: no se ha
  publicado build nuevo desde entonces.

## Ya conocidos, sin trabajo nuevo que abrir aquí

- **Pago del Summit que no conecta** («la plataforma de pago no estaba disponible»,
  cupo quedó reservado) → pasarela de CredibanCo, bloqueada del lado del banco. No se
  toca hasta que CredibanCo resuelva su acceso.
- **Foro publicado sin pasar por aprobación real**, aunque la pantalla prometa revisión
  → es F16.3 del plan de 226 casos, ya documentado como caso rojo que espera decisión del
  cliente (¿se implementa aprobación real, o se retira el texto que promete revisión?).
  Diana lo confirma de forma independiente desde su propia cuenta.
- **Términos y condiciones ilegibles en modo oscuro** → ya está en la lista de bugs
  menores abiertos (enlaces legales azul oscuro sobre fondo oscuro).

## Parte técnica — resuelto el 22-08-2026

1. **✓ «Tipo de identificación» sin variantes LATAM.** Nuevo
   `domain/utils/identificacion_empresarial.dart`: 17 países LATAM, cada uno con su
   documento tributario real (RFC México, RUC Perú, RUT Chile, CUIT Argentina...).
   Colombia conserva Cédula/Tarjeta de identidad junto a NIT, para el caso de un
   negocio unipersonal. El país en sí también pasó de ser binario
   (Colombia/Otro) a la lista completa. 5 pruebas nuevas.

2. **✓ «Estado de Cliente/Alumni» no se entendía.** Se agregó `helperText`: «¿Ya eres
   cliente o alumni de alguna de estas unidades de Legacy?».

3. **Dejado para la parte de producto — «Intereses» limitado a dos opciones.**
   Confirmado en código (`register_screen.dart:444`): la lista completa es
   literalmente `['Gobierno corporativo', 'Familia empresaria']`. No hay ninguna lista
   de categorías en el resto del código de la que deducir cuáles faltan — inventarlas
   sería adivinar contenido, así que se movió a la sección de producto, más abajo.

4. **✓ «Red de gobierno»: el error al contactar era el texto crudo del backend.**
   La pantalla es «Miembros» (`community_members_screen.dart`, menú Perfil → «Red de
   Gobierno» → `/comunidad-miembros`). No hay ninguna restricción de rol ni de estado
   de cliente para invitar a alguien —cualquier cuenta puede—: lo que fallaba era el
   mensaje. Mostraba literal `"Error: Exception: connection already exists or is
   pending"`, sin traducir. Ahora traduce los tres motivos reales del backend
   (`chat_service.go:41-61`): conexión ya existe/pendiente, bloqueado, o invitarse a
   sí mismo.

5. **✓ Ícono del asistente inconsistente.** Confirmado: `Icons.psychology_outlined`
   en el botón flotante de Inicio, `Icons.headphones_outlined` en el de Legacy
   Knowledge — mismo botón, mismo destino (`/chatbot`). Unificado al de Inicio.

6. **Investigado y descartado como bug — Legacy+ «no me reconoce como comunidad».**
   `legacy_plus_screen.dart` es una pantalla puramente informativa: no importa
   `AuthProvider` ni ningún otro provider, no tiene ninguna condición de rol ni de
   estado de cliente. El único elemento tocable de toda la pantalla es la flecha de
   atrás — no hay botón de «activarme», «contactar ventas» ni nada que lleve a ningún
   lado. No es que la cuenta de Diana no califique: la pantalla no ofrece ninguna
   acción, para nadie. Se movió a la parte de producto: falta decidir qué acción debe
   existir ahí.

7. **Dejado para la parte de producto — Favoritos no es descubrible.** Se confirma que
   la función funciona bien (ver más abajo, tramo 5 del plan de pruebas): es
   alcanzable por el menú «⋮» → «Artículos guardados» dentro del detalle de un
   artículo, pero no hay ningún acceso visible desde el Inicio ni el menú lateral.
   Dónde ubicar ese acceso es una decisión de diseño, no un bug — se mueve a la
   sección de producto.

Detalle de la verificación (tests, `flutter analyze`, instalación en el teléfono) en
`qa_bitacora.md`, entrada del 22-08 «Parte técnica de la revisión de Diana Uribe (LSO)».

## Parte de producto/contenido — decisiones que no son código

1. **«Intereses» del registro, solo dos opciones.** Ver punto 3 de la parte técnica:
   falta que el cliente diga qué temas completos debería ofrecer esa lista.

2. **Qué acción debe tener Legacy+.** Ver punto 6 de la parte técnica: hoy la pantalla
   no tiene ningún botón que lleve a activarse ni a contactar ventas. Falta decidir
   qué debe pasar al tocarla — ¿un enlace a WhatsApp, un formulario, un correo?

3. **✓ Dónde ubicar el acceso a Favoritos — resuelto el 22-08.** Se agregó «Mis
   favoritos» como primera fila de la lista de Perfil (`profile_screen.dart`), con
   acceso directo a `/favorites`. Ver `qa_bitacora.md`, entrada «Favoritos gana acceso
   propio en Perfil».

5. **Libros de LSO vacíos.** Confirmado en código (`graphql_service.dart:69-71`): la
   app consulta correctamente `products(category: "libros")` contra el WooCommerce de
   `lso.school` y pinta lo que llegue — la categoría está vacía en producción, no hay
   ningún fallo de la app. `Libros - LSO.xlsx` trae los 5 libros completos (título,
   autores, descripción, SEO, precio, portada, enlaces a LSO/Amazon/ICONTEC) listos
   para cargar. **Acción:** alguien con acceso al WooCommerce de LSO sube los 5
   productos a la categoría «libros». No requiere ningún cambio en este repositorio.

6. **✓ Restructurar Programas — resuelto el 22-08.** De los 8 títulos que trajo la
   propuesta de Diana, solo 4 existían tal cual en la tienda real de LSO (comprobado
   contra el GraphQL); se usaron los 2 que tenían un programa real bajo otro nombre y se
   dejaron fuera los 2 sin ningún programa parecido, en vez de mostrar tarjetas sin
   destino — decisión del usuario. Quedaron 3 secciones (EUDE, actualización,
   in-company) y cada fila abre directo la página de pago en `lso.school`, sin pantalla
   de detalle intermedia. Ver `qa_bitacora.md`, entrada «Programas se restructura en 3
   secciones».

7. **✓ «Nuevo cada semana» — resuelto el 22-08, con alcance mínimo por decisión del
   usuario.** Se quitó el título completo del artículo y el destino puntual; el
   subtítulo quedó en el texto genérico por rol que ya existía como respaldo, y el
   toque lleva siempre a Legacy Knowledge. No se construyó el resumen real
   multi-fuente (eventos + contenido + programas) que proponía Diana — eso sigue
   pendiente si se quiere ir más lejos. Invalida F9.5 del plan de 226 casos, anotado
   ahí. Ver `qa_bitacora.md`, entrada «"Nuevo cada semana" deja de agotar el artículo
   ahí mismo».

8. **✓ Aprovechar el celular pedido al inscribirse a un evento — resuelto el 22-08.**
   Decisión del usuario: actualiza el perfil sin preguntar. Si el teléfono escrito en
   el formulario de inscripción es distinto al del perfil, se guarda ahí también tras
   confirmar el registro. No bloquea la inscripción si la sincronización falla.
   Comprobado de punta a punta en producción, incluso con la pasarela de pago caída.
   Ver `qa_bitacora.md`, entrada «Corregir el teléfono al inscribirse a un evento
   actualiza el perfil».

9. **✓ Descripción en la ficha de evento — resuelto el 22-08, y no era lo que parecía.**
   El campo ya existía, ya se mostraba, y el Legacy Summit ya tenía una descripción
   real en producción — comprobado contra `GET /api/events`. Lo que de verdad faltaba
   era un rótulo «DESCRIPCIÓN»: sin título, el párrafo no se leía como tal. De paso se
   corrigió el texto de respaldo, que era del propio Summit y aparecía igual en
   cualquier evento sin descripción. Ver `qa_bitacora.md`, entrada «La descripción del
   evento ya existía; le faltaba el rótulo».

10. **✓ Textos de «Foros anónimos» — resuelto el 22-08.** Decisión del usuario:
    arreglar el texto ya, sin esperar a que se decida si se construye la aprobación
    real (F16.3 sigue abierta tal cual, solo se dejó de prometer una revisión que no
    pasa). Se agregó también una explicación de qué son los foros anónimos, ausente
    hasta ahora. Comprobado en producción de punta a punta, incluido el aviso de
    éxito real. Ver `qa_bitacora.md`, entrada «Los foros dejan de prometer una
    revisión que no existe».

11. **Imagen de bienvenida de la pantalla de ingreso.** Diana sugiere una foto de los
    profesores de Legacy en vez de la actual — decisión de contenido/branding.

## Cómo seguir

**Parte técnica: cerrada.** De los siete puntos que arrancaron como técnicos, cuatro se
arreglaron con código el mismo 22-08 (identificación LATAM, ayuda de Cliente/Alumni,
ícono del asistente, mensaje de «Red de Gobierno») y tres resultaron ser, al
investigarlos, decisiones de producto — se movieron a esa sección.

**Parte de producto: 7 de 11 resueltos el 22-08.** Los 4 que quedan están cada uno
esperando un insumo concreto, no una decisión abstracta:

- **Punto 1, Intereses del registro** — espera la lista de temas.
- **Punto 2, acción de Legacy+** — espera decidir qué botón agregar (WhatsApp,
  formulario, correo).
- **Punto 5, libros de LSO** — espera que alguien con acceso al WooCommerce de LSO
  suba los 5 productos; no toca este repositorio.
- **Punto 11, imagen de bienvenida** — espera la foto de los profesores de Legacy.

---
**Fecha de creación:** 2026-08-22
**Estado:** Parte técnica cerrada. 7 de 11 puntos de producto resueltos. Los 4 que
quedan esperan un insumo concreto del cliente (contenido, decisión o archivo), listado
arriba.
