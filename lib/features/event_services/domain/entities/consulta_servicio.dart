/// Estado del ciclo de vida de una consulta/cotización de evento
enum ConsultaServicioStatus {
  pendiente,
  respondida,
  aceptada,
  rechazada,
  cancelada,
}

/// Entidad pura de dominio que representa la consulta o solicitud de cotización
/// realizada por un cliente hacia una ficha de servicio de eventos.
class ConsultaServicio {
  final String id;
  final String serviceId;
  final String serviceTitle;
  final String providerId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String eventDate; // ISO-8601 o YYYY-MM-DD
  final int guestCount;
  final String location;
  final String notes;
  final double budgetOffered;
  final ConsultaServicioStatus status;
  final String createdAt;

  const ConsultaServicio({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.providerId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.eventDate,
    required this.guestCount,
    required this.location,
    this.notes = '',
    this.budgetOffered = 0.0,
    this.status = ConsultaServicioStatus.pendiente,
    required this.createdAt,
  });

  ConsultaServicio copyWith({
    String? id,
    String? serviceId,
    String? serviceTitle,
    String? providerId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? eventDate,
    int? guestCount,
    String? location,
    String? notes,
    double? budgetOffered,
    ConsultaServicioStatus? status,
    String? createdAt,
  }) {
    return ConsultaServicio(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      providerId: providerId ?? this.providerId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      eventDate: eventDate ?? this.eventDate,
      guestCount: guestCount ?? this.guestCount,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      budgetOffered: budgetOffered ?? this.budgetOffered,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsultaServicio &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ConsultaServicio(id: $id, service: $serviceTitle, status: $status)';
}
