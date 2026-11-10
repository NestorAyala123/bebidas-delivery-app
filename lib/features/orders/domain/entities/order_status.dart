/// Order lifecycle states
enum OrderStatus {
  created,
  confirmed,
  rejected,
  preparing,
  readyForPickup,
  pickedUp,
  readyForDelivery,
  lookingForDriver,
  driverAssigned,
  inDelivery,
  delivered,
  cancelled;

  /// RN01: El establecimiento debe confirmar el pedido antes de buscar repartidor.
  bool get canSearchDriver => this == OrderStatus.confirmed;

  bool get isTerminal =>
      this == OrderStatus.delivered ||
      this == OrderStatus.rejected ||
      this == OrderStatus.cancelled;

  bool get canBeCancelled =>
      this == OrderStatus.created ||
      this == OrderStatus.confirmed ||
      this == OrderStatus.preparing ||
      this == OrderStatus.readyForPickup ||
      this == OrderStatus.readyForDelivery ||
      this == OrderStatus.lookingForDriver;

  /// Indica si el pedido está en estado inicial pendiente de confirmación
  bool get isPending => this == OrderStatus.created;

  /// Nombre legible para interfaces de usuario
  String get displayName => switch (this) {
        OrderStatus.created => 'Pendiente',
        OrderStatus.confirmed => 'Confirmado',
        OrderStatus.rejected => 'Rechazado',
        OrderStatus.preparing => 'En preparación',
        OrderStatus.readyForPickup => 'Listo para retirar',
        OrderStatus.pickedUp => 'Retirado',
        OrderStatus.readyForDelivery => 'Listo para entrega',
        OrderStatus.lookingForDriver => 'Buscando Repartidor',
        OrderStatus.driverAssigned => 'Repartidor Asignado',
        OrderStatus.inDelivery => 'En Camino',
        OrderStatus.delivered => 'Entregado',
        OrderStatus.cancelled => 'Cancelado',
      };
}

class OrderStatusChange {
  final OrderStatus status;
  final DateTime changedAt;

  const OrderStatusChange({required this.status, required this.changedAt});
}
