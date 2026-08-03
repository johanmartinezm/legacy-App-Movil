# Plan de Integración de Pagos CredibanCo (IPay)

Este documento detalla el inventario de puntos de contacto ("touchpoints") del sistema de pagos y define los cambios arquitectónicos necesarios en todas las capas del stack tecnológico (Backend, App Móvil y Dashboard Administrativo) para conectarse nativamente al ambiente de pruebas de CredibanCo.

---

## 1. Puntos de Contacto Actuales (Touchpoints Identificados)

Tras auditar el código fuente, se identificaron los siguientes flujos donde el ecosistema interactúa con pagos (que actualmente están en estado *Mock* o simulado):

### 1.1. App Móvil (Flutter)
- **`App-Movil/lib/presentation/screens/eventos/event_payment_screen.dart`**: Pantalla de confirmación para Eventos. El botón "PROCEDER AL PAGO" despliega actualmente un pop-up de éxito inmediato.
- **`App-Movil/lib/presentation/screens/cart/checkout_screen.dart`**: Pantalla del carrito de compras. Simula la selección de método de pago (incluyendo "PSE") y redirige al instante a la confirmación de la orden.
- **`App-Movil/lib/presentation/widgets/eventos/qr_attendance_dialog.dart`**: Gestiona alertas de negocio. Si un usuario intenta generar su código de acceso y el sistema arroja el error `PAGO_PENDIENTE`, se le insta a completar el pago.

### 1.2. Sitio Administrativo (Angular)
- **`Sitio-Administrativo/src/app/features/admin/registrations/registration-wizard/registration-wizard.component.html`**: Durante la pre-inscripción manual por parte de un administrador, el Paso 3 indica `Método de Pago (Simulado)`.

---

## 2. Cambios Necesarios a Nivel de Arquitectura

Para habilitar la pasarela IPay de CredibanCo, el sistema debe evolucionar hacia un modelo de **Web Checkout**. Esto evita tener que manejar tarjetas directamente en el código de la app, delegando esa responsabilidad a CredibanCo, lo que simplifica la certificación de seguridad.

### 2.1. Base de Datos (PostgreSQL)
Es imprescindible agregar una capa de persistencia para trazabilidad:
- **Nueva tabla transaccional (`transactions`)**:
  - `id` (UUID, Primary Key)
  - `user_id` (Relación con el usuario)
  - `reference_type` (Enum: 'EVENT', 'CART') - Para saber qué se está pagando.
  - `reference_id` (UUID) - ID de la orden interna o del evento.
  - `amount` (Decimal)
  - `credibanco_order_id` (String) - Código identificador devuelto por el banco.
  - `status` (Enum: PENDING, APPROVED, DECLINED, FAILED)
  - `created_at`, `updated_at`

### 2.2. Backend (Go - Orquestador Central)
El backend asume la responsabilidad de comunicarse de forma segura con CredibanCo.
1. **CredibanCo Service (`services/credibanco_service.go`)**:
   - `CreateOrder`: Se comunica con el endpoint `ecouat.credibanco.com/payment/rest/register.do` usando el `Usuario API` y la `Clave` provistos. Recibe y devuelve el `formUrl` seguro.
   - `GetOrderStatus`: Consulta `ecouat.credibanco.com/payment/rest/getOrderStatusExtended.do` pasándole el Order ID para validar el estatus real de la transacción (Aprobado/Rechazado).
2. **Nuevos Endpoints (`controllers/payment_controller.go`)**:
   - `POST /api/payments/intent`: Registra el pago en estado `PENDING` en nuestra BD y retorna el `formUrl` de CredibanCo al Frontend.
   - `GET /api/payments/verify/:order_id`: Endpoint clave de verificación que actualiza la BD de acuerdo a la respuesta oficial del banco y despacha las operaciones de negocio (ej. otorgar la entrada al evento).

### 2.3. App Móvil (Flutter)
Para conectar con la pasarela, Flutter actuará como consumidor del backend.
1. **Lanzador de Pasarela (Web Checkout)**:
   - Al tocar "Proceder al Pago", la app llama a `/api/payments/intent` y obtiene el `formUrl`.
   - La app abre este enlace utilizando `url_launcher` (navegador in-app) o `webview_flutter`. El usuario realiza el pago directamente en la pantalla de CredibanCo.
2. **Deep Linking (Retorno a la App)**:
   - Al terminar el flujo bancario, CredibanCo redirige al usuario a una URL proporcionada por nosotros (Ej. `legacyapp://payment-callback?orderId=xyz`).
   - Se configurará Flutter para interceptar este App Link, cerrar el WebView, llamar a `/api/payments/verify` y finalmente mostrar dinámicamente la pantalla de Éxito o Fallo sin intervención manual.

### 2.4. Sitio Administrativo (Angular)
1. **Reemplazo del Mock en el Asistente**:
   - Actualizar el Wizard para llamar a `/api/payments/intent` si se requiere cobrar online desde el panel de control.
2. **NUEVO: Dashboard de Estados de Transacciones**:
   - **Factibilidad**: ¡Totalmente factible y recomendado! Es esencial para el servicio al cliente.
   - **Desarrollo requerido**:
     - En el backend (Go): Un endpoint `GET /api/admin/transactions` con soporte para paginación y filtros.
     - En Angular: Creación del componente `TransactionsDashboardComponent` utilizando Angular Material (Tablas).
   - **Funcionalidades Clave de esta pantalla**:
     - Visualización global del histórico (Semáforo de colores: Verde = Aprobado, Naranja = Pendiente, Rojo = Rechazado).
     - Filtros por correo electrónico de usuario y número de orden.
     - **Botón de Verificación Manual (Sincronizar)**: Permite a un administrador forzar una consulta al backend (`GetOrderStatus`) hacia CredibanCo en caso de que la transacción haya quedado en el limbo (por ejemplo, si el usuario cerró su celular en medio de la transacción sin que se ejecutara el Deep Link de retorno).

---

## 3. Estrategia de Trabajo Propuesta (Sin inicio de código actual)

1. **Fase 1**: Modelado de BD en PostgreSQL y desarrollo del cliente REST en Go apuntando a los URLs de `ecouat`.
2. **Fase 2**: Integración de Deep Links y WebViews en el ecosistema de Flutter.
3. **Fase 3**: Creación de la pantalla de Monitoreo de Transacciones en el Dashboard de Angular.
