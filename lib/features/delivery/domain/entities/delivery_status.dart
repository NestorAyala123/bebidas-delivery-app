/// Represents the lifecycle states of a delivery request and its execution.
enum DeliveryStatus {
  /// Solicitud de delivery creada, esperando ofertas de repartidores
  pendingOffer,

  /// Repartidor asignado tras aceptar una oferta
  driverAssigned,

  /// Repartidor llegó al comercio/tienda
  arrivedAtStore,

  /// Repartidor recogió los productos en el local
  pickedUp,

  /// Pedido en tránsito hacia el domicilio del cliente
  onTheWay,

  /// Pedido entregado exitosamente al cliente
  delivered,

  /// Solicitud o entrega cancelada
  cancelled;

  bool get isTerminal =>
      this == DeliveryStatus.delivered || this == DeliveryStatus.cancelled;

  bool get isActive => !isTerminal;

  bool get isAssigned =>
      this == DeliveryStatus.driverAssigned ||
      this == DeliveryStatus.arrivedAtStore ||
      this == DeliveryStatus.pickedUp ||
      this == DeliveryStatus.onTheWay;
}

/// Backwards compatibility alias for existing code
typedef DeliveryExecutionStatus = DeliveryStatus;
