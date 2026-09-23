import 'order_item.dart';
import 'order_status.dart';

/// Core Order domain entity.
/// Enforces RN01, RN07, RN08.
class Order {
  final String id;
  final String customerId;
  final String storeId; // RN07: Un pedido pertenece a un solo establecimiento
  final List<OrderItem> items;
  final OrderStatus status;
  final String deliveryAddress;
  final double missingContainersFee;
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
    required this.createdAt,
    this.confirmedAt,
  }) : assert(items.length > 0, 'Un pedido debe tener al menos un item');

  /// Subtotal calculated from frozen prices
  double get itemsSubtotal =>
      items.fold(0.0, (acc, item) => acc + item.subtotal);

  /// Final total including missing containers fee
  double get total => itemsSubtotal + missingContainersFee;

  /// RN01: El establecimiento debe confirmar el pedido antes de buscar repartidor.
  bool get canRequestDriver => status.canSearchDriver;

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
      createdAt: createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }
}
