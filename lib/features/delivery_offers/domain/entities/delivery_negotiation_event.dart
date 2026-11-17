/// Tipo de evento registrado en el historial de una negociación de entrega.
enum DeliveryNegotiationEventType {
  requestCreated,
  clientOfferUpdated,
  driverOfferReceived,
  offerSelected,
  offerClosed,
  statusChanged,
  deliveryCancelled,
  deliveryRated;

  String get label => switch (this) {
    DeliveryNegotiationEventType.requestCreated => 'Solicitud creada',
    DeliveryNegotiationEventType.clientOfferUpdated => 'Propuesta actualizada',
    DeliveryNegotiationEventType.driverOfferReceived => 'Oferta recibida',
    DeliveryNegotiationEventType.offerSelected => 'Oferta seleccionada',
    DeliveryNegotiationEventType.offerClosed => 'Oferta cerrada',
    DeliveryNegotiationEventType.statusChanged => 'Cambio de estado',
    DeliveryNegotiationEventType.deliveryCancelled => 'Entrega cancelada',
    DeliveryNegotiationEventType.deliveryRated => 'Entrega calificada',
  };
}

/// Entrada del historial de la negociación.
class DeliveryNegotiationEvent {
  final String id;
  final DeliveryNegotiationEventType type;
  final String description;
  final double? amount;
  final String? driverId;
  final DateTime createdAt;

  const DeliveryNegotiationEvent({
    required this.id,
    required this.type,
    required this.description,
    this.amount,
    this.driverId,
    required this.createdAt,
  });

  @override
  String toString() =>
      'DeliveryNegotiationEvent(type: ${type.name}, description: $description)';
}
