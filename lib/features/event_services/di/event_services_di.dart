import '../../../../core/di/service_locator.dart';
import '../domain/repositories/consulta_servicio_repository.dart';
import '../domain/repositories/ficha_servicio_repository.dart';
import '../domain/usecases/crear_consulta_servicio_use_case.dart';
import '../domain/usecases/obtener_consultas_servicio_use_case.dart';
import '../domain/usecases/obtener_ficha_detalle_use_case.dart';
import '../domain/usecases/obtener_servicios_use_case.dart';
import '../domain/usecases/publicar_ficha_use_case.dart';
import '../infrastructure/repositories/in_memory_consulta_servicio_repository.dart';
import '../infrastructure/repositories/in_memory_ficha_servicio_repository.dart';
import '../presentation/controllers/consultas_controller.dart';
import '../presentation/controllers/event_services_controller.dart';

/// Módulo de Inyección de Dependencias para Servicios de Eventos (Adriano).
class EventServicesDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    // 1. Repositorio de Infraestructura
    if (!locator.isRegistered<FichaServicioRepository>()) {
      locator.registerLazySingleton<FichaServicioRepository>(
        () => InMemoryFichaServicioRepository(),
      );
    }

    if (!locator.isRegistered<ConsultaServicioRepository>()) {
      locator.registerLazySingleton<ConsultaServicioRepository>(
        () => InMemoryConsultaServicioRepository(),
      );
    }

    // 2. Casos de uso de Dominio
    if (!locator.isRegistered<ObtenerServiciosUseCase>()) {
      locator.registerFactory<ObtenerServiciosUseCase>(
        () => ObtenerServiciosUseCase(locator.get<FichaServicioRepository>()),
      );
    }

    if (!locator.isRegistered<PublicarFichaUseCase>()) {
      locator.registerFactory<PublicarFichaUseCase>(
        () => PublicarFichaUseCase(locator.get<FichaServicioRepository>()),
      );
    }

    if (!locator.isRegistered<ObtenerFichaDetalleUseCase>()) {
      locator.registerFactory<ObtenerFichaDetalleUseCase>(
        () => ObtenerFichaDetalleUseCase(locator.get<FichaServicioRepository>()),
      );
    }

    if (!locator.isRegistered<CrearConsultaServicioUseCase>()) {
      locator.registerFactory<CrearConsultaServicioUseCase>(
        () => CrearConsultaServicioUseCase(
          locator.get<ConsultaServicioRepository>(),
        ),
      );
    }

    if (!locator.isRegistered<ObtenerConsultasServicioUseCase>()) {
      locator.registerFactory<ObtenerConsultasServicioUseCase>(
        () => ObtenerConsultasServicioUseCase(
          locator.get<ConsultaServicioRepository>(),
        ),
      );
    }

    // 3. Controlador de Presentación
    if (!locator.isRegistered<EventServicesController>()) {
      locator.registerFactory<EventServicesController>(
        () => EventServicesController(
          obtenerServiciosUseCase: locator.get<ObtenerServiciosUseCase>(),
          publicarFichaUseCase: locator.get<PublicarFichaUseCase>(),
        ),
      );
    }

    if (!locator.isRegistered<ConsultasController>()) {
      locator.registerFactory<ConsultasController>(
        () => ConsultasController(
          crearConsultaServicioUseCase:
              locator.get<CrearConsultaServicioUseCase>(),
          obtenerConsultasServicioUseCase:
              locator.get<ObtenerConsultasServicioUseCase>(),
        ),
      );
    }
  }
}

