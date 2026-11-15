import '../../../../core/di/service_locator.dart';
import '../domain/repositories/delivery_negotiation_repository.dart';
import '../infrastructure/repositories/in_memory_delivery_negotiation_repository.dart';
import 'controllers/delivery_negotiation_controller.dart';

/// Construye el controlador usando el contenedor y, si no está registrado,
/// el repositorio en memoria de demostración.
DeliveryNegotiationController buildDeliveryNegotiationController({
  DeliveryNegotiationRepository? repository,
}) {
  final negotiationRepository =
      repository ??
      (sl.isRegistered<DeliveryNegotiationRepository>()
          ? sl.get<DeliveryNegotiationRepository>()
          : InMemoryDeliveryNegotiationRepository());

  return DeliveryNegotiationController(repository: negotiationRepository);
}
