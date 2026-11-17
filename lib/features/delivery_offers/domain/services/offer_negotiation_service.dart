import '../../../../core/errors/exceptions.dart';
import '../entities/delivery_offer.dart';

/// Client actions when no drivers are available (RN03)
enum NoDriversAction {
  wait,
  increaseOffer,
  pickupAtStore,
  useStoreOwnDelivery,
  cancelOrder,
}

/// Resumen comparativo de las ofertas recibidas para una entrega.
class OfferComparison {
  final List<DeliveryOffer> offers;
  final DeliveryOffer? cheapest;
  final DeliveryOffer? mostExpensive;
  final double averageAmount;
  final int counterOfferCount;

  const OfferComparison({
    required this.offers,
    this.cheapest,
    this.mostExpensive,
    required this.averageAmount,
    required this.counterOfferCount,
  });

  bool get hasOffers => offers.isNotEmpty;
  int get offerCount => offers.length;

  bool get hasMultipleOffers => offers.length > 1;

  /// Diferencia entre la oferta más alta y la más baja.
  double get spread {
    if (cheapest == null || mostExpensive == null) return 0;
    return mostExpensive!.offeredAmount - cheapest!.offeredAmount;
  }

  /// Ahorro de la mejor oferta frente a la tarifa referencial.
  double savingsVsReference(double referenceFare) {
    if (cheapest == null) return 0;
    return referenceFare - cheapest!.offeredAmount;
  }
}

/// Domain service that encapsulates delivery negotiation rules, including RN06 and RN03.
class OfferNegotiationService {
  const OfferNegotiationService();

  /// Enforces RN06:
  /// When a client selects a driver's offer, that offer becomes [accepted]
  /// and all other pending offers for the same delivery request are immediately closed
  /// with [closedByAnotherAcceptance].
  List<DeliveryOffer> selectDriverOffer({
    required List<DeliveryOffer> currentOffers,
    required String selectedOfferId,
  }) {
    final selectedOfferIndex = currentOffers.indexWhere(
      (o) => o.id == selectedOfferId,
    );
    if (selectedOfferIndex < 0) {
      throw const DomainException(
        'La oferta seleccionada no existe en la lista',
      );
    }

    final selectedOffer = currentOffers[selectedOfferIndex];
    if (selectedOffer.status != DeliveryOfferStatus.pending) {
      throw const DomainException(
        'Solo se pueden aceptar ofertas en estado pendiente',
      );
    }

    final alreadyAccepted = currentOffers.where(
      (offer) => offer.status == DeliveryOfferStatus.accepted,
    );
    if (alreadyAccepted.isNotEmpty) {
      throw const DomainException(
        'La entrega ya tiene un repartidor asignado; no se puede aceptar otra oferta',
      );
    }

    final belongsToAnotherRequest = currentOffers.any(
      (offer) => offer.deliveryRequestId != selectedOffer.deliveryRequestId,
    );
    if (belongsToAnotherRequest) {
      throw const DomainException(
        'Todas las ofertas deben pertenecer a la misma solicitud de entrega',
      );
    }

    return currentOffers.map((offer) {
      if (offer.id == selectedOfferId) {
        return offer.copyWithStatus(DeliveryOfferStatus.accepted);
      } else if (offer.status == DeliveryOfferStatus.pending) {
        // RN06: Todas las demás ofertas pendientes se cierran
        return offer.copyWithStatus(
          DeliveryOfferStatus.closedByAnotherAcceptance,
        );
      }
      return offer;
    }).toList();
  }

  /// Valida la propuesta económica del cliente.
  bool isValidClientOffer({
    required double amount,
    required double referenceFare,
  }) {
    if (amount.isNaN || amount.isInfinite) return false;
    if (amount < 1 || amount > 200) return false;
    return amount <= referenceFare * 3;
  }

  /// Compara las ofertas pendientes (o la aceptada) de una negociación.
  OfferComparison compareOffers(List<DeliveryOffer> offers) {
    final candidates = offers
        .where(
          (offer) =>
              offer.status == DeliveryOfferStatus.pending ||
              offer.status == DeliveryOfferStatus.accepted,
        )
        .toList(growable: false);

    if (candidates.isEmpty) {
      return const OfferComparison(
        offers: [],
        averageAmount: 0,
        counterOfferCount: 0,
      );
    }

    var cheapest = candidates.first;
    var mostExpensive = candidates.first;
    var total = 0.0;
    var counterOffers = 0;

    for (final offer in candidates) {
      if (offer.offeredAmount < cheapest.offeredAmount) cheapest = offer;
      if (offer.offeredAmount > mostExpensive.offeredAmount) {
        mostExpensive = offer;
      }
      total += offer.offeredAmount;
      if (offer.isCounterOffer) counterOffers++;
    }

    return OfferComparison(
      offers: List.unmodifiable(candidates),
      cheapest: cheapest,
      mostExpensive: mostExpensive,
      averageAmount: total / candidates.length,
      counterOfferCount: counterOffers,
    );
  }

  /// Validates if an action is valid according to store capabilities (RN03)
  bool canSelectNoDriversAction({
    required NoDriversAction action,
    required bool storeHasOwnDelivery,
    required bool storeAllowsPickup,
  }) {
    return switch (action) {
      NoDriversAction.wait => true,
      NoDriversAction.increaseOffer => true,
      NoDriversAction.pickupAtStore => storeAllowsPickup,
      NoDriversAction.useStoreOwnDelivery => storeHasOwnDelivery,
      NoDriversAction.cancelOrder => true,
    };
  }
}
