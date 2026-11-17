import '../../../../core/di/service_locator.dart';
import '../../products/domain/usecases/validar_disponibilidad_compra_use_case.dart';
import '../domain/usecases/calcular_precio_compra_use_case.dart';

/// Módulo de Inyección de Dependencias para precios y envíos (Wendy).
class PricingDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (!locator.isRegistered<CalcularPrecioCompraUseCase>()) {
      locator.registerFactory<CalcularPrecioCompraUseCase>(
        () => const CalcularPrecioCompraUseCase(),
      );
    }

    if (!locator.isRegistered<ValidarDisponibilidadCompraUseCase>()) {
      locator.registerFactory<ValidarDisponibilidadCompraUseCase>(
        () => const ValidarDisponibilidadCompraUseCase(),
      );
    }
  }
}
