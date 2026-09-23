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
    final selectedOfferIndex = currentOffers.indexWhere((o) => o.id == selectedOfferId);
    if (selectedOfferIndex < 0) {
      throw const DomainException('La oferta seleccionada no existe en la lista');
    }

    final selectedOffer = currentOffers[selectedOfferIndex];
    if (selectedOffer.status != DeliveryOfferStatus.pending) {
      throw const DomainException('Solo se pueden aceptar ofertas en estado pendiente');
    }

    return currentOffers.map((offer) {
      if (offer.id == selectedOfferId) {
        return offer.copyWithStatus(DeliveryOfferStatus.accepted);
      } else if (offer.status == DeliveryOfferStatus.pending) {
        // RN06: Todas las demás ofertas pendientes se cierran
        return offer.copyWithStatus(DeliveryOfferStatus.closedByAnotherAcceptance);
      }
      return offer;
    }).toList();
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
