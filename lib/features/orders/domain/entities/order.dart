import '../../../../core/errors/exceptions.dart';
import '../../../delivery/domain/entities/delivery_mode.dart';
import 'order_delivery_method.dart';
import 'order_item.dart';
import 'order_status.dart';
import 'payment_method.dart';

/// Core Order domain entity.
/// Enforces RN01, RN07, RN08 and stores the checkout decisions of RN02.
class Order {
  final String id;
  final String customerId;
  final String storeId; // RN07: Un pedido pertenece a un solo establecimiento
  final List<OrderItem> items;
  final OrderStatus status;
  final OrderDeliveryMethod deliveryMethod;
  final DeliveryMode deliveryMode;
  final PaymentMethod? paymentMethod;
  final String deliveryAddress;
  final double missingContainersFee;
  final double deliveryFee;
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
    OrderDeliveryMethod? deliveryMethod,
    DeliveryMode? deliveryMode,
    this.paymentMethod,
    required this.deliveryAddress,
    this.missingContainersFee = 0.0,
    this.deliveryFee = 0.0,
    required this.createdAt,
    this.confirmedAt,
    this.rejectionReason,
    this.statusHistory = const [],
  }) : deliveryMethod =
           deliveryMethod ??
           (deliveryMode == DeliveryMode.pickupAtStore
               ? OrderDeliveryMethod.pickup
               : deliveryMode == DeliveryMode.ownDelivery
               ? OrderDeliveryMethod.storeDelivery
               : OrderDeliveryMethod.externalDelivery),
       deliveryMode =
           deliveryMode ??
           (deliveryMethod == OrderDeliveryMethod.pickup
               ? DeliveryMode.pickupAtStore
               : deliveryMethod == OrderDeliveryMethod.storeDelivery
               ? DeliveryMode.ownDelivery
               : DeliveryMode.externalDriver),
       assert(items.length > 0, 'Un pedido debe tener al menos un item'),
       assert(deliveryFee >= 0, 'El costo de envío no puede ser negativo');

  /// Subtotal calculated from frozen prices
  double get itemsSubtotal =>
      items.fold(0.0, (acc, item) => acc + item.subtotal);

  /// Final total including missing containers fee and delivery fee
  double get total => itemsSubtotal + missingContainersFee + deliveryFee;

  /// RN01: El establecimiento debe confirmar el pedido antes de buscar repartidor.
  bool get canRequestDriver => status.canSearchDriver;
  bool get canCancel => status.canBeCancelled;

  List<OrderStatusChange> get timeline => statusHistory.isEmpty
      ? [OrderStatusChange(status: status, changedAt: createdAt)]
      : statusHistory;

  /// Indica si el cliente ya eligió cómo pagar.
  bool get isPaymentRegistered => paymentMethod != null;

  /// Solo se confirma el checkout con modalidad y pago registrados.
  bool get isCheckoutReady => isPaymentRegistered;

  /// RN02: modalidad seleccionada por el cliente.
  bool get isPickup => deliveryMode.isPickup;
  bool get usesExternalDriver => deliveryMode.requiresExternalDriver;

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

    final timestamp = changedAt ?? DateTime.now();

    final history = List<OrderStatusChange>.of(timeline)
      ..add(OrderStatusChange(status: newStatus, changedAt: timestamp));

    return Order(
      id: id,
      customerId: customerId,
      storeId: storeId,
      items: items,
      status: newStatus,
      deliveryMethod: deliveryMethod,
      deliveryMode: deliveryMode,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      missingContainersFee: missingContainersFee,
      deliveryFee: deliveryFee,
      createdAt: createdAt,
      confirmedAt: newStatus == OrderStatus.confirmed
          ? (confirmedAt ?? timestamp)
          : this.confirmedAt,
      rejectionReason: newStatus == OrderStatus.rejected
          ? rejectionReason!.trim()
          : this.rejectionReason,
      statusHistory: history,
    );
  }

  /// Crea una copia con las decisiones de checkout actualizadas.
  Order copyWithCheckout({
    DeliveryMode? deliveryMode,
    PaymentMethod? paymentMethod,
    double? deliveryFee,
  }) {
    final newMode = deliveryMode ?? this.deliveryMode;
    final newMethod = switch (newMode) {
      DeliveryMode.pickupAtStore => OrderDeliveryMethod.pickup,
      DeliveryMode.ownDelivery => OrderDeliveryMethod.storeDelivery,
      DeliveryMode.externalDriver => OrderDeliveryMethod.externalDelivery,
    };
    return Order(
      id: id,
      customerId: customerId,
      storeId: storeId,
      items: items,
      status: status,
      deliveryMethod: newMethod,
      deliveryMode: newMode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress,
      missingContainersFee: missingContainersFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      createdAt: createdAt,
      confirmedAt: confirmedAt,
      rejectionReason: rejectionReason,
      statusHistory: statusHistory,
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
    final newMode = switch (newMethod) {
      OrderDeliveryMethod.pickup => DeliveryMode.pickupAtStore,
      OrderDeliveryMethod.storeDelivery => DeliveryMode.ownDelivery,
      OrderDeliveryMethod.externalDelivery => DeliveryMode.externalDriver,
    };
    return Order(
      id: id,
      customerId: customerId,
      storeId: storeId,
      items: items,
      status: OrderStatus.preparing,
      deliveryMethod: newMethod,
      deliveryMode: newMode,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      missingContainersFee: missingContainersFee,
      deliveryFee: deliveryFee,
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
            newStatus == OrderStatus.lookingForDriver ||
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
        newStatus == OrderStatus.noDriversAvailable ||
            newStatus == OrderStatus.driverAssigned ||
            newStatus == OrderStatus.confirmed ||
            newStatus == OrderStatus.cancelled,
      OrderStatus.noDriversAvailable =>
        newStatus == OrderStatus.lookingForDriver ||
            newStatus == OrderStatus.cancelled ||
            newStatus == OrderStatus.preparing,
      OrderStatus.driverAssigned =>
        deliveryMethod == OrderDeliveryMethod.externalDelivery &&
            newStatus == OrderStatus.inDelivery,
      OrderStatus.inDelivery => newStatus == OrderStatus.delivered,
      OrderStatus.rejected ||
      OrderStatus.delivered ||
      OrderStatus.cancelled => false,
    };
  }
}
