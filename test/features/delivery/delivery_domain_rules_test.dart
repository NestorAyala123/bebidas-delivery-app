import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/exceptions.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_mode.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/driver.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/driver_status.dart';

void main() {
  group('Delivery Domain Rules Tests (Etapa 1.3)', () {
    final testDate = DateTime(2026, 9, 23, 14, 0);

    DeliveryRequest createSampleRequest({
      String id = 'del-001',
      String orderId = 'ord-100',
      String customerId = 'usr-001',
      String storeId = 'store-001',
      String originAddress = 'Av. Primavera 123',
      String destinationAddress = 'Calle Los Álamos 456',
      double? distanceInKm = 3.5,
      double referenceFare = 15.0,
      DeliveryMode deliveryMode = DeliveryMode.externalDriver,
      DeliveryStatus status = DeliveryStatus.pendingOffer,
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
        deliveryMode: deliveryMode,
        status: status,
        isOrderConfirmedByStore: isOrderConfirmedByStore,
        createdAt: testDate,
      );
    }

    Driver createSampleDriver({
      String id = 'drv-001',
      String name = 'Juan Pérez',
      DriverStatus status = DriverStatus.available,
    }) {
      return Driver(id: id, name: name, status: status, createdAt: testDate);
    }

    // -------------------------------------------------------------
    // RN02: Disponibilidad del repartidor
    // -------------------------------------------------------------
    group('RN02: Driver availability rules', () {
      test('1. Repartidor disponible puede aceptar solicitudes', () {
        final driver = createSampleDriver(status: DriverStatus.available);
        final request = createSampleRequest();

        expect(driver.canAcceptDeliveries, isTrue);
        expect(driver.status.isAvailable, isTrue);
        expect(driver.canTakeDeliveryRequest(request), isTrue);
      });

      test('2. Repartidor ocupado NO puede aceptar solicitudes', () {
        final driver = createSampleDriver(status: DriverStatus.busy);
        final request = createSampleRequest();

        expect(driver.canAcceptDeliveries, isFalse);
        expect(driver.status.isBusy, isTrue);
        expect(driver.canTakeDeliveryRequest(request), isFalse);
      });

      test('3. Repartidor offline NO puede aceptar solicitudes', () {
        final driver = createSampleDriver(status: DriverStatus.offline);
        final request = createSampleRequest();

        expect(driver.canAcceptDeliveries, isFalse);
        expect(driver.status.isOffline, isTrue);
        expect(driver.canTakeDeliveryRequest(request), isFalse);
      });

      test('Repartidor disponible NO puede tomar solicitudes que no estén en pendingOffer', () {
        final driver = createSampleDriver(status: DriverStatus.available);
        final assignedRequest = createSampleRequest(
          status: DeliveryStatus.driverAssigned,
        );
        final deliveredRequest = createSampleRequest(
          status: DeliveryStatus.delivered,
        );

        expect(driver.canTakeDeliveryRequest(assignedRequest), isFalse);
        expect(driver.canTakeDeliveryRequest(deliveredRequest), isFalse);
      });
    });

    // -------------------------------------------------------------
    // RN03: Solicitud asociada a un único pedido (orderId válido)
    // -------------------------------------------------------------
    group('RN03: Order association rules', () {
      test('4. Solicitud requiere orderId válido y no vacío', () {
        expect(
          () => createSampleRequest(orderId: ''),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => createSampleRequest(orderId: '   '),
          throwsA(isA<AssertionError>()),
        );

        final request = createSampleRequest(orderId: 'ord-valid-999');
        expect(request.orderId, equals('ord-valid-999'));
      });
    });

    // -------------------------------------------------------------
    // RN04: Datos mínimos de la ruta y tarifa
    // -------------------------------------------------------------
    group('RN04: Route and fare data validity rules', () {
      test('5. Origen y destino no pueden estar vacíos', () {
        expect(
          () => createSampleRequest(originAddress: ''),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => createSampleRequest(originAddress: '   '),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => createSampleRequest(destinationAddress: ''),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => createSampleRequest(destinationAddress: '   '),
          throwsA(isA<AssertionError>()),
        );
      });

      test('6. Distancia no puede ser negativa', () {
        expect(
          () => createSampleRequest(distanceInKm: -0.1),
          throwsA(isA<AssertionError>()),
        );

        // Distancia nula (aún no calculada) o cero/positiva es válida
        expect(() => createSampleRequest(distanceInKm: null), returnsNormally);
        expect(() => createSampleRequest(distanceInKm: 0.0), returnsNormally);
        expect(() => createSampleRequest(distanceInKm: 12.4), returnsNormally);
      });

      test('7. Tarifa referencial no puede ser negativa', () {
        expect(
          () => createSampleRequest(referenceFare: -1.0),
          throwsA(isA<AssertionError>()),
        );

        expect(() => createSampleRequest(referenceFare: 0.0), returnsNormally);
        expect(() => createSampleRequest(referenceFare: 18.5), returnsNormally);
      });
    });

    // -------------------------------------------------------------
    // RN05: Estados y consistencia de DeliveryStatus
    // -------------------------------------------------------------
    group('RN05: DeliveryStatus states and transition rules', () {
      test('8. Estados terminales (delivered, cancelled) no deben considerarse activos', () {
        expect(DeliveryStatus.delivered.isTerminal, isTrue);
        expect(DeliveryStatus.delivered.isActive, isFalse);

        expect(DeliveryStatus.cancelled.isTerminal, isTrue);
        expect(DeliveryStatus.cancelled.isActive, isFalse);

        // Estados en progreso son activos y no terminales
        for (final status in [
          DeliveryStatus.pendingOffer,
          DeliveryStatus.driverAssigned,
          DeliveryStatus.arrivedAtStore,
          DeliveryStatus.pickedUp,
          DeliveryStatus.onTheWay,
        ]) {
          expect(status.isActive, isTrue);
          expect(status.isTerminal, isFalse);
        }
      });

      test('9. Propiedad isAssigned es consistente a lo largo del ciclo', () {
        // Asignados:
        expect(DeliveryStatus.driverAssigned.isAssigned, isTrue);
        expect(DeliveryStatus.arrivedAtStore.isAssigned, isTrue);
        expect(DeliveryStatus.pickedUp.isAssigned, isTrue);
        expect(DeliveryStatus.onTheWay.isAssigned, isTrue);

        // No asignados:
        expect(DeliveryStatus.pendingOffer.isAssigned, isFalse);
        expect(DeliveryStatus.delivered.isAssigned, isFalse);
        expect(DeliveryStatus.cancelled.isAssigned, isFalse);
      });

      test('Transiciones válidas paso a paso', () {
        var request = createSampleRequest();
        expect(request.status, equals(DeliveryStatus.pendingOffer));

        request = request.transitionTo(DeliveryStatus.driverAssigned);
        expect(request.status, equals(DeliveryStatus.driverAssigned));

        request = request.transitionTo(DeliveryStatus.arrivedAtStore);
        expect(request.status, equals(DeliveryStatus.arrivedAtStore));

        request = request.transitionTo(DeliveryStatus.pickedUp);
        expect(request.status, equals(DeliveryStatus.pickedUp));

        request = request.transitionTo(DeliveryStatus.onTheWay);
        expect(request.status, equals(DeliveryStatus.onTheWay));

        request = request.transitionTo(DeliveryStatus.delivered);
        expect(request.status, equals(DeliveryStatus.delivered));
        expect(request.status.isTerminal, isTrue);
      });

      test('Cancelación válida desde estados intermedios antes de entrega', () {
        final pending = createSampleRequest();
        expect(
          pending.transitionTo(DeliveryStatus.cancelled).status,
          equals(DeliveryStatus.cancelled),
        );

        final assigned = pending.transitionTo(DeliveryStatus.driverAssigned);
        expect(
          assigned.transitionTo(DeliveryStatus.cancelled).status,
          equals(DeliveryStatus.cancelled),
        );

        final atStore = assigned.transitionTo(DeliveryStatus.arrivedAtStore);
        expect(
          atStore.transitionTo(DeliveryStatus.cancelled).status,
          equals(DeliveryStatus.cancelled),
        );
      });

      test('Transiciones inválidas lanzan DomainException', () {
        final pending = createSampleRequest();

        // Salto ilegal: de pendingOffer directo a delivered
        expect(
          () => pending.transitionTo(DeliveryStatus.delivered),
          throwsA(isA<DomainException>()),
        );

        // Salto ilegal: de pendingOffer a pickedUp
        expect(
          () => pending.transitionTo(DeliveryStatus.pickedUp),
          throwsA(isA<DomainException>()),
        );

        // Transición desde estado terminal delivered
        final delivered = pending
            .transitionTo(DeliveryStatus.driverAssigned)
            .transitionTo(DeliveryStatus.arrivedAtStore)
            .transitionTo(DeliveryStatus.pickedUp)
            .transitionTo(DeliveryStatus.onTheWay)
            .transitionTo(DeliveryStatus.delivered);

        expect(
          () => delivered.transitionTo(DeliveryStatus.cancelled),
          throwsA(isA<DomainException>()),
        );

        expect(
          () => delivered.transitionTo(DeliveryStatus.pendingOffer),
          throwsA(isA<DomainException>()),
        );

        // Transición desde estado terminal cancelled
        final cancelled = pending.transitionTo(DeliveryStatus.cancelled);
        expect(
          () => cancelled.transitionTo(DeliveryStatus.driverAssigned),
          throwsA(isA<DomainException>()),
        );
      });
    });

    // -------------------------------------------------------------
    // RN01: Inicio válido (Orden confirmada)
    // -------------------------------------------------------------
    group('RN01: Order confirmation requirement', () {
      test('Solicitud externa requiere orden confirmada', () {
        expect(
          () => createSampleRequest(isOrderConfirmedByStore: false),
          throwsA(isA<DomainException>()),
        );

        expect(
          () => createSampleRequest(isOrderConfirmedByStore: true),
          returnsNormally,
        );
      });
    });
  });
}
