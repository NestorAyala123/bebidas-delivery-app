import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../orders/domain/contracts/order_delivery_contract.dart';
import '../entities/delivery_fee.dart';
import '../entities/delivery_mode.dart';
import '../entities/delivery_request.dart';
import '../entities/delivery_status.dart';
import '../repositories/delivery_repository.dart';
import '../services/delivery_order_policy.dart';

/// Caso de uso para crear una solicitud de delivery externo a partir
/// de los datos de un pedido confirmado (OrderDeliveryInfo).
///
/// Aplica las reglas de negocio de Semana 4:
/// - RN01: Solo pedidos confirmados por el comercio pueden generar solicitud de reparto.
///   Pedidos pendientes, rechazados o cancelados (isConfirmedByStore = false) no deben generarla.
/// - Prevención de duplicados: No permite más de una solicitud activa por pedido (orderId).
///   Si una solicitud anterior está en estado terminal (ej. cancelada), permite una nueva.
/// - Conserva: orderId, customerId, storeId, originAddress, destinationAddress y distanceInKm.
/// - Tarifa referencial: calculada y consistente con DeliveryFee.
/// 100% pure Dart, independiente de Flutter y Firebase.
class CreateDeliveryRequestFromOrderUseCase {
  final DeliveryRepository repository;
  final DeliveryOrderPolicy policy;
  final DeliveryFee feeCalculator;
  final String Function()? idGenerator;

  const CreateDeliveryRequestFromOrderUseCase({
    required this.repository,
    this.policy = const DeliveryOrderPolicy(),
    this.feeCalculator = const DeliveryFee(),
    this.idGenerator,
  });

  Future<Result<DeliveryRequest, Failure>> call({
    required OrderDeliveryInfo orderInfo,
    double? distanceInKm,
    DateTime? createdAt,
  }) async {
    // 1. RN01: Solo pedidos confirmados por el comercio pueden generar solicitud
    if (!orderInfo.isConfirmedByStore) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN01: El pedido debe estar confirmado por el comercio para generar una solicitud de delivery.',
        ),
      );
    }

    // 2. Validación de elegibilidad para delivery externo
    if (!policy.canCreateDeliveryRequest(orderInfo)) {
      return const FailureResult(
        BusinessRuleFailure(
          'El pedido no es elegible para solicitar servicio de delivery externo.',
        ),
      );
    }

    // 3. Prevención de solicitudes duplicadas activas para el mismo orderId
    final activeCheck =
        await repository.getActiveDeliveryRequestByOrderId(orderInfo.orderId);
    if (activeCheck.isSuccess && activeCheck.dataOrNull != null) {
      return FailureResult(
        BusinessRuleFailure(
          'Ya existe una solicitud de delivery activa para el pedido ${orderInfo.orderId}.',
        ),
      );
    }

    // 4. Distancia obligatoria y no negativa
    final effectiveDistance = distanceInKm ?? orderInfo.distanceInKm;
    if (effectiveDistance == null || effectiveDistance < 0) {
      return const FailureResult(
        ValidationFailure(
          'La distancia en kilómetros es obligatoria y debe ser mayor o igual a 0.',
        ),
      );
    }

    // 5. Cálculo de tarifa referencial inalterable
    final calculatedFare = feeCalculator.calculate(effectiveDistance);

    // 6. Generación de ID de solicitud
    final requestId = idGenerator?.call() ??
        'req-${orderInfo.orderId}-${DateTime.now().millisecondsSinceEpoch}';

    // 7. Construcción de entidad DeliveryRequest
    final request = DeliveryRequest(
      id: requestId,
      orderId: orderInfo.orderId,
      customerId: orderInfo.customerId,
      storeId: orderInfo.storeId,
      originAddress: orderInfo.pickupAddress,
      destinationAddress: orderInfo.deliveryAddress,
      distanceInKm: effectiveDistance,
      referenceFare: calculatedFare,
      deliveryMode: DeliveryMode.externalDriver,
      status: DeliveryStatus.pendingOffer,
      isOrderConfirmedByStore: true,
      createdAt: createdAt ?? DateTime.now(),
    );

    return repository.createDeliveryRequest(request);
  }
}
