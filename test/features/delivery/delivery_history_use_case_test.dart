import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_offer.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/offer_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_delivery_history_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/infrastructure/repositories/mock_delivery_repository.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/app_user.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';

void main() {
  group('Semana 7 - GetDeliveryHistoryUseCase (Historial de Delivery)', () {
    late MockDeliveryRepository repository;
    late GetDeliveryHistoryUseCase useCase;
    final fixedDate = DateTime(2026, 11, 2, 12, 0);

    late DeliveryRequest deliveredRequest;
    late DeliveryRequest assignedRequest;
    late DeliveryRequest offeredPendingRequest;

    setUp(() async {
      repository = MockDeliveryRepository(
        latency: Duration.zero,
        seedTime: fixedDate,
      );
      useCase = GetDeliveryHistoryUseCase(repository);

      deliveredRequest = DeliveryRequest(
        id: 'req-h-01',
        orderId: 'ord-h-01',
        customerId: 'cust-100',
        storeId: 'store-200',
        originAddress: 'Av. 4 de Noviembre, Manta',
        destinationAddress: 'Calle 12 y Av. 24, Manta',
        distanceInKm: 3.5,
        referenceFare: 3.25,
        isOrderConfirmedByStore: true,
        status: DeliveryStatus.delivered,
        assignedDriverId: 'drv-assign-1',
        agreedFareInCents: 350,
        createdAt: fixedDate,
      );

      assignedRequest = DeliveryRequest(
        id: 'req-h-02',
        orderId: 'ord-h-02',
        customerId: 'cust-100',
        storeId: 'store-200',
        originAddress: 'Av. 4 de Noviembre, Manta',
        destinationAddress: 'Calle 12 y Av. 24, Manta',
        distanceInKm: 4.0,
        referenceFare: 3.50,
        isOrderConfirmedByStore: true,
        status: DeliveryStatus.driverAssigned,
        assignedDriverId: 'drv-assign-1',
        agreedFareInCents: 325,
        createdAt: fixedDate.add(const Duration(hours: 2)),
      );

      offeredPendingRequest = DeliveryRequest(
        id: 'req-h-03',
        orderId: 'ord-h-03',
        customerId: 'cust-100',
        storeId: 'store-200',
        originAddress: 'Av. 4 de Noviembre, Manta',
        destinationAddress: 'Calle 12 y Av. 24, Manta',
        distanceInKm: 2.5,
        referenceFare: 2.75,
        isOrderConfirmedByStore: true,
        status: DeliveryStatus.pendingOffer,
        createdAt: fixedDate.add(const Duration(hours: 4)),
      );

      await repository.createDeliveryRequest(deliveredRequest);
      await repository.createDeliveryRequest(assignedRequest);
      await repository.createDeliveryRequest(offeredPendingRequest);
    });

    IdentityContract makeIdentity({
      required String id,
      required UserRole role,
      bool isActive = true,
    }) {
      return IdentityContract(
        id: id,
        email: '$id@test.com',
        displayName: 'User $id',
        phoneNumber: '+59399999999',
        role: role,
        isActive: isActive,
        createdAt: fixedDate,
      );
    }

    group('1. Historial por cliente', () {
      test('Devuelve solo las solicitudes del cliente autenticado', () async {
        final result = await useCase.call(
          identity: makeIdentity(id: 'cust-100', role: UserRole.client),
        );

        expect(result.isSuccess, isTrue);
        final history = result.dataOrNull!;
        expect(history.length, 3);
        for (final request in history) {
          expect(request.customerId, 'cust-100');
        }

        final delivered = history.firstWhere(
          (r) => r.id == deliveredRequest.id,
        );
        expect(delivered.status, DeliveryStatus.delivered);
        expect(delivered.agreedFareInCents, deliveredRequest.agreedFareInCents);
        expect(delivered.assignedDriverId, deliveredRequest.assignedDriverId);

        final pending = history.firstWhere(
          (r) => r.id == offeredPendingRequest.id,
        );
        expect(pending.status, DeliveryStatus.pendingOffer);
        expect(pending.assignedDriverId, isNull);
        expect(pending.agreedFareInCents, isNull);
      });

      test('Rechaza historial para un usuario inactivo', () async {
        final result = await useCase.call(
          identity: makeIdentity(
            id: 'cust-100',
            role: UserRole.client,
            isActive: false,
          ),
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });
    });

    group('2. Historial por comercio', () {
      test('Devuelve las solicitudes del comercio autenticado', () async {
        final result = await useCase.call(
          identity: makeIdentity(id: 'store-200', role: UserRole.store),
        );

        expect(result.isSuccess, isTrue);
        final history = result.dataOrNull!;
        expect(history.length, 3);
        for (final request in history) {
          expect(request.storeId, 'store-200');
        }
      });
    });

    group('3. Historial por repartidor', () {
      test(
        'Devuelve la operación asignada al repartidor autenticado',
        () async {
          final result = await useCase.call(
            identity: makeIdentity(id: 'drv-assign-1', role: UserRole.driver),
          );

          expect(result.isSuccess, isTrue);
          final history = result.dataOrNull!;
          expect(history.length, 2);
          expect(history.any((r) => r.id == deliveredRequest.id), isTrue);
          expect(history.any((r) => r.id == assignedRequest.id), isTrue);
          expect(history.any((r) => r.id == offeredPendingRequest.id), isFalse);
          expect(history.first.status, DeliveryStatus.delivered);
        },
      );

      test(
        'Devuelve negociaciones en las que el repartidor presentó ofertas',
        () async {
          repository.registerOffer(
            DeliveryOffer(
              id: 'off-h-01',
              deliveryRequestId: offeredPendingRequest.id,
              driverId: 'drv-offer-1',
              driverName: 'Ana Gómez',
              referenceFareInCents: 275,
              offeredFareInCents: 250,
              status: OfferStatus.pending,
              createdAt: fixedDate,
            ),
          );

          final result = await useCase.call(
            identity: makeIdentity(id: 'drv-offer-1', role: UserRole.driver),
          );

          expect(result.isSuccess, isTrue);
          final history = result.dataOrNull!;
          expect(history.length, 1);
          expect(history.first.id, offeredPendingRequest.id);
        },
      );
    });

    group('4. Historial sin operaciones', () {
      test(
        'Devuelve una lista vacía cuando el usuario no tiene operaciones',
        () async {
          final result = await useCase.call(
            identity: makeIdentity(id: 'drv-none', role: UserRole.driver),
          );

          expect(result.isSuccess, isTrue);
          expect(result.dataOrNull, isEmpty);
        },
      );

      test('Proveedor de eventos no consulta historial de delivery', () async {
        final result = await useCase.call(
          identity: makeIdentity(id: 'evt-1', role: UserRole.eventProvider),
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isEmpty);
      });
    });
  });
}
