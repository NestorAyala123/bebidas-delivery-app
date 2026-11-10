# Bloque de identidad y comunicación

Este documento describe el scaffolding inicial de `auth`, `users` y `chat`.
La implementación sigue el monolito modular existente:

```text
presentation -> application -> domain <- infrastructure
```

## 1. Roles y RBAC

| Rol | Capacidades principales | Restricciones |
| --- | --- | --- |
| `client` (Cliente) | Explorar comercios, administrar su perfil, crear pedidos y conversar con participantes de sus pedidos | No administra catálogo, pedidos de otros usuarios ni tarifas de entrega |
| `store` (Comercio) | Administrar perfil comercial, catálogo, disponibilidad, pedidos propios y chat con clientes/repartidores | Solo opera recursos de su comercio |
| `driver` (Repartidor) | Consultar solicitudes, enviar ofertas, gestionar entregas y conversar sobre entregas asignadas | No modifica pedidos ni catálogos de comercios |
| `event_provider` (Proveedor) | Administrar perfil y servicios de eventos, y conversar con clientes interesados | No administra pedidos de bebidas ni entregas |

La enumeración y matriz ejecutable están en
`lib/features/users/domain/entities/role.dart`. Los valores serializados son
parte del contrato: `client`, `store`, `driver`, `event_provider`.

Reglas RBAC obligatorias:

1. El backend valida el JWT y los permisos; la app solo oculta acciones de UI.
2. Los recursos se autorizan por pertenencia (por ejemplo, un comercio solo
   puede operar sus pedidos).
3. Los mensajes solo se leen y envían cuando el usuario es participante de la
   conversación.
4. `refreshToken` se almacena de forma segura y se revoca al cerrar sesión.

## 2. Contrato público de identidad

Los módulos consumidores dependen de `IdentityContract`, no de una
implementación de Firebase o HTTP. La respuesta canónica es:

```json
{
  "data": {
    "id": "usr_123",
    "email": "ana@example.com",
    "displayName": "Ana Pérez",
    "phoneNumber": "+573001112233",
    "role": "client",
    "isActive": true,
    "createdAt": "2026-10-04T14:00:00Z"
  }
}
```

Endpoints:

| Método | Ruta | Uso |
| --- | --- | --- |
| `POST` | `/v1/auth/register` | Crear cuenta y emitir tokens |
| `POST` | `/v1/auth/login` | Autenticar y emitir tokens |
| `POST` | `/v1/auth/refresh` | Rotar el access token |
| `POST` | `/v1/auth/logout` | Revocar la sesión |
| `GET` | `/v1/users/me` | Consultar identidad propia |
| `PATCH` | `/v1/users/me` | Actualizar nombre/teléfono |
| `GET` | `/v1/users/{userId}` | Consultar identidad pública autorizada |

La especificación completa está en
[`docs/openapi/identity-communication.yaml`](./openapi/identity-communication.yaml).

## 3. Estructura implementada

```text
lib/features/
├── auth/
│   ├── application/dtos/auth_dtos.dart
│   ├── application/use_cases/login_use_case.dart
│   ├── application/use_cases/register_use_case.dart
│   ├── domain/entities/user_session.dart
│   ├── domain/repositories/auth_repository.dart
│   └── infrastructure/mock_auth_repository.dart
├── users/
│   ├── application/dtos/profile_dtos.dart
│   ├── application/use_cases/get_profile_use_case.dart
│   ├── application/use_cases/update_profile_use_case.dart
│   └── domain/entities/{role,identity_contract}.dart
└── chat/
    ├── application/dtos/chat_dtos.dart
    └── domain/entities/conversation.dart
```

`MockAuthRepository` permite conectar pantallas sin backend real. Es un
adaptador temporal en memoria y debe sustituirse por una implementación HTTP
o Firebase antes de producción. Los casos de uso validan entrada y devuelven
`Result<S, Failure>`, manteniendo el patrón del repositorio.

## 4. Propuesta de chat

Una conversación tiene un `id`, tipo (`direct` u `order_support`), participantes,
un `orderId` opcional y timestamps. Cada participante contiene `userId`, rol y
fecha de incorporación. El flujo recomendado es:

1. `POST /v1/conversations` con dos o más participantes.
2. El servidor comprueba que el solicitante puede conversar con cada
   participante y crea la conversación idempotentemente.
3. `POST /v1/conversations/{conversationId}/participants` agrega participantes
   autorizados (por ejemplo, el repartidor asignado).
4. `POST /v1/conversations/{conversationId}/messages` persiste y publica el
   mensaje.
5. `GET /v1/conversations/{conversationId}/messages` pagina el historial;
   WebSocket queda como transporte opcional para tiempo real.

Formato base de mensaje:

```json
{
  "id": "msg_123",
  "conversationId": "cnv_123",
  "senderId": "usr_123",
  "type": "text",
  "text": "Tu pedido está listo",
  "createdAt": "2026-10-04T14:05:00Z",
  "readAt": null
}
```

Tipos futuros (`image`, `location`, `system`) deben conservar `text` nulo o
vacío según el esquema de versión que se publique.

## 5. Semana 3: perfiles, autorización y mensajes de texto

Perfiles (`users`):

- `UpdateProfileUseCase`: solo el dueño (`requester.id == userId`) con permiso
  `profile:update:own`. Nombre de 2 a 60 caracteres; teléfono opcional de 7 a 15
  dígitos (puede iniciar con `+`); un teléfono en blanco lo elimina.
- `GetProfileUseCase`: el dueño ve su identidad completa; cualquier otro usuario
  autenticado recibe `IdentityContract.toPublic()` (sin correo ni teléfono).
- `ListContactsUseCase`: identidades públicas con las que se puede conversar.
- `InMemoryUserRepository` es la fuente de verdad de `AppUser`; `MockAuthRepository`
  solo guarda credenciales, así que un cambio de perfil sobrevive a un nuevo login.

Chat (`chat`):

- `CreateConversationUseCase`: exige `chat:conversation:create`, que el solicitante
  sea participante, sin repetidos ni desconocidos. Los roles de los participantes
  se toman de la identidad, no de la solicitud. Es idempotente.
- `SendMessageUseCase`: exige `chat:message:send`, remitente = solicitante, ser
  participante, texto entre 1 y 1000 caracteres (solo `type: text`).
- `WatchMessagesUseCase` / `ListConversationsUseCase`: la lectura se restringe a
  participantes; una conversación ajena y una inexistente responden igual.
- Rutas: `/chat` (lista y "Nueva conversación") y `/chat/room` (mensajes).
  `InMemoryChatRepository` debe sustituirse por Firestore con reglas equivalentes.

## 6. Semana 4: chat cliente-comercio y cliente-proveedor, acceso y sesión

Tipos de conversación (`ConversationType`):

| Tipo | Participantes | Asunto obligatorio |
| --- | --- | --- |
| `storeInquiry` | cliente ↔ comercio | `subjectId` = `storeId` |
| `serviceInquiry` | cliente ↔ proveedor de eventos | `subjectId` = `serviceId` |
| `orderSupport` | cliente/comercio/repartidor (no proveedor) | `orderId` |
| `direct` | cliente↔comercio, cliente↔proveedor, cliente↔repartidor, comercio↔repartidor | — |

Control de acceso:

- `ConversationPolicy` (dominio) decide qué pares de roles pueden conversar.
  `CreateConversationUseCase` la aplica con los roles **verificados** por el
  módulo de identidad; los roles que envía el cliente se ignoran.
- `OpenInquiryChatUseCase.forStore` / `.forService`: solo un cliente puede
  iniciarlas. El otro participante **no lo elige el cliente**: se resuelve con
  el puerto `ChatCounterpartDirectory` (`storeId → Store.ownerId`,
  `serviceId → FichaServicio.providerId`). Son idempotentes por asunto: el
  mismo cliente y comercio reabren la misma conversación.
- Si el comercio o proveedor no tiene cuenta, se informa "todavía no tiene una
  cuenta para chatear" en lugar de crear un chat huérfano.
- Lectura y envío siguen restringidos a participantes (semana 3).
- La lista de "Nueva conversación" solo muestra contactos permitidos por la
  política.

Integración con otros módulos (cambios mínimos, para revisión de cada dueño):

- `ChatLauncher.openStoreChat` / `.openServiceChat` es el punto de entrada
  público. Se usa en el botón "Chatear con el comercio" del mapa
  (`mapa_proximo_page.dart`) y en "Contactar Chat" de la ficha
  (`detalle_ficha_page.dart`).
- `store_management_page.dart` guarda como `ownerId` el usuario con sesión y
  `publicar_ficha_page.dart` guarda como `providerId` el usuario con sesión
  (antes eran textos fijos y el chat no podía encontrar a la persona).
- `DemoChatLinks` enlaza los datos de prueba sin cuenta (comercios del mapa
  `store-00x` y fichas `prov-00x`) con `comercio@demo.com` y
  `eventos@demo.com`. Es solo para desarrollo; con Firestore se elimina.

Estados de sesión:

- `SessionGate` protege `/chat` y `/chat/room`: escucha `AuthController`; al
  cerrar sesión la pantalla pasa a "Tu sesión no está activa" y al entrar con
  otra cuenta se vuelve a comprobar el acceso desde cero (un usuario que no
  participa ve "No participas en esta conversación").
- `currentIdentity()` expone la identidad con sesión a otros módulos.
- `AuthController.logout()` limpia error y carga; los errores de login se
  muestran con el mensaje legible del `Failure`.
- El cierre de sesión de `HomePage` ahora cierra la sesión de verdad (antes
  solo navegaba a la bienvenida).

Recorrido de demostración:

1. Entrar como `cliente@demo.com` / `cliente123`, volver a la bienvenida y abrir
   "Servicios para Eventos" → una ficha → "Contactar Chat"; escribir un mensaje.
2. Desde "Ver mapa de comercios cercanos", tocar un comercio → "Chatear con el
   comercio".
3. Cerrar sesión y entrar como `eventos@demo.com` / `eventos123` o
   `comercio@demo.com` / `comercio123` → Perfil → Mensajes: aparece la
   conversación con el asunto y se puede responder.
4. Entrar como `repartidor@demo.com`: no ve esas conversaciones.

Pruebas: `test/features/chat/inquiry_chat_test.dart` (política, apertura,
idempotencia, roles, intrusos) y `test/features/chat/chat_session_states_test.dart`
(logout, cambio de cuenta, bandeja con asunto).

## 7. Semana 5: chat completo, acceso desde comercio y servicios, avisos

Leídos y no leídos:

- `ChatRepository` guarda hasta cuándo leyó cada participante
  (`markAsRead` / `lastReadAt`) y publica `changes` cuando se envía o se lee
  un mensaje.
- `MarkConversationReadUseCase`: solo un participante puede marcar como leído.
  `ChatPage` lo llama al abrir el chat y con cada mensaje que ve.
- `ListConversationsUseCase` devuelve el último mensaje (`lastMessage`) y los
  no leídos (`unreadCount`). Los mensajes propios nunca cuentan como no leídos.
- La bandeja (`/chat`) se actualiza sola: muestra vista previa ("Tú: …"), hora,
  título en negrita y contador cuando hay mensajes sin leer.

Aviso de mensajes nuevos dentro de la app (sin notificaciones push):

- `WatchUnreadMessagesUseCase`: flujo en vivo con el total de no leídos y el
  mensaje más reciente, calculado **solo** con las conversaciones del usuario.
- `ChatInboxButton`: ícono "Mensajes" con contador para cualquier barra
  superior. Si su pantalla es la visible y llega un mensaje nuevo, muestra
  "Nuevo mensaje: …" con la acción **Ver**. Al cerrar sesión el contador se
  limpia; si el módulo de chat no está registrado (pruebas aisladas de otros
  módulos) no se dibuja.

Acceso desde comercio y servicios:

| Pantalla | Módulo | Cambio |
| --- | --- | --- |
| `orders/.../store_orders_page.dart` (Pedidos del comercio) | Pedidos | `ChatInboxButton` en la barra |
| `stores/.../store_management_page.dart` (Mis comercios) | Comercios | `ChatInboxButton` en la barra |
| `event_services/.../mis_consultas_page.dart` (Mis consultas) | Servicios | `ChatInboxButton` en la barra |
| `auth/.../profile_page.dart`, `home_page.dart` | Identidad | Botón con contador, opción "Mensajes" y botón "Mi panel" en el perfil |

- `OpenInquiryChatUseCase.forServiceCustomer` / `ChatLauncher.openServiceCustomerChat`:
  el proveedor abre el chat con el cliente de una consulta. Solo si el
  servicio es suyo, y reutiliza la conversación que abrió el cliente.

Pendiente de coordinar con Adriano: la tarjeta de "Mis consultas" abre
`_ConsultaChatSheet`, un chat local de demostración ("Chat con Nibia") cuyos
mensajes no se guardan ni pasan por el control de participantes. Para usar el
chat real basta reemplazar `_openChat` por
`ChatLauncher.openServiceChat(context, serviceId: consulta.serviceId, serviceTitle: consulta.serviceTitle)`
(cliente) u `openServiceCustomerChat(...)` (proveedor), y ajustar su prueba de
widget. Además, `customerId` usa por defecto `'customer-demo'`, que no es una
cuenta real.

Pruebas: `test/features/chat/unread_messages_test.dart` (no leídos, lectura
solo por participantes, aviso en vivo, proveedor → cliente) y
`test/features/chat/chat_inbox_button_test.dart` (contador, aviso, cierre de
sesión, sin módulo de chat).

## Evidencia sugerida para el PR

```bash
flutter analyze
flutter test
```

Capturar además una respuesta `POST /v1/auth/register`, una consulta
`GET /v1/users/me` y una conversación con sus participantes. La integración
real de persistencia, hash de contraseñas, firma JWT y WebSocket queda fuera
de este scaffolding.
