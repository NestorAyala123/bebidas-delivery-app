import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';
import 'package:bebidas_delivery_app/features/delivery_offers/domain/entities/delivery_offer.dart';
import 'package:bebidas_delivery_app/features/delivery_offers/infrastructure/repositories/in_memory_delivery_negotiation_repository.dart';
import 'package:bebidas_delivery_app/features/delivery_offers/presentation/controllers/delivery_negotiation_controller.dart';

void main() {
  late InMemoryDeliveryNegotiationRepository repository;
  late DeliveryNegotiationController controller;

  setUp(() {
    repository = InMemoryDeliveryNegotiationRepository();
    controller = DeliveryNegotiationController(repository: repository);
  });

  tearDown(() => controller.dispose());

  Future<void> openPendingNegotiation() async {
    await controller.loadNegotiation('req-demo-01');
  }

  group('DeliveryNegotiationController', () {
    test('carga la negociación pendiente con su propuesta', () async {
      await openPendingNegotiation();

      final negotiation = controller.negotiation;
      expect(negotiation, isNotNull);
      expect(negotiation!.status, DeliveryStatus.pendingOffer);
      expect(negotiation.customerOffer, 3.00);
      expect(negotiation.referenceFare, 3.50);
      expect(negotiation.offers, isEmpty);
      expect(controller.comparison.hasOffers, isFalse);
    });

    test('compara dos ofertas y permite seleccionar solo una (RN06)', () async {
      await openPendingNegotiation();

      expect(await controller.simulateTwoDriverOffers(), isTrue);
      var negotiation = controller.negotiation!;
      expect(negotiation.offers.length, 2);
      expect(controller.comparison.hasMultipleOffers, isTrue);
      expect(controller.comparison.cheapest?.driverName, 'Marcos Vera');
      expect(controller.comparison.cheapest?.isCounterOffer, isTrue);

      final selected = controller.comparison.cheapest!;
      final other = negotiation.offers.firstWhere(
        (offer) => offer.id != selected.id,
      );

      expect(await controller.selectOffer(selected.id), isTrue);
      negotiation = controller.negotiation!;
      expect(negotiation.status, DeliveryStatus.driverAssigned);
      expect(negotiation.acceptedOffer?.id, selected.id);
      expect(negotiation.agreedFare, selected.offeredAmount);
      expect(
        negotiation.offers.firstWhere((o) => o.id == other.id).status,
        DeliveryOfferStatus.closedByAnotherAcceptance,
      );

      // La segunda aceptación debe fallar y no alterar la asignación.
      expect(await controller.selectOffer(other.id), isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.negotiation!.status, DeliveryStatus.driverAssigned);
      expect(controller.negotiation!.acceptedOffer?.id, selected.id);
    });

    test(
      'recorre los estados de entrega, califica y guarda historial',
      () async {
        await openPendingNegotiation();
        await controller.simulateTwoDriverOffers();
        await controller.selectOffer(controller.comparison.cheapest!.id);

        for (final expected in [
          DeliveryStatus.arrivedAtStore,
          DeliveryStatus.pickedUp,
          DeliveryStatus.onTheWay,
          DeliveryStatus.delivered,
        ]) {
          expect(await controller.advanceStatus(), isTrue);
          expect(controller.negotiation!.status, expected);
        }

        expect(controller.negotiation!.canRate, isTrue);
        expect(
          await controller.rateDelivery(4, comment: 'Entrega puntual'),
          isTrue,
        );
        expect(controller.negotiation!.rating?.stars, 4);
        expect(controller.negotiation!.canRate, isFalse);
        expect(await controller.rateDelivery(5), isFalse);

        await controller.loadHistory('customer-demo');
        final historyItem = controller.history.firstWhere(
          (item) => item.id == 'req-demo-01',
        );
        expect(historyItem.status, DeliveryStatus.delivered);
        expect(historyItem.rating?.comment, 'Entrega puntual');
        expect(historyItem.history.length, greaterThan(4));
      },
    );

    test('valida la propuesta del cliente antes de guardarla', () async {
      await openPendingNegotiation();

      expect(await controller.proposeClientOffer(0.50), isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.negotiation!.customerOffer, 3.00);

      expect(await controller.proposeClientOffer(250), isFalse);
      expect(controller.negotiation!.customerOffer, 3.00);

      expect(await controller.proposeClientOffer(4.00), isTrue);
      expect(controller.negotiation!.customerOffer, 4.00);
    });

    test('cancela una entrega activa y la conserva en historial', () async {
      await openPendingNegotiation();
      await controller.simulateTwoDriverOffers();
      await controller.selectOffer(controller.comparison.cheapest!.id);

      expect(
        await controller.cancelDelivery(reason: 'Cambio de planes'),
        isTrue,
      );
      expect(controller.negotiation!.status, DeliveryStatus.cancelled);
      expect(await controller.advanceStatus(), isFalse);

      await controller.loadHistory('customer-demo');
      final cancelled = controller.history.firstWhere(
        (item) => item.id == 'req-demo-01',
      );
      expect(cancelled.status, DeliveryStatus.cancelled);
      expect(
        cancelled.history.any(
          (event) => event.description.contains('Cambio de planes'),
        ),
        isTrue,
      );
    });
  });
}
