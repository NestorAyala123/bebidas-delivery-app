# Semana 2: comercios y productos

## Alcance implementado

La primera vertical de la rama `feature/stores-products` permite:

- Registrar y editar un comercio con nombre, dirección, teléfono y descripción.
- Configurar delivery propio, repartidor de plataforma y retiro en local.
- Cambiar el comercio entre abierto y cerrado.
- Registrar productos básicos con nombre, precio e imagen opcional.
- Editar productos y cambiar su disponibilidad.
- Configurar un precio escalonado por cantidad mínima.
- Configurar el depósito de un envase retornable por producto.
- Consultar los productos asociados a un comercio y filtrar los disponibles.
- Consultar el catálogo de un comercio mediante `GetStoreCatalogUseCase`,
  diferenciando productos disponibles del catálogo completo de administración.

## Capas

- `domain`: entidades y contratos de repositorio. No importa Flutter, Firebase ni
  servicios externos.
- `application`: casos de uso `SaveStoreUseCase`, `UpdateStoreStatusUseCase`,
  `SaveProductUseCase`, `UpdateProductAvailabilityUseCase`,
  `SavePriceRuleUseCase` y `SaveReturnableContainerUseCase`, incluyendo
  validaciones de negocio de entrada.
- `infrastructure`: repositorios en memoria para hacer funcional la primera
  vertical sin fijar todavía una decisión de persistencia.
- `presentation`: ruta `/stores` y pantalla de administración.

La implementación en memoria es intencionalmente reemplazable. Cuando el equipo
defina Firebase u otra persistencia, se puede agregar otro repositorio que
implemente los contratos sin modificar las entidades ni los casos de uso.

## Pruebas

Se agregaron pruebas para:

- Alta y edición de comercios.
- Validación de coordenadas y datos obligatorios.
- Cambio de estado abierto/cerrado.
- Alta, edición y disponibilidad de productos.
- Precio negativo e imagen opcional.
- Regla de precio asociada al producto.
- Depósito obligatorio para envases retornables.

Comandos verificados:

```text
dart format .
flutter analyze
flutter test
```
