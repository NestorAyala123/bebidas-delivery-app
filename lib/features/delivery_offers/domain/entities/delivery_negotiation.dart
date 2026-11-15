import '../../../delivery/domain/entities/delivery_request.dart';
import '../../../delivery/domain/entities/delivery_status.dart';
import 'delivery_negotiation_event.dart';
import 'delivery_offer.dart';
import 'delivery_rating.dart';

/// Agregado que reúne una solicitud de entrega, las ofertas de los
/// repartidores, el historial de eventos y la calificación final.
class DeliveryNegotiation {
  final DeliveryRequest request;
  final List<DeliveryOffer> offers;
  final List<DeliveryNegotiationEvent> history;
  final String? assignedOfferId;
  final double? agreedFare;
  final DeliveryRating? rating;

  DeliveryNegotiation({
    required this.request,
    List<DeliveryOffer> offers = const [],
    List<DeliveryNegotiationEvent> history = const [],
    this.assignedOfferId,
    this.agreedFare,
    this.rating,
  }) : offers = List.unmodifiable(offers),
       history = List.unmodifiable(history);

  String get id => request.id;
  DeliveryStatus get status => request.status;
  double get referenceFare => request.referenceFare;
  double get customerOffer =>
      request.initialCustomerOffer ?? request.referenceFare;

  List<DeliveryOffer> get pendingOffers =>
      offers.where((offer) => offer.status.isActive).toList(growable: false);

  DeliveryOffer? get acceptedOffer {
    for (final offer in offers) {
      if (offer.status == DeliveryOfferStatus.accepted) return offer;
    }
    return null;
  }

  /// Ofertas que se comparan en la UI: las pendientes o, si ya se eligió,
  /// la oferta aceptada.
  List<DeliveryOffer> get comparableOffers {
    final pending = pendingOffers;
    if (pending.isNotEmpty) return pending;
    final accepted = acceptedOffer;
    return accepted == null ? const [] : [accepted];
  }

  DeliveryOffer? get bestPricedOffer {
    final candidates = comparableOffers;
    if (candidates.isEmpty) return null;
    return candidates.reduce(
      (current, offer) =>
          offer.offeredAmount < current.offeredAmount ? offer : current,
    );
  }

  bool get isAwaitingOffers => status == DeliveryStatus.pendingOffer;
  bool get isAssigned => status.isAssigned;
  bool get isFinished => status.isTerminal;
  bool get hasRating => rating != null;
  bool get canRate => status == DeliveryStatus.delivered && rating == null;
  bool get hasSelection => assignedOfferId != null;

  double? get savingsVsReference {
    final fare = agreedFare;
    if (fare == null) return null;
    return referenceFare - fare;
  }

  /// Progreso de la entrega entre 0 y 1 para la barra de avance.
  double get progress => switch (status) {
    DeliveryStatus.pendingOffer => 0.1,
    DeliveryStatus.driverAssigned => 0.3,
    DeliveryStatus.arrivedAtStore => 0.5,
    DeliveryStatus.pickedUp => 0.65,
    DeliveryStatus.onTheWay => 0.85,
    DeliveryStatus.delivered => 1,
    DeliveryStatus.cancelled => 0,
  };

  DeliveryNegotiation copyWith({
    DeliveryRequest? request,
    List<DeliveryOffer>? offers,
    List<DeliveryNegotiationEvent>? history,
    String? assignedOfferId,
    double? agreedFare,
    DeliveryRating? rating,
  }) {
    return DeliveryNegotiation(
      request: request ?? this.request,
      offers: offers ?? this.offers,
      history: history ?? this.history,
      assignedOfferId: assignedOfferId ?? this.assignedOfferId,
      agreedFare: agreedFare ?? this.agreedFare,
      rating: rating ?? this.rating,
    );
  }

  DeliveryNegotiation withEvent(DeliveryNegotiationEvent event) {
    return copyWith(history: [...history, event]);
  }

  @override
  String toString() =>
      'DeliveryNegotiation(id: $id, status: ${status.name}, '
      'offers: ${offers.length}, agreedFare: $agreedFare)';
}
