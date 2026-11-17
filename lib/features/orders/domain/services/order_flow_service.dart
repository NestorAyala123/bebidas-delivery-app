import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../delivery/domain/entities/delivery_mode.dart';
import '../../../pricing/domain/services/delivery_fee_policy.dart';
import '../entities/order.dart';
import '../entities/order_status.dart';
import '../entities/payment_method.dart';

/// Acciones del cliente cuando no hay repartidores disponibles (RN03).
enum OrderNoDriversAction {
  wait,
  increaseOffer,
  pickupAtStore,
  useStoreOwnDelivery,
  cancelOrder;

  String get label => switch (this) {
    OrderNoDriversAction.wait => 'Esperar a que aparezca un repartidor',
    OrderNoDriversAction.increaseOffer => 'Aumentar la tarifa ofrecida',
    OrderNoDriversAction.pickupAtStore => 'Retirar en el local',
    OrderNoDriversAction.useStoreOwnDelivery =>
      'Usar delivery propio del comercio',
    OrderNoDriversAction.cancelOrder => 'Cancelar el pedido',
  };
}

/// Resultado de aplicar una alternativa ante la ausencia de repartidores.
class NoDriversResolution {
  final Order order;
  final String message;

  const NoDriversResolution({required this.order, required this.message});
}

/// Reglas puras del flujo de pedido: modalidad (RN02), transiciones de estado,
/// pago registrado y alternativas sin repartidores (RN03).
class OrderFlowService {
  final DeliveryFeePolicy deliveryFeePolicy;

  const OrderFlowService({this.deliveryFeePolicy = const DeliveryFeePolicy()});

  Result<void, Failure> validateDeliveryMode({
    required DeliveryMode mode,
    required bool storeHasOwnDelivery,
    required bool storeAllowsExternalDelivery,
    required bool storeAllowsPickup,
  }) {
    if (mode == DeliveryMode.ownDelivery && !storeHasOwnDelivery) {
      return const FailureResult(
        BusinessRuleFailure('El comercio no ofrece delivery propio (RN02)'),
      );
    }

    if (mode == DeliveryMode.externalDriver && !storeAllowsExternalDelivery) {
      return const FailureResult(
        BusinessRuleFailure(
          'El comercio no permite repartidores externos (RN02)',
        ),
      );
    }

    if (mode == DeliveryMode.pickupAtStore && !storeAllowsPickup) {
      return const FailureResult(
        BusinessRuleFailure('El comercio no permite retiro en local (RN02)'),
      );
    }

    return const Success(null);
  }

  Result<Order, Failure> selectDeliveryMode({
    required Order order,
    required DeliveryMode mode,
    required bool storeHasOwnDelivery,
    required bool storeAllowsExternalDelivery,
    required bool storeAllowsPickup,
    double? deliveryFee,
  }) {
    final validation = validateDeliveryMode(
      mode: mode,
      storeHasOwnDelivery: storeHasOwnDelivery,
      storeAllowsExternalDelivery: storeAllowsExternalDelivery,
      storeAllowsPickup: storeAllowsPickup,
    );

    if (validation.isFailure) {
      return FailureResult(validation.failureOrNull!);
    }

    if (order.status.isTerminal) {
      return const FailureResult(
        BusinessRuleFailure(
          'No puedes cambiar la modalidad de un pedido cerrado',
        ),
      );
    }

    if (mode.isPickup) {
      return Success(
        order.copyWithCheckout(deliveryMode: mode, deliveryFee: 0),
      );
    }

    final fee = deliveryFee ?? order.deliveryFee;
    if (fee < 0) {
      return const FailureResult(
        ValidationFailure('La tarifa de entrega no puede ser negativa'),
      );
    }

    return Success(
      order.copyWithCheckout(deliveryMode: mode, deliveryFee: fee),
    );
  }

  Result<Order, Failure> registerPaymentMethod({
    required Order order,
    required PaymentMethod method,
  }) {
    if (order.status.isTerminal) {
      return const FailureResult(
        BusinessRuleFailure('El pedido ya está cerrado y no admite pagos'),
      );
    }

    return Success(order.copyWithCheckout(paymentMethod: method));
  }

  Result<void, Failure> validatePaymentReady(Order order) {
    if (!order.isPaymentRegistered) {
      return const FailureResult(
        ValidationFailure('Selecciona un método de pago antes de confirmar'),
      );
    }
    if (order.isPickup && order.deliveryFee != 0) {
      return const FailureResult(
        BusinessRuleFailure('El retiro en local no debe cobrar envío'),
      );
    }
    return const Success(null);
  }

  /// Transiciones válidas del ciclo de vida (RN01 + ejecución de entrega).
  Result<Order, Failure> transition(Order order, OrderStatus next) {
    final current = order.status;

    if (current == next) {
      return const FailureResult(
        BusinessRuleFailure('El pedido ya se encuentra en ese estado'),
      );
    }

    final allowed = switch (current) {
      OrderStatus.created =>
        next == OrderStatus.confirmed ||
            next == OrderStatus.rejected ||
            next == OrderStatus.cancelled,
      OrderStatus.confirmed =>
        next == OrderStatus.preparing ||
            next == OrderStatus.lookingForDriver ||
            next == OrderStatus.cancelled,
      OrderStatus.preparing =>
        next == OrderStatus.readyForPickup ||
            next == OrderStatus.readyForDelivery ||
            next == OrderStatus.lookingForDriver ||
            next == OrderStatus.cancelled,
      OrderStatus.readyForPickup =>
        next == OrderStatus.pickedUp || next == OrderStatus.cancelled,
      OrderStatus.pickedUp =>
        next == OrderStatus.delivered || next == OrderStatus.cancelled,
      OrderStatus.readyForDelivery =>
        next == OrderStatus.inDelivery || next == OrderStatus.cancelled,
      OrderStatus.lookingForDriver =>
        next == OrderStatus.driverAssigned ||
            next == OrderStatus.noDriversAvailable ||
            next == OrderStatus.confirmed ||
            next == OrderStatus.cancelled,
      OrderStatus.noDriversAvailable =>
        next == OrderStatus.lookingForDriver ||
            next == OrderStatus.preparing ||
            next == OrderStatus.cancelled,
      OrderStatus.driverAssigned =>
        next == OrderStatus.inDelivery || next == OrderStatus.cancelled,
      OrderStatus.inDelivery => next == OrderStatus.delivered,
      OrderStatus.delivered ||
      OrderStatus.rejected ||
      OrderStatus.cancelled => false,
    };

    if (!allowed) {
      return FailureResult(
        BusinessRuleFailure(
          'Transición no permitida: ${current.name} → ${next.name}',
        ),
      );
    }

    if (next == OrderStatus.lookingForDriver && !order.isCheckoutReady) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN01: registra modalidad y método de pago antes de buscar repartidor',
        ),
      );
    }

    if (next == OrderStatus.lookingForDriver &&
        !order.deliveryMode.requiresExternalDriver) {
      return const FailureResult(
        BusinessRuleFailure(
          'Solo la modalidad de repartidor externo busca ofertas',
        ),
      );
    }

    return Success(
      order.copyWithStatus(
        next,
        confirmedAt: next == OrderStatus.confirmed
            ? DateTime.now()
            : order.confirmedAt,
      ),
    );
  }

  /// Aplica la alternativa elegida por el cliente cuando nadie acepta la oferta.
  Result<NoDriversResolution, Failure> resolveNoDrivers({
    required Order order,
    required OrderNoDriversAction action,
    required bool storeHasOwnDelivery,
    required bool storeAllowsPickup,
    double? increasedFee,
  }) {
    if (order.status != OrderStatus.lookingForDriver) {
      return const FailureResult(
        BusinessRuleFailure(
          'Las alternativas aplican cuando el pedido está buscando repartidor',
        ),
      );
    }

    switch (action) {
      case OrderNoDriversAction.wait:
        return Success(
          NoDriversResolution(
            order: order,
            message: 'Seguimos buscando repartidores para tu pedido',
          ),
        );

      case OrderNoDriversAction.increaseOffer:
        final fee = increasedFee ?? order.deliveryFee;
        if (fee <= order.deliveryFee) {
          return FailureResult(
            BusinessRuleFailure(
              'La nueva oferta debe ser mayor a \$${order.deliveryFee.toStringAsFixed(2)}',
            ),
          );
        }
        if (fee > 200) {
          return const FailureResult(
            ValidationFailure('La tarifa máxima permitida es \$200.00'),
          );
        }
        return Success(
          NoDriversResolution(
            order: order.copyWithCheckout(deliveryFee: fee),
            message: 'Oferta aumentada a \$${fee.toStringAsFixed(2)}',
          ),
        );

      case OrderNoDriversAction.pickupAtStore:
        if (!storeAllowsPickup) {
          return const FailureResult(
            BusinessRuleFailure('El comercio no permite retiro en local'),
          );
        }
        return Success(
          NoDriversResolution(
            order: order.copyWithCheckout(
              deliveryMode: DeliveryMode.pickupAtStore,
              deliveryFee: 0,
            ),
            message: 'Cambiaste a retiro en local. No se cobra envío.',
          ),
        );

      case OrderNoDriversAction.useStoreOwnDelivery:
        if (!storeHasOwnDelivery) {
          return const FailureResult(
            BusinessRuleFailure('El comercio no dispone de delivery propio'),
          );
        }
        return Success(
          NoDriversResolution(
            order: order.copyWithCheckout(
              deliveryMode: DeliveryMode.ownDelivery,
            ),
            message:
                'El comercio realizará la entrega con su propio repartidor',
          ),
        );

      case OrderNoDriversAction.cancelOrder:
        return Success(
          NoDriversResolution(
            order: order.copyWithStatus(OrderStatus.cancelled),
            message: 'Pedido cancelado. No se realizará ningún cobro de envío.',
          ),
        );
    }
  }

  /// Lanza [DomainException] si una transición inválida intenta persistirse.
  void assertTransition(Order order, OrderStatus next) {
    final result = transition(order, next);
    if (result.isFailure) {
      throw DomainException(result.failureOrNull!.message);
    }
  }
}
