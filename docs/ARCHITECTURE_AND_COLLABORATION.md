# Guía de Arquitectura y Trabajo Colaborativo (5 Desarrolladores)

## 1. Flujo de Git y Ramas

```
main (Producción)
  └── develop (Integración)
        ├── feature/auth-users-chat        (Nibia)
        ├── feature/stores-products        (Wendy)
        ├── feature/cart-orders            (David)
        ├── feature/location-services      (Adriano)
        └── feature/delivery-offers        (Néstor)
```

- **Regla de oro**: Nadie hace push directo a `main` ni a `develop`.
- Todo cambio se integra a `develop` mediante **Pull Request** revisado.
- Cada integrante trabaja principalmente dentro de su rama de feature asignada.

---

## 2. Responsabilidad por Integrante

| Integrante | Módulos Asignados | Rama de Trabajo | Alcance Funcional |
|---|---|---|---|
| **Nibia** | `auth`, `users`, `chat` | `feature/auth-users-chat` | Registro, Login, Logout, Perfil, Roles (cliente, comercio, repartidor, eventos), Chat en tiempo real. |
| **Wendy** | `stores`, `products`, `pricing`, `returnable_containers` | `feature/stores-products` | Comercios, Horarios, Catálogo, Disponibilidad, Precios escalonados (RN04), Envases retornables (RN05). |
| **David** | `cart`, `orders` | `feature/cart-orders` | Carrito unitienda (RN07), Creación de pedido, Precios congelados (RN08), Estados del pedido, Confirmación (RN01). |
| **Adriano** | `location`, `event_services` | `feature/location-services` | GPS, Permisos, Mapas, Distancias (Haversine), Comercios cercanos, Servicios para eventos. |
| **Néstor** | `delivery`, `delivery_offers`, `ratings` | `feature/delivery-offers` | Modalidades de entrega (RN02), Negociación de ofertas y cierre automático (RN06), Alternativas si no hay choferes (RN03), Calificaciones. |

---

## 3. Arquitectura por Módulo (4 Capas)

Cada módulo funcional se estructura en:

```
features/<modulo>/
├── domain/            # 100% puro Dart: entities, repositories (interfaces), value objects, domain services, exceptions.
├── application/       # Use Cases y servicios de aplicación.
├── infrastructure/    # Firebase, Firestore, DTOs, Mappers, Repositorios implementados, GPS, HTTP.
└── presentation/      # Widgets, Pages, Controllers, State.
```

### ⚠️ Reglas estrictas de `domain`:
- **PROHIBIDO** importar: Firebase, Cloud Firestore (`DocumentSnapshot`, `Timestamp`), Flutter widgets (`BuildContext`, `Widget`), `geolocator`, `flutter_map`, HTTP.
- Debe probarse con pruebas unitarias independientes sin emulador ni Firebase.

---

## 4. Comunicación entre Módulos y Cero Conflictos de Merge

1. **Evitar dependencias directas de infraestructura**:
   - `delivery` NUNCA importa `orders/infrastructure/...`.
   - La comunicación se realiza mediante **contratos públicos** en `domain/contracts/` (ejemplo: `OrderDeliveryContract`, `LocationServiceContract`).
2. **Rutas Desacopladas (`FeatureRouteModule`)**:
   - Cada feature declara sus rutas implementando `FeatureRouteModule`.
   - `AppRouter` solo las registra sin que nadie tenga que editar el router global.
3. **Inyección de Dependencias Desacoplada (`FeatureDiModule`)**:
   - Cada feature registra sus casos de uso e infraestructura implementando `FeatureDiModule`.
   - Nadie tiene que tocar `injection_container.dart` cada vez que crea un Use Case.
