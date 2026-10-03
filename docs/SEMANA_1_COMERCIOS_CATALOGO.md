# Evidencia de Semana 1: comercios y catálogo

**Proyecto:** Aplicación móvil de bebidas, delivery y servicios para eventos  
**Responsable:** Wendy  
**Módulos:** `stores`, `products`, `price_rules` y `returnable_containers`  
**Tecnología prevista:** Flutter, Dart, Firebase Authentication, Cloud Firestore y Firebase Storage

> Este documento se basa en el documento del proyecto y en la estructura actual del repositorio. Las decisiones que no están expresamente definidas se identifican como **propuesta** o **pendiente de definir**.

## 1. Objetivo del módulo

Permitir que un usuario con rol de licorería o comercio registre su establecimiento y administre un catálogo básico de bebidas. El catálogo debe mostrar precios, descuentos por cantidad, disponibilidad e información de envases retornables. Los clientes podrán consultar comercios abiertos y sus productos para crear pedidos.

El documento del proyecto incluye en el MVP la gestión de comercios, catálogo, precios por cantidad y manejo básico de envases retornables. También indica que el comercio puede registrar nombre, dirección, ubicación, horario, teléfono, imagen y descripción.

## 2. Entidades definidas

### `stores`

Representa una licorería o comercio que publica bebidas en la aplicación. Sirve para identificar el establecimiento, mostrarlo a los clientes y controlar si puede recibir nuevos pedidos. Se relaciona con un usuario responsable y contiene varios productos.

### `products`

Representa una bebida publicada por un comercio. Sirve para mostrar el catálogo, consultar el precio base, la disponibilidad, la imagen y la información necesaria para agregar el producto a un pedido. Cada producto pertenece a un solo comercio, de acuerdo con RN07.

### `price_rules`

Representa un precio especial que se aplica cuando el cliente compra una cantidad mínima de unidades. Sirve para implementar RN04: el comercio define rangos o umbrales y el sistema selecciona automáticamente el precio que corresponde a la cantidad.

### `returnable_containers`

Representa la configuración del envase retornable asociado a un producto. Sirve para indicar si el producto requiere envase y cuál es el valor de garantía por cada envase faltante. En la compra, el cliente informa cuántos envases vacíos entrega y solo se cobra la diferencia, según RN05.

## 3. Campos mínimos para el MVP

### Convenciones

- `string`, `boolean`, `number`, `timestamp`, `geopoint`, `map` y `array` son tipos compatibles con Cloud Firestore.
- El ID de un documento no necesita almacenarse como un campo adicional; se obtiene de `DocumentSnapshot.id`.
- **Definido** significa que aparece en el documento del proyecto o ya está reflejado en el dominio del repositorio.
- **Propuesta** significa que es necesario para implementar una función, pero todavía debe ser validado con el equipo o docente.

### `stores`

| Campo | Tipo de dato | Obligatorio | Descripción | Ejemplo |
|---|---|---:|---|---|
| `name` | string | Sí | Nombre comercial del establecimiento. **Definido.** | `"Licorería La Esquina"` |
| `description` | string | No | Descripción breve del comercio. **Definido.** | `"Bebidas frías y atención nocturna"` |
| `address` | string | Sí | Dirección que verá el cliente. **Definido.** | `"Av. 4 de Noviembre y Calle 12"` |
| `location` | geopoint | Sí | Coordenadas para ubicación y comercios cercanos. **Definido en alcance; formato propuesto.** | `(-0.95, -80.72)` |
| `openingHours` | map | Sí | Horario semanal. **Definido; estructura propuesta.** | `{ "monday": { "open": "09:00", "close": "22:00" } }` |
| `phone` | string | Sí | Teléfono de contacto. **Definido.** | `"0991234567"` |
| `imageUrl` | string | No | URL de la imagen del comercio en Storage. **Definido; almacenamiento propuesto.** | `"https://.../stores/store-1.jpg"` |
| `isOpen` | boolean | Sí | Estado actual para aceptar nuevos pedidos. **Definido por RF05.** | `true` |
| `deliveryModes` | map | Sí | Modalidades habilitadas: delivery propio, repartidor de plataforma y retiro. **Definido por RN02; forma propuesta.** | `{ "own": true, "platform": true, "pickup": true }` |
| `ownerId` | string | Sí | ID del usuario responsable del comercio. **Propuesta necesaria para permisos.** | `"user-123"` |
| `createdAt` | timestamp | Sí | Fecha de creación. **Propuesta técnica.** | `Timestamp.now()` |
| `updatedAt` | timestamp | Sí | Fecha de última modificación. **Propuesta técnica.** | `Timestamp.now()` |

### `products`

| Campo | Tipo de dato | Obligatorio | Descripción | Ejemplo |
|---|---|---:|---|---|
| `storeId` | string | Sí | ID del comercio propietario. **Definido por RN07.** | `"store-1"` |
| `name` | string | Sí | Nombre comercial del producto. | `"Cerveza six-pack"` |
| `description` | string | No | Presentación o descripción del producto. | `"Lata de 355 ml, paquete de 6"` |
| `basePrice` | number | Sí | Precio unitario cuando no aplica una regla por cantidad. | `10.0` |
| `isAvailable` | boolean | Sí | Indica si el producto puede agregarse a un pedido. | `true` |
| `imageUrl` | string | No | URL de la imagen del producto en Storage. **Propuesta de implementación.** | `"https://.../products/prod-1.jpg"` |
| `createdAt` | timestamp | Sí | Fecha de creación. **Propuesta técnica.** | `Timestamp.now()` |
| `updatedAt` | timestamp | Sí | Fecha de última modificación. **Propuesta técnica.** | `Timestamp.now()` |

La entidad Dart actual ya contempla `storeId`, `name`, `description`, `basePrice`, `isAvailable`, `isReturnableContainer`, `containerDepositPrice` y `quantityTiers`. Al implementar Firestore, la configuración de envase y las reglas pueden persistirse en sus colecciones relacionadas para separar responsabilidades.

### `price_rules`

| Campo | Tipo de dato | Obligatorio | Descripción | Ejemplo |
|---|---|---:|---|---|
| `productId` | string | Sí | ID del producto al que aplica la regla. | `"prod-1"` |
| `minQuantity` | number entero | Sí | Cantidad mínima para activar el precio. | `6` |
| `unitPrice` | number | Sí | Precio unitario desde ese umbral. | `9.0` |
| `isActive` | boolean | Sí | Permite activar o desactivar la regla sin borrarla. **Propuesta.** | `true` |

Se propone usar `minQuantity` y no almacenar `maxQuantity`: el sistema ordena las reglas por `minQuantity` descendente y escoge la primera cuyo mínimo sea menor o igual a la cantidad solicitada. Esto coincide con `QuantityPricingTier` y evita rangos solapados. Si el equipo exige rangos explícitos, `maxQuantity` queda **pendiente de definir**.

### `returnable_containers`

| Campo | Tipo de dato | Obligatorio | Descripción | Ejemplo |
|---|---|---:|---|---|
| `productId` | string | Sí | ID del producto que usa el envase. | `"prod-1"` |
| `isReturnable` | boolean | Sí | Indica si el producto usa un envase retornable. | `true` |
| `depositPrice` | number | Sí si es retornable | Garantía cobrada por cada envase faltante. | `2.0` |
| `isActive` | boolean | Sí | Indica si la configuración está vigente. **Propuesta.** | `true` |

La cantidad requerida no se guarda en esta entidad: se calcula con la cantidad de unidades del producto en el pedido. La cantidad entregada por el cliente pertenece al pedido o a su recepción, no al catálogo.

## 4. Relaciones y estructura propuesta en Firestore

Para el MVP se propone una base sencilla, sin microservicios:

```text
stores/{storeId}
  products/{productId}
    price_rules/{priceRuleId}
    returnable_containers/{containerId}
```

- `stores` contiene los comercios.
- `products` puede ser una subcolección del comercio porque cada producto pertenece a un único `storeId`.
- `price_rules` es una subcolección del producto porque sus reglas no tienen sentido fuera de ese producto.
- `returnable_containers` es una subcolección del producto. Para el MVP se espera como máximo un documento activo por producto.
- Se mantienen `storeId` y `productId` en los documentos relacionados para facilitar mapeos, validaciones y contratos entre módulos.
- Se recomienda usar los IDs de documentos, no referencias Firestore, en las entidades de dominio. Las referencias pueden utilizarse en infraestructura si luego se confirma esa decisión.
- Las imágenes se guardarían en Firebase Storage y Firestore solo conservaría `imageUrl`.

## 5. Contratos de consulta

Los contratos siguientes describen el comportamiento esperado del repositorio. Todos deben devolver una lista, una entidad o un error explícito; no deben devolver datos incompletos como si la operación hubiera sido exitosa.

| Consulta | Parámetros | Devuelve | Filtros y ordenamiento | Ejemplo de resultado |
|---|---|---|---|---|
| `getOpenStores` | Opcionalmente `limit` | `List<Store>` | `isOpen == true`; orden por `name` ascendente o por cercanía si se provee ubicación. | `[{ id: "store-1", name: "La Esquina", isOpen: true }]` |
| `getStoreById` | `storeId` | `Store` | Búsqueda directa por ID. | `{ id: "store-1", address: "Av. 4 de Noviembre" }` |
| `getNearbyStores` | `latitude`, `longitude`, `radiusInKm` | `List<Store>` | Comercios abiertos dentro del radio. **La consulta geoespacial exacta queda pendiente de definir.** | `[{ id: "store-1", location: (-0.95, -0.72) }]` |
| `getProductsByStore` | `storeId` | `List<Product>` | `isAvailable == true` para catálogo del cliente; orden por `name` ascendente. Para administración se puede omitir ese filtro. | `[{ id: "prod-1", name: "Cerveza", basePrice: 10.0 }]` |
| `getAvailableProducts` | `storeId` | `List<Product>` | `isAvailable == true`; orden por `name` ascendente. | `[{ id: "prod-1", isAvailable: true }]` |
| `getProductById` | `storeId`, `productId` | `Product` | Lectura directa de `stores/{storeId}/products/{productId}`. | `{ id: "prod-1", storeId: "store-1", basePrice: 10.0 }` |
| `getPriceRulesByProduct` | `storeId`, `productId`, opcional `quantity` | `List<PriceRule>` o regla aplicable | `isActive == true`; ordenar por `minQuantity` descendente. | `[{ minQuantity: 12, unitPrice: 8.0 }, { minQuantity: 6, unitPrice: 9.0 }]` |
| `getApplicablePrice` | `productId`, `quantity` | `number` | Usar la primera regla activa con `minQuantity <= quantity`; si no existe, usar `basePrice`. | `quantity: 12 -> unitPrice: 8.0` |
| `getReturnableContainerByProduct` | `storeId`, `productId` | `ReturnableContainer?` | Documento activo del producto; si no existe, el producto no usa envase retornable. | `{ isReturnable: true, depositPrice: 2.0 }` |

Las consultas de escritura necesarias para el boceto son `createStore`, `createProduct`, `createPriceRule`, `saveReturnableContainer`, `updateStoreStatus` y `updateProductAvailability`. Deben validar que el usuario autenticado sea propietario o tenga el rol autorizado.

## 6. Reglas de negocio y decisiones técnicas

| Regla del negocio | Decisión técnica de implementación |
|---|---|
| Un comercio abierto aparece disponible para nuevos pedidos; uno cerrado no debe recibirlos. (RF05) | Guardar `isOpen` en `stores`. La interfaz puede mostrar el horario, pero la autorización de aceptar un pedido debe volver a validar el estado en backend/reglas de Firestore. |
| El comercio puede habilitar delivery propio, delivery con repartidores de la plataforma o retiro. (RN02) | Guardar un mapa booleano `deliveryModes`. Los nombres definitivos de los modos deben confirmarse con el equipo. |
| Un producto agotado o no disponible no se ofrece para nuevos pedidos. | Guardar `isAvailable` en `products` y filtrar por `true` en el catálogo del cliente. |
| Los precios por cantidad aplican automáticamente según la cantidad comprada. (RN04) | Guardar reglas con `minQuantity` y `unitPrice`, ordenarlas de mayor a menor y seleccionar la primera que califique. Validar mínimos positivos y precios no negativos. |
| El precio usado en una compra queda congelado aunque cambie el catálogo. (RN08) | Al crear el pedido, copiar nombre, precio unitario aplicado, cantidad y depósito al `orderItem`. No recalcular pedidos existentes desde Firestore. |
| Si un producto usa envase retornable, el cliente declara cuántos envases vacíos entrega. (RN05/RF36) | Guardar `returnedContainers` en el pedido o en la recepción del pedido; no modificar el catálogo por esa declaración. |
| Solo se cobra la garantía de los envases faltantes. (RN05/RF37) | `missing = max(requiredContainers - returnedContainers, 0)` y `missingFee = missing * depositPrice`. El servicio actual `ContainerFeeCalculator` ya prueba esta regla. |
| Un pedido solo contiene productos de un comercio. (RN07) | El carrito debe conservar un único `storeId`; el módulo de catálogo no debe mezclar productos de comercios diferentes. |

La confirmación de edad, la devolución física de envases, la forma exacta de calcular comercios cercanos y la validación de horarios automáticos son **pendientes de definir con el equipo/docente**. No se deben resolver como supuestos en esta semana.

## 7. Boceto de alta de comercio

### Pantalla: “Registrar comercio”

1. **Datos básicos**
   - Nombre del comercio (obligatorio).
   - Descripción (opcional).
   - Teléfono (obligatorio).
   - Dirección (obligatoria).
2. **Ubicación**
   - Botón “Usar mi ubicación”.
   - Campo o mapa para confirmar la ubicación.
3. **Horario**
   - Selector de días.
   - Hora de apertura y cierre por día.
4. **Imagen**
   - Botón “Agregar imagen”.
   - Vista previa y opción de reemplazar.
5. **Modalidades**
   - Casillas: “Delivery propio”, “Delivery de la plataforma” y “Retiro en local”.
6. **Estado inicial**
   - El comercio se crea cerrado o abierto según la decisión del equipo. **Pendiente de definir.**

**Botones:** “Cancelar” y “Guardar comercio”.

**Validaciones:** nombre, dirección y teléfono no vacíos; teléfono con formato válido; al menos una modalidad seleccionada; horarios completos y coherentes; ubicación válida si el mapa es obligatorio; imagen con formato y tamaño permitidos si se selecciona.

**Flujo al guardar:**

1. Verificar sesión y rol de comercio.
2. Validar el formulario.
3. Subir la imagen a Storage, si existe.
4. Crear `stores/{storeId}` con los campos del formulario, `ownerId`, `isOpen` inicial y timestamps.
5. Mostrar confirmación y navegar al catálogo del comercio.
6. Mostrar un mensaje comprensible si falla la conexión o el guardado.

## 8. Boceto de catálogo: Comercio → Catálogo → Agregar producto

### 8.1 Pantalla del catálogo

Muestra el nombre del comercio, estado abierto/cerrado, una lista de productos, imagen, nombre, precio base, disponibilidad y una acción para editar. Incluye el botón **“Agregar producto”** y un control para activar o desactivar disponibilidad.

### 8.2 Formulario “Agregar producto”

Campos mínimos:

- Nombre del producto.
- Descripción opcional.
- Precio base.
- Imagen opcional.
- Interruptor “Producto disponible”.

### 8.3 Configuración del precio

El comercio ingresa el precio unitario base. La pantalla debe mostrarlo claramente porque será el precio usado cuando ninguna regla de cantidad aplique.

### 8.4 Configuración de precio por cantidad

El comercio puede agregar filas con:

```text
Cantidad mínima: 6 | Precio unitario: 9.00
Cantidad mínima: 12 | Precio unitario: 8.00
```

Validar que los mínimos sean mayores que cero, no se repitan y que los precios no sean negativos. El orden de las filas se puede mostrar ascendente, aunque la consulta las procesa descendentes.

### 8.5 Configuración de envase retornable

Un interruptor pregunta si el producto usa envase retornable. Si está activo, se solicita el valor de garantía por envase. El catálogo no solicita aquí cuántos envases devuelve el cliente: esa cantidad se conoce durante la compra o la entrega.

### 8.6 Disponibilidad e imagen

El producto puede guardarse disponible o no disponible. Si se selecciona imagen, se solicita permiso para galería o cámara, se sube a Storage y se guarda la URL en `imageUrl`. El acceso a la imagen debe mostrar un error claro si falla.

### 8.7 Guardado en Firebase

1. Validar sesión, rol y pertenencia del comercio.
2. Crear el documento en `stores/{storeId}/products`.
3. Guardar reglas activas en `price_rules`.
4. Guardar o actualizar el documento de `returnable_containers` si corresponde.
5. Guardar la URL de imagen, si existe.
6. Mostrar el producto actualizado en el catálogo.

Se recomienda que las escrituras relacionadas se realicen mediante una operación controlada (transacción o lote) cuando se confirme la infraestructura Firebase. Si una escritura falla, la aplicación debe informar el error y evitar mostrar un producto incompleto como guardado.

## 9. Estado actual del repositorio

La base actual ya tiene:

- `Store` con nombre, dirección, estado y modalidades de entrega.
- `Product` con comercio, nombre, descripción, precio base, disponibilidad, envase y niveles de precio.
- `QuantityPricingTier` para RN04.
- `ContainerFeeCalculator` y pruebas para RN05.
- Contratos de dominio `StoreRepository` y `ProductRepository`.
- Pruebas unitarias de precios por cantidad y envases retornables.
- Entidades explícitas `PriceRule` y `ReturnableContainer`.
- Contrato `ReturnableContainerRepository`.
- Consultas de disponibilidad y creación incorporadas a los contratos de comercios y productos.

Todavía no se observan implementaciones de `infrastructure`, pantallas de comercios/catálogo ni dependencias de Firebase en `pubspec.yaml`. Por tanto, las estructuras Firestore, mapeadores, Storage y formularios de este documento son el diseño de Semana 1, no funcionalidades ya terminadas. Las entidades y contratos de dominio sí quedaron implementados y probados en esta semana.

## 10. Decisiones técnicas tomadas

1. Mantener la arquitectura Flutter como monolito modular, sin microservicios.
2. Mantener el dominio en Dart puro, sin importar Firebase ni widgets de Flutter.
3. Usar subcolecciones para conservar la relación comercio-producto-reglas.
4. Usar IDs simples entre entidades y dejar las referencias Firestore para la infraestructura.
5. Guardar imágenes en Firebase Storage y solo la URL en Firestore.
6. Usar `isOpen` e `isAvailable` para consultas simples y comprensibles.
7. Representar el precio por cantidad con umbral mínimo, de acuerdo con `QuantityPricingTier`.
8. Congelar el precio en `order_items` al crear el pedido, responsabilidad coordinada con el módulo de carrito/pedidos.
9. Calcular el cargo de envases faltantes sin cobrar envases que el cliente sí devuelve.

## 11. Aspectos pendientes de confirmar

- Si el comercio inicia abierto o cerrado después del registro.
- Estructura definitiva de `openingHours` y si el estado abierto se calcula automáticamente con el horario.
- Si el catálogo requiere categorías, unidad de venta o marca; no se agregan al MVP hasta confirmarlo.
- Si `price_rules` usará solo `minQuantity` o también `maxQuantity`.
- Si habrá un único tipo de envase por producto o varios tipos.
- Momento y responsable de confirmar físicamente los envases devueltos.
- Método de búsqueda por cercanía (geohash, consulta aproximada u otra alternativa).
- Tamaño, formato y obligatoriedad de imágenes.
- Reglas de seguridad de Firestore para propietarios y clientes.
- Confirmación de mayoría de edad para compra y entrega de alcohol, señalada en el documento del proyecto como tema para el docente.
- Campos definitivos del pedido que almacenará los precios congelados y el cargo por envases.

## Conclusión

El diseño cubre el alcance de la Semana 1 sin agregar funcionalidades fuera del MVP. Define las cuatro entidades, sus campos mínimos, relaciones, consultas, reglas y dos flujos de interfaz. La siguiente etapa puede implementar primero los mapeadores y repositorios de Firestore, y después las pantallas de registro de comercio y administración del catálogo, una vez que el equipo confirme los puntos pendientes.
