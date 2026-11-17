import '../../../../core/di/service_locator.dart';
import '../domain/repositories/delivery_negotiation_repository.dart';
import '../infrastructure/repositories/in_memory_delivery_negotiation_repository.dart';
import '../presentation/controllers/delivery_negotiation_controller.dart';
import '../presentation/delivery_negotiation_factory.dart';

/// Módulo de Inyección de Dependencias para negociación de entregas.
class DeliveryOffersDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (!locator.isRegistered<DeliveryNegotiationRepository>()) {
      locator.registerLazySingleton<DeliveryNegotiationRepository>(
        () => InMemoryDeliveryNegotiationRepository(),
      );
    }

    if (!locator.isRegistered<DeliveryNegotiationController>()) {
      locator.registerFactory<DeliveryNegotiationController>(
        () => buildDeliveryNegotiationController(
          repository: locator.get<DeliveryNegotiationRepository>(),
        ),
      );
    }
  }
}
