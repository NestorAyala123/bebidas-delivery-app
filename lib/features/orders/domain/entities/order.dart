import '../../../../core/errors/exceptions.dart';
import 'order_delivery_method.dart';
import 'order_item.dart';
import 'order_status.dart';
import 'order_payment_method.dart';

/// Core Order domain entity.
/// Enforces RN01, RN07, RN08.
class Order {
  final String id;
  final String customerId;
  final String storeId; // RN07: Un pedido pertenece a un solo establecimiento
  final List<OrderItem> items;
  final OrderStatus status;
  final OrderDeliveryMethod deliveryMethod;
  final OrderPaymentMethod paymentMethod;
  final String deliveryAddress;
  final double missingContainersFee;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String? rejectionReason;
  final List<OrderStatusChange> statusHistory;

  const Order({
    required this.id,
    required this.customerId,
    required this.storeId,
    required this.items,
    required this.status,
    required this.deliveryMethod,
    this.paymentMethod = OrderPaymentMethod.cash,
    required this.deliveryAddress,
    this.missingContainersFee = 0.0,
    required this.createdAt,
    this.confirmedAt,
    this.rejectionReason,
    this.statusHistory = const [],
  }) : assert(items.length > 0, 'Un pedido debe tener al menos un item');

  /// Subtotal calculated from frozen prices
  double get itemsSubtotal =>
      items.fold(0.0, (acc, item) => acc + item.subtotal);

  /// Final total including missing containers fee
  double get total => itemsSubtotal + missingContainersFee;

  /// RN01: El establecimiento debe confirmar el pedido antes de buscar repartidor.
  bool get canRequestDriver => status.canSearchDriver;
  bool get canCancel => status.canBeCancelled;

  List<OrderStatusChange> get timeline => statusHistory.isEmpty
      ? [OrderStatusChange(status: status, changedAt: createdAt)]
      : statusHistory;

  /// Creates a copy with an updated status
  Order copyWithStatus(
    OrderStatus newStatus, {
    DateTime? confirmedAt,
    String? rejectionReason,
    DateTime? changedAt,
  }) {
    if (!_canTransitionTo(newStatus)) {
      throw DomainException(
        'No se puede cambiar el estado del pedido de $status a $newStatus.',
      );
    }
    if (newStatus == OrderStatus.rejected &&
        (rejectionReason == null || rejectionReason.trim().isEmpty)) {
      throw const DomainException(
        'Se debe indicar el motivo para rechazar un pedido.',
      );
    }

    final history = List<OrderStatusChange>.of(timeline)
      ..add(
        OrderStatusChange(
          status: newStatus,
          changedAt: changedAt ?? DateTime.now(),
        ),
      );

    return Order(
      id: id,
      customerId: customerId,
      storeId: storeId,
      items: items,
      status: newStatus,
      deliveryMethod: deliveryMethod,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      missingContainersFee: missingContainersFee,
      createdAt: createdAt,
      confirmedAt: newStatus == OrderStatus.confirmed
          ? confirmedAt
          : this.confirmedAt,
      rejectionReason: newStatus == OrderStatus.rejected
          ? rejectionReason!.trim()
          : this.rejectionReason,
      statusHistory: history,
    );
  }

  Order useAlternativeDeliveryMethod(
    OrderDeliveryMethod newMethod, {
    DateTime? changedAt,
  }) {
    if (status != OrderStatus.noDriversAvailable ||
        newMethod == OrderDeliveryMethod.externalDelivery ||
        newMethod == deliveryMethod) {
      throw const DomainException(
        'La alternativa de entrega no es válida para este pedido.',
      );
    }

    final timestamp = changedAt ?? DateTime.now();
    return Order(
      id: id,
      customerId: customerId,
      storeId: storeId,
      items: items,
      status: OrderStatus.preparing,
      deliveryMethod: newMethod,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      missingContainersFee: missingContainersFee,
      createdAt: createdAt,
      confirmedAt: confirmedAt,
      rejectionReason: rejectionReason,
      statusHistory: [
        ...timeline,
        OrderStatusChange(status: OrderStatus.preparing, changedAt: timestamp),
      ],
    );
  }

  bool _canTransitionTo(OrderStatus newStatus) {
    return switch (status) {
      OrderStatus.created =>
        newStatus == OrderStatus.confirmed ||
            newStatus == OrderStatus.rejected ||
            newStatus == OrderStatus.cancelled,
      OrderStatus.confirmed =>
        newStatus == OrderStatus.preparing ||
            (deliveryMethod == OrderDeliveryMethod.externalDelivery &&
                newStatus == OrderStatus.lookingForDriver) ||
            newStatus == OrderStatus.cancelled,
      OrderStatus.preparing => switch (deliveryMethod) {
        OrderDeliveryMethod.pickup =>
          newStatus == OrderStatus.readyForPickup ||
              newStatus == OrderStatus.cancelled,
        OrderDeliveryMethod.storeDelivery =>
          newStatus == OrderStatus.readyForDelivery ||
              newStatus == OrderStatus.cancelled,
        OrderDeliveryMethod.externalDelivery =>
          newStatus == OrderStatus.lookingForDriver ||
              newStatus == OrderStatus.cancelled,
      },
      OrderStatus.readyForPickup => newStatus == OrderStatus.pickedUp,
      OrderStatus.pickedUp => newStatus == OrderStatus.delivered,
      OrderStatus.readyForDelivery => newStatus == OrderStatus.inDelivery,
      OrderStatus.lookingForDriver =>
        deliveryMethod == OrderDeliveryMethod.externalDelivery &&
            (newStatus == OrderStatus.noDriversAvailable ||
                newStatus == OrderStatus.driverAssigned ||
                newStatus == OrderStatus.cancelled),
      OrderStatus.noDriversAvailable =>
        newStatus == OrderStatus.lookingForDriver ||
            newStatus == OrderStatus.cancelled,
      OrderStatus.driverAssigned =>
        deliveryMethod == OrderDeliveryMethod.externalDelivery &&
            newStatus == OrderStatus.inDelivery,
      OrderStatus.inDelivery =>
        (deliveryMethod == OrderDeliveryMethod.storeDelivery ||
                deliveryMethod == OrderDeliveryMethod.externalDelivery) &&
            newStatus == OrderStatus.delivered,
      OrderStatus.rejected ||
      OrderStatus.delivered ||
      OrderStatus.cancelled => false,
    };
  }
}
