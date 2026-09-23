import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/delivery_offers/domain/entities/delivery_offer.dart';
import 'package:bebidas_delivery_app/features/delivery_offers/domain/services/offer_negotiation_service.dart';

void main() {
  group('Delivery Negotiation Rules (RN06 & RN03)', () {
    const service = OfferNegotiationService();

    test('RN06: Selecting an offer marks it accepted and closes all other pending offers', () {
      final now = DateTime.now();
      final offers = [
        DeliveryOffer(
          id: 'offer-1',
          deliveryRequestId: 'req-1',
          driverId: 'drv-1',
          driverName: 'Carlos',
          offeredAmount: 15.0,
          status: DeliveryOfferStatus.pending,
          createdAt: now,
        ),
        DeliveryOffer(
          id: 'offer-2',
          deliveryRequestId: 'req-1',
          driverId: 'drv-2',
          driverName: 'Marcos',
          offeredAmount: 14.0,
          status: DeliveryOfferStatus.pending,
          createdAt: now,
        ),
        DeliveryOffer(
          id: 'offer-3',
          deliveryRequestId: 'req-1',
          driverId: 'drv-3',
          driverName: 'Lucía',
          offeredAmount: 16.0,
          status: DeliveryOfferStatus.pending,
          createdAt: now,
        ),
      ];

      // Client accepts offer-2
      final updatedOffers = service.selectDriverOffer(
        currentOffers: offers,
        selectedOfferId: 'offer-2',
      );

      final accepted = updatedOffers.firstWhere((o) => o.id == 'offer-2');
      final closed1 = updatedOffers.firstWhere((o) => o.id == 'offer-1');
      final closed3 = updatedOffers.firstWhere((o) => o.id == 'offer-3');

      expect(accepted.status, equals(DeliveryOfferStatus.accepted));
      expect(closed1.status, equals(DeliveryOfferStatus.closedByAnotherAcceptance));
      expect(closed3.status, equals(DeliveryOfferStatus.closedByAnotherAcceptance));
    });

    test('RN03: Validates available actions when no drivers are around', () {
      // Store does NOT have own delivery, but allows pickup
      expect(
        service.canSelectNoDriversAction(
          action: NoDriversAction.useStoreOwnDelivery,
          storeHasOwnDelivery: false,
          storeAllowsPickup: true,
        ),
        isFalse,
      );

      expect(
        service.canSelectNoDriversAction(
          action: NoDriversAction.pickupAtStore,
          storeHasOwnDelivery: false,
          storeAllowsPickup: true,
        ),
        isTrue,
      );

      expect(
        service.canSelectNoDriversAction(
          action: NoDriversAction.increaseOffer,
          storeHasOwnDelivery: false,
          storeAllowsPickup: true,
        ),
        isTrue,
      );
    });
  });
}
