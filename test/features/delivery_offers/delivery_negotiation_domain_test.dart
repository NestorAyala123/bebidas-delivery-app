import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/delivery_offers/domain/entities/delivery_offer.dart';
import 'package:bebidas_delivery_app/features/delivery_offers/domain/services/delivery_lifecycle_service.dart';
import 'package:bebidas_delivery_app/features/delivery_offers/domain/services/offer_negotiation_service.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';

void main() {
  const negotiationService = OfferNegotiationService();
  const lifecycleService = DeliveryLifecycleService();
  final now = DateTime(2026, 11, 15, 10);

  DeliveryOffer offer({
    required String id,
    required String driverId,
    required double amount,
    bool counterOffer = false,
    DeliveryOfferStatus status = DeliveryOfferStatus.pending,
  }) {
    return DeliveryOffer(
      id: id,
      deliveryRequestId: 'req-test',
      driverId: driverId,
      driverName: 'Repartidor $driverId',
      offeredAmount: amount,
      isCounterOffer: counterOffer,
      status: status,
      createdAt: now,
    );
  }

  group('Comparación de ofertas', () {
    test('identifica la mejor oferta, promedio y contraofertas', () {
      final comparison = negotiationService.compareOffers([
        offer(id: 'o1', driverId: 'd1', amount: 3.50),
        offer(id: 'o2', driverId: 'd2', amount: 2.75, counterOffer: true),
        offer(id: 'o3', driverId: 'd3', amount: 4.00, counterOffer: true),
      ]);

      expect(comparison.offerCount, 3);
      expect(comparison.cheapest?.id, 'o2');
      expect(comparison.mostExpensive?.id, 'o3');
      expect(comparison.averageAmount, closeTo(3.4166, 0.001));
      expect(comparison.spread, closeTo(1.25, 0.001));
      expect(comparison.counterOfferCount, 2);
      expect(comparison.savingsVsReference(3.50), closeTo(0.75, 0.001));
    });

    test('ignora ofertas cerradas o rechazadas', () {
      final comparison = negotiationService.compareOffers([
        offer(id: 'o1', driverId: 'd1', amount: 3.00),
        offer(
          id: 'o2',
          driverId: 'd2',
          amount: 1.00,
          status: DeliveryOfferStatus.closedByAnotherAcceptance,
        ),
        offer(
          id: 'o3',
          driverId: 'd3',
          amount: 1.50,
          status: DeliveryOfferStatus.rejected,
        ),
      ]);

      expect(comparison.offerCount, 1);
      expect(comparison.cheapest?.id, 'o1');
    });
  });

  group('Ciclo de vida de la entrega', () {
    test('avanza en orden hasta entregado y no permite retroceder', () {
      expect(
        lifecycleService.nextStatus(DeliveryStatus.pendingOffer),
        DeliveryStatus.driverAssigned,
      );
      expect(
        lifecycleService.nextStatus(DeliveryStatus.driverAssigned),
        DeliveryStatus.arrivedAtStore,
      );
      expect(
        lifecycleService.nextStatus(DeliveryStatus.onTheWay),
        DeliveryStatus.delivered,
      );
      expect(lifecycleService.nextStatus(DeliveryStatus.delivered), isNull);

      expect(
        lifecycleService.canTransition(
          DeliveryStatus.pendingOffer,
          DeliveryStatus.onTheWay,
        ),
        isFalse,
      );
      expect(
        lifecycleService.canTransition(
          DeliveryStatus.onTheWay,
          DeliveryStatus.cancelled,
        ),
        isTrue,
      );
      expect(
        lifecycleService.canTransition(
          DeliveryStatus.delivered,
          DeliveryStatus.cancelled,
        ),
        isFalse,
      );
      expect(lifecycleService.canRate(DeliveryStatus.delivered), isTrue);
      expect(lifecycleService.canRate(DeliveryStatus.onTheWay), isFalse);
    });
  });

  group('Selección única RN06', () {
    test('acepta una sola oferta y cierra el resto', () {
      final updated = negotiationService.selectDriverOffer(
        currentOffers: [
          offer(id: 'o1', driverId: 'd1', amount: 3.00),
          offer(id: 'o2', driverId: 'd2', amount: 2.50),
        ],
        selectedOfferId: 'o2',
      );

      expect(
        updated.firstWhere((o) => o.id == 'o2').status,
        DeliveryOfferStatus.accepted,
      );
      expect(
        updated.firstWhere((o) => o.id == 'o1').status,
        DeliveryOfferStatus.closedByAnotherAcceptance,
      );
    });

    test('rechaza una segunda aceptación sobre la misma entrega', () {
      final alreadySelected = [
        offer(id: 'o1', driverId: 'd1', amount: 3.00),
        offer(
          id: 'o2',
          driverId: 'd2',
          amount: 2.50,
          status: DeliveryOfferStatus.accepted,
        ),
      ];

      expect(
        () => negotiationService.selectDriverOffer(
          currentOffers: alreadySelected,
          selectedOfferId: 'o1',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
