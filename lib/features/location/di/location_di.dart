import '../../../../core/di/service_locator.dart';
import '../domain/repositories/location_repository.dart';
import '../domain/usecases/obtener_comercios_cercanos_use_case.dart';
import '../domain/usecases/obtener_ubicacion_actual_use_case.dart';
import '../infrastructure/repositories/geolocator_location_repository.dart';
import '../presentation/controllers/location_map_controller.dart';

/// Módulo de Inyección de Dependencias para Ubicación y Mapas (Adriano).
class LocationDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    // 1. Repositorio de Infraestructura (Geolocator)
    if (!locator.isRegistered<LocationRepository>()) {
      locator.registerLazySingleton<LocationRepository>(
        () => GeolocatorLocationRepository(),
      );
    }

    // 2. Casos de uso de Dominio
    if (!locator.isRegistered<ObtenerUbicacionActualUseCase>()) {
      locator.registerFactory<ObtenerUbicacionActualUseCase>(
        () => ObtenerUbicacionActualUseCase(locator.get<LocationRepository>()),
      );
    }

    if (!locator.isRegistered<ObtenerComerciosCercanosUseCase>()) {
      locator.registerFactory<ObtenerComerciosCercanosUseCase>(
        () => ObtenerComerciosCercanosUseCase(locator.get<LocationRepository>()),
      );
    }

    // 3. Controlador de Presentación
    if (!locator.isRegistered<LocationMapController>()) {
      locator.registerFactory<LocationMapController>(
        () => LocationMapController(
          obtenerUbicacionActualUseCase:
              locator.get<ObtenerUbicacionActualUseCase>(),
          obtenerComerciosCercanosUseCase:
              locator.get<ObtenerComerciosCercanosUseCase>(),
        ),
      );
    }
  }
}
