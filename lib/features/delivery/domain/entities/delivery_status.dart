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

  /// Terminal states: Once reached, no further transitions are allowed
  bool get isTerminal =>
      this == DeliveryStatus.delivered || this == DeliveryStatus.cancelled;

  /// Active states: Ongoing delivery lifecycle
  bool get isActive => !isTerminal;

  /// Indicates a driver is currently assigned and responsible for this delivery
  bool get isAssigned =>
      this == DeliveryStatus.driverAssigned ||
      this == DeliveryStatus.arrivedAtStore ||
      this == DeliveryStatus.pickedUp ||
      this == DeliveryStatus.onTheWay;

  /// RN05: Evaluates if this status can conceptually transition to [nextStatus].
  bool canTransitionTo(DeliveryStatus nextStatus) {
    if (this == nextStatus) return false;

    return switch (this) {
      DeliveryStatus.pendingOffer =>
        nextStatus == DeliveryStatus.driverAssigned ||
            nextStatus == DeliveryStatus.cancelled,
      DeliveryStatus.driverAssigned =>
        nextStatus == DeliveryStatus.arrivedAtStore ||
            nextStatus == DeliveryStatus.cancelled,
      DeliveryStatus.arrivedAtStore =>
        nextStatus == DeliveryStatus.pickedUp ||
            nextStatus == DeliveryStatus.cancelled,
      DeliveryStatus.pickedUp =>
        nextStatus == DeliveryStatus.onTheWay ||
            nextStatus == DeliveryStatus.cancelled,
      DeliveryStatus.onTheWay =>
        nextStatus == DeliveryStatus.delivered ||
            nextStatus == DeliveryStatus.cancelled,
      DeliveryStatus.delivered => false,
      DeliveryStatus.cancelled => false,
    };
  }
}

/// Backwards compatibility alias for existing code
typedef DeliveryExecutionStatus = DeliveryStatus;
