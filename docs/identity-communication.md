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

## Evidencia sugerida para el PR

```bash
flutter analyze
flutter test
```

Capturar además una respuesta `POST /v1/auth/register`, una consulta
`GET /v1/users/me` y una conversación con sus participantes. La integración
real de persistencia, hash de contraseñas, firma JWT y WebSocket queda fuera
de este scaffolding.
