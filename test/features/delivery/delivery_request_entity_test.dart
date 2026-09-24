import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/exceptions.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_mode.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';

void main() {
  group('DeliveryRequest Domain Entity Tests', () {
    final testDate = DateTime(2026, 9, 23, 12, 0);

    test('Creates valid DeliveryRequest with all required fields', () {
      final request = DeliveryRequest(
        id: 'del-001',
        orderId: 'ord-100',
        customerId: 'usr-1',
        storeId: 'store-1',
        originAddress: 'Av. Larco 456, Miraflores',
        destinationAddress: 'Calle Berlin 123, Miraflores',
        distanceInKm: 2.5,
        referenceFare: 12.0,
        isOrderConfirmedByStore: true,
        createdAt: testDate,
      );

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
    });

    test('Transitions status through delivery lifecycle', () {
      final request = DeliveryRequest(
        id: 'del-001',
        orderId: 'ord-100',
        customerId: 'usr-1',
        storeId: 'store-1',
        originAddress: 'Av. Larco 456',
        destinationAddress: 'Calle Berlin 123',
        distanceInKm: 3.0,
        referenceFare: 15.0,
        isOrderConfirmedByStore: true,
        createdAt: testDate,
      );

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
        () => DeliveryRequest(
          id: 'del-003',
          orderId: 'ord-300',
          customerId: 'usr-1',
          storeId: 'store-1',
          originAddress: '',
          destinationAddress: 'Calle 1',
          referenceFare: 10.0,
          isOrderConfirmedByStore: true,
          createdAt: testDate,
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => DeliveryRequest(
          id: 'del-003',
          orderId: 'ord-300',
          customerId: 'usr-1',
          storeId: 'store-1',
          originAddress: 'Av. 1',
          destinationAddress: '',
          referenceFare: 10.0,
          isOrderConfirmedByStore: true,
          createdAt: testDate,
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => DeliveryRequest(
          id: 'del-003',
          orderId: 'ord-300',
          customerId: 'usr-1',
          storeId: 'store-1',
          originAddress: 'Av. 1',
          destinationAddress: 'Calle 2',
          referenceFare: -5.0,
          isOrderConfirmedByStore: true,
          createdAt: testDate,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
