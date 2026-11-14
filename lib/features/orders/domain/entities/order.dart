import '../../../delivery/domain/entities/delivery_mode.dart';
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
  final String deliveryAddress;
  final double missingContainersFee;
  final DeliveryMode deliveryMode;
  final PaymentMethod? paymentMethod;
  final double deliveryFee;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  const Order({
    required this.id,
    required this.customerId,
    required this.storeId,
    required this.items,
    required this.status,
    required this.deliveryAddress,
    this.missingContainersFee = 0.0,
    this.deliveryMode = DeliveryMode.externalDriver,
    this.paymentMethod,
    this.deliveryFee = 0.0,
    required this.createdAt,
    this.confirmedAt,
  })  : assert(items.length > 0, 'Un pedido debe tener al menos un item'),
        assert(deliveryFee >= 0, 'El costo de envío no puede ser negativo');

  /// Subtotal calculated from frozen prices
  double get itemsSubtotal =>
      items.fold(0.0, (acc, item) => acc + item.subtotal);

  /// Final total including missing containers fee and delivery fee
  double get total => itemsSubtotal + missingContainersFee + deliveryFee;

  /// RN01: El establecimiento debe confirmar el pedido antes de buscar repartidor.
  bool get canRequestDriver => status.canSearchDriver;

  /// Indica si el cliente ya eligió cómo pagar.
  bool get isPaymentRegistered => paymentMethod != null;

  /// Solo se confirma el checkout con modalidad y pago registrados.
  bool get isCheckoutReady => isPaymentRegistered;

  /// RN02: modalidad seleccionada por el cliente.
  bool get isPickup => deliveryMode.isPickup;
  bool get usesExternalDriver => deliveryMode.requiresExternalDriver;

  /// Creates a copy with an updated status
  Order copyWithStatus(OrderStatus newStatus, {DateTime? confirmedAt}) {
    return Order(
      id: id,
      customerId: customerId,
      storeId: storeId,
      items: items,
      status: newStatus,
      deliveryAddress: deliveryAddress,
      missingContainersFee: missingContainersFee,
      deliveryMode: deliveryMode,
      paymentMethod: paymentMethod,
      deliveryFee: deliveryFee,
      createdAt: createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  /// Crea una copia con las decisiones de checkout actualizadas.
  Order copyWithCheckout({
    DeliveryMode? deliveryMode,
    PaymentMethod? paymentMethod,
    double? deliveryFee,
  }) {
    return Order(
      id: id,
      customerId: customerId,
      storeId: storeId,
      items: items,
      status: status,
      deliveryAddress: deliveryAddress,
      missingContainersFee: missingContainersFee,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      createdAt: createdAt,
      confirmedAt: confirmedAt,
    );
  }
}
