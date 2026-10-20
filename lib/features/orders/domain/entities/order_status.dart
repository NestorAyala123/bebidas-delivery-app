/// Order lifecycle states
enum OrderStatus {
  created,
  confirmed,
  rejected,
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

  /// Indica si el pedido está en estado inicial pendiente de confirmación
  bool get isPending => this == OrderStatus.created;

  /// Nombre legible para interfaces de usuario
  String get displayName => switch (this) {
        OrderStatus.created => 'Pendiente',
        OrderStatus.confirmed => 'Confirmado',
        OrderStatus.rejected => 'Rechazado',
        OrderStatus.lookingForDriver => 'Buscando Repartidor',
        OrderStatus.driverAssigned => 'Repartidor Asignado',
        OrderStatus.inDelivery => 'En Camino',
        OrderStatus.delivered => 'Entregado',
        OrderStatus.cancelled => 'Cancelado',
      };
}
