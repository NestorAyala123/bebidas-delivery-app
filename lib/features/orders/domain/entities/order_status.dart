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
}
