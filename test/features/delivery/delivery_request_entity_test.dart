import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/exceptions.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_mode.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';

void main() {
  group('DeliveryRequest Domain Entity Tests', () {
    final testDate = DateTime(2026, 9, 23, 12, 0);

    DeliveryRequest createSampleRequest({
      String id = 'del-001',
      String orderId = 'ord-100',
      String customerId = 'usr-1',
      String storeId = 'store-1',
      String originAddress = 'Av. Larco 456, Miraflores',
      String destinationAddress = 'Calle Berlin 123, Miraflores',
      double? distanceInKm = 2.5,
      double referenceFare = 12.0,
      DeliveryStatus status = DeliveryStatus.pendingOffer,
      String? assignedDriverId,
      int? agreedFareInCents,
      bool isOrderConfirmedByStore = true,
    }) {
      return DeliveryRequest(
        id: id,
        orderId: orderId,
        customerId: customerId,
        storeId: storeId,
        originAddress: originAddress,
        destinationAddress: destinationAddress,
        distanceInKm: distanceInKm,
        referenceFare: referenceFare,
        status: status,
        assignedDriverId: assignedDriverId,
        agreedFareInCents: agreedFareInCents,
        isOrderConfirmedByStore: isOrderConfirmedByStore,
        createdAt: testDate,
      );
    }

    test('Creates valid DeliveryRequest with all required fields', () {
      final request = createSampleRequest();

      expect(request.id, equals('del-001'));
      expect(request.orderId, equals('ord-100'));
      expect(request.originAddress, equals('Av. Larco 456, Miraflores'));
      expect(
        request.destinationAddress,
        equals('Calle Berlin 123, Miraflores'),
      );
      expect(request.distanceInKm, equals(2.5));
      expect(request.referenceFare, equals(12.0));
      expect(
        request.suggestedFee,
        equals(12.0),
      ); // Backwards compatibility getter
      expect(request.status, equals(DeliveryStatus.pendingOffer));
      expect(request.status.isActive, isTrue);
      expect(request.status.isTerminal, isFalse);
      expect(request.assignedDriverId, isNull);
      expect(request.agreedFareInCents, isNull);
      expect(request.agreedFare, isNull);
    });

    test('Transitions status through delivery lifecycle', () {
      final request = createSampleRequest(distanceInKm: 3.0, referenceFare: 15.0);

      // Driver assigned
      final assigned = request.copyWithAssignedDriver(driverId: 'drv-777');
      expect(assigned.status, equals(DeliveryStatus.driverAssigned));
      expect(assigned.assignedDriverId, equals('drv-777'));
      expect(assigned.status.isAssigned, isTrue);

      // Arrived at store
      final atStore = assigned.copyWithStatus(DeliveryStatus.arrivedAtStore);
      expect(atStore.status, equals(DeliveryStatus.arrivedAtStore));
      expect(atStore.status.isAssigned, isTrue);

      // Picked up
      final pickedUp = atStore.copyWithStatus(DeliveryStatus.pickedUp);
      expect(pickedUp.status, equals(DeliveryStatus.pickedUp));

      // On the way
      final onTheWay = pickedUp.copyWithStatus(DeliveryStatus.onTheWay);
      expect(onTheWay.status, equals(DeliveryStatus.onTheWay));

      // Delivered (terminal)
      final delivered = onTheWay.copyWithStatus(DeliveryStatus.delivered);
      expect(delivered.status, equals(DeliveryStatus.delivered));
      expect(delivered.status.isTerminal, isTrue);
      expect(delivered.status.isActive, isFalse);
    });

    test('Throws DomainException when order is not confirmed for external driver (RN01)', () {
      expect(
        () => DeliveryRequest(
          id: 'del-002',
          orderId: 'ord-200',
          customerId: 'usr-2',
          storeId: 'store-1',
          originAddress: 'Av. Pardo 100',
          destinationAddress: 'Calle Schell 200',
          referenceFare: 10.0,
          deliveryMode: DeliveryMode.externalDriver,
          isOrderConfirmedByStore: false, // Unconfirmed
          createdAt: testDate,
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test('Throws AssertionError when origin or destination is empty or fee negative', () {
      expect(
        () => createSampleRequest(originAddress: ''),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => createSampleRequest(destinationAddress: ''),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => createSampleRequest(referenceFare: -5.0),
        throwsA(isA<AssertionError>()),
      );
    });

    group('Negociación de entrega: assignDriver y agreedFareInCents (Semana 5)', () {
      test('assignDriver asigna exitosamente el repartidor y la tarifa acordada', () {
        final request = createSampleRequest();

        final assigned = request.assignDriver(
          driverId: 'drv-888',
          agreedFareInCents: 450, // $4.50
        );

        expect(assigned.status, equals(DeliveryStatus.driverAssigned));
        expect(assigned.assignedDriverId, equals('drv-888'));
        expect(assigned.agreedFareInCents, equals(450));
        expect(assigned.agreedFare, equals(4.50));
        expect(assigned.status.isAssigned, isTrue);
      });

      test('assignDriver rechaza repartidor con id vacío', () {
        final request = createSampleRequest();

        expect(
          () => request.assignDriver(driverId: '  ', agreedFareInCents: 450),
          throwsA(isA<DomainException>()),
        );
      });

      test('assignDriver rechaza asignación si la solicitud no está en pendingOffer (RN-NEG-01)', () {
        final assignedRequest = createSampleRequest(
          status: DeliveryStatus.driverAssigned,
          assignedDriverId: 'drv-existing',
        );

        expect(
          () => assignedRequest.assignDriver(driverId: 'drv-new', agreedFareInCents: 450),
          throwsA(isA<DomainException>()),
        );

        final cancelledRequest = createSampleRequest(status: DeliveryStatus.cancelled);
        expect(
          () => cancelledRequest.assignDriver(driverId: 'drv-new', agreedFareInCents: 450),
          throwsA(isA<DomainException>()),
        );
      });

      test('assignDriver rechaza tarifas acordadas <= 0 o > 10.000.000 centavos (RN-NEG-03)', () {
        final request = createSampleRequest();

        expect(
          () => request.assignDriver(driverId: 'drv-1', agreedFareInCents: 0),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => request.assignDriver(driverId: 'drv-1', agreedFareInCents: -100),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => request.assignDriver(driverId: 'drv-1', agreedFareInCents: 10000001),
          throwsA(isA<DomainException>()),
        );
      });

      test('Constructor valida agreedFareInCents si se proporciona', () {
        expect(
          () => createSampleRequest(agreedFareInCents: 0),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => createSampleRequest(agreedFareInCents: -50),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => createSampleRequest(agreedFareInCents: 10000001),
          throwsA(isA<DomainException>()),
        );

        final valid = createSampleRequest(agreedFareInCents: 525);
        expect(valid.agreedFareInCents, equals(525));
        expect(valid.agreedFare, equals(5.25));
      });

      test('copyWith preserva agreedFareInCents', () {
        final request = createSampleRequest().assignDriver(
          driverId: 'drv-1',
          agreedFareInCents: 350,
        );

        final copied = request.copyWith(destinationAddress: 'Nueva dirección');
        expect(copied.destinationAddress, equals('Nueva dirección'));
        expect(copied.assignedDriverId, equals('drv-1'));
        expect(copied.agreedFareInCents, equals(350));
        expect(copied.agreedFare, equals(3.50));
      });
    });
  });
}
