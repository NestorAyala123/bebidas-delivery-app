/// Representa los estados del ciclo de vida de una oferta o contraoferta
/// presentada por un repartidor para una solicitud de delivery.
/// 100% pure Dart, independiente de Flutter y Firebase.
enum OfferStatus {
  /// Oferta creada por el repartidor y en espera de evaluación por el solicitante.
  pending,

  /// Oferta aceptada por el solicitante autorizado. El repartidor gana la asignación.
  accepted,

  /// Oferta rechazada explícitamente por el solicitante autorizado.
  rejected,

  /// Oferta descartada automáticamente por asignación de otra oferta o cancelación de la solicitud.
  discarded;

  /// Indica si el estado es terminal. Una vez alcanzado, no se admiten más transiciones.
  bool get isTerminal =>
      this == OfferStatus.accepted ||
      this == OfferStatus.rejected ||
      this == OfferStatus.discarded;

  /// Indica si la oferta aún se encuentra activa y pendiente de respuesta.
  bool get isPending => this == OfferStatus.pending;

  /// Valida si este estado puede transicionar conceptualmente a [nextStatus].
  bool canTransitionTo(OfferStatus nextStatus) {
    if (this == nextStatus) return false;

    return switch (this) {
      OfferStatus.pending =>
        nextStatus == OfferStatus.accepted ||
            nextStatus == OfferStatus.rejected ||
            nextStatus == OfferStatus.discarded,
      OfferStatus.accepted => false,
      OfferStatus.rejected => false,
      OfferStatus.discarded => false,
    };
  }
}
