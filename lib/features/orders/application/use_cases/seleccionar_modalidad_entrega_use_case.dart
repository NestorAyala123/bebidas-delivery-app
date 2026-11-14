import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../delivery/domain/entities/delivery_mode.dart';
import '../../domain/entities/order.dart';
import '../../domain/services/order_flow_service.dart';

/// Selecciona y valida la modalidad de entrega elegida por el cliente (RN02).
class SeleccionarModalidadEntregaUseCase {
  final OrderFlowService flowService;

  const SeleccionarModalidadEntregaUseCase({
    this.flowService = const OrderFlowService(),
  });

  Result<Order, Failure> call({
    required Order order,
    required DeliveryMode mode,
    required bool storeHasOwnDelivery,
    required bool storeAllowsExternalDelivery,
    required bool storeAllowsPickup,
    double? deliveryFee,
  }) {
    return flowService.selectDeliveryMode(
      order: order,
      mode: mode,
      storeHasOwnDelivery: storeHasOwnDelivery,
      storeAllowsExternalDelivery: storeAllowsExternalDelivery,
      storeAllowsPickup: storeAllowsPickup,
      deliveryFee: deliveryFee,
    );
  }
}
