import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/driver.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/driver_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/offer_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/accept_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_delivery_offers_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_pending_delivery_requests_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/reject_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/submit_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/infrastructure/repositories/mock_delivery_repository.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/app_user.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';

void main() {
  group('Etapa 5 – Integración del Flujo de Ofertas y Negociación de Delivery', () {
    late MockDeliveryRepository repository;
    late GetPendingDeliveryRequestsUseCase getPendingRequestsUseCase;
    late GetDeliveryOffersUseCase getOffersUseCase;
    late SubmitDeliveryOfferUseCase submitOfferUseCase;
    late AcceptDeliveryOfferUseCase acceptOfferUseCase;
    late RejectDeliveryOfferUseCase rejectOfferUseCase;

    final fixedTime = DateTime(2026, 11, 2, 16, 0);

    late Driver driver1;
    late Driver driver2;
    late Driver driver3;
    late DeliveryRequest requestAlpha;
    late DeliveryRequest requestBeta;

    setUp(() async {
      repository = MockDeliveryRepository(
        latency: Duration.zero,
        seedTime: fixedTime,
      );

      getPendingRequestsUseCase = GetPendingDeliveryRequestsUseCase(repository);
      getOffersUseCase = GetDeliveryOffersUseCase(repository);
      submitOfferUseCase = SubmitDeliveryOfferUseCase(repository: repository);
      acceptOfferUseCase = AcceptDeliveryOfferUseCase(repository);
      rejectOfferUseCase = RejectDeliveryOfferUseCase(repository);

      driver1 = Driver(
        id: 'drv-101',
        name: 'Roberto Valdivieso',
        phoneNumber: '+59391111111',
        status: DriverStatus.available,
        createdAt: fixedTime,
      );

      driver2 = Driver(
        id: 'drv-102',
        name: 'Carla Zambrano',
        phoneNumber: '+59392222222',
        status: DriverStatus.available,
        createdAt: fixedTime,
      );

      driver3 = Driver(
        id: 'drv-103',
        name: 'Fernando Intriago',
        phoneNumber: '+59393333333',
        status: DriverStatus.available,
        createdAt: fixedTime,
      );

      repository.registerDriver(driver1);
      repository.registerDriver(driver2);
      repository.registerDriver(driver3);

      requestAlpha = DeliveryRequest(
        id: 'req-flow-alpha',
        orderId: 'ord-alpha-99',
        customerId: 'cust-owner-1',
        storeId: 'store-owner-1',
        originAddress: 'Calle Central 500',
        destinationAddress: 'Av. Costanera 1200',
        distanceInKm: 3.5,
        referenceFare: 3.25, // 325 centavos
        isOrderConfirmedByStore: true,
        status: DeliveryStatus.pendingOffer,
        createdAt: fixedTime,
      );

      requestBeta = DeliveryRequest(
        id: 'req-flow-beta',
        orderId: 'ord-beta-88',
        customerId: 'cust-owner-2',
        storeId: 'store-owner-1',
        originAddress: 'Calle Central 500',
        destinationAddress: 'Av. Del Ejército 300',
        distanceInKm: 2.0,
        referenceFare: 2.50, // 250 centavos
        isOrderConfirmedByStore: true,
        status: DeliveryStatus.pendingOffer,
        createdAt: fixedTime,
      );

      await repository.createDeliveryRequest(requestAlpha);
      await repository.createDeliveryRequest(requestBeta);
    });

    IdentityContract makeIdentity({
      required String id,
      required UserRole role,
      bool isActive = true,
    }) {
      return IdentityContract(
        id: id,
        email: '$id@deliveryapp.test',
        displayName: 'User $id',
        phoneNumber: '+59390000000',
        role: role,
        isActive: isActive,
        createdAt: fixedTime,
      );
    }

    // =========================================================================
    // 1. Integración del Ciclo Completo (8 Pasos)
    // =========================================================================
    group('1. Integración del Ciclo Completo de Negociación y Asignación', () {
      test('Ciclo completo: consulta, ofertas, contraoferta por rechazo, aceptación atómica y descarte', () async {
        // Paso 1: Consultar solicitudes disponibles
        final pendingReqsResult = await getPendingRequestsUseCase();
        expect(pendingReqsResult.isSuccess, isTrue);
        final pendingList = pendingReqsResult.dataOrNull!;
        expect(pendingList.any((r) => r.id == requestAlpha.id), isTrue);

        // Paso 2: Consultar ofertas asociadas a la solicitud (inicialmente vacía)
        final initialOffersResult = await getOffersUseCase(requestAlpha.id);
        expect(initialOffersResult.isSuccess, isTrue);
        expect(initialOffersResult.dataOrNull!, isEmpty);

        // Paso 3: Repartidor 1 disponible presenta una oferta base (325 centavos)
        final offer1Result = await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver1.id,
          driverIdentity: makeIdentity(id: driver1.id, role: UserRole.driver),
          offeredFareInCents: 325,
        );
        expect(offer1Result.isSuccess, isTrue);
        final offer1 = offer1Result.dataOrNull!;
        expect(offer1.offeredFareInCents, equals(325));
        expect(offer1.status, equals(OfferStatus.pending));

        // Paso 4: Repartidor 2 disponible presenta una contraoferta (400 centavos)
        final offer2Result = await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver2.id,
          driverIdentity: makeIdentity(id: driver2.id, role: UserRole.driver),
          offeredFareInCents: 400,
          comment: 'Zona con tráfico denso',
        );
        expect(offer2Result.isSuccess, isTrue);
        final offer2 = offer2Result.dataOrNull!;
        expect(offer2.isCounterOffer, isTrue);

        // Paso 5: Cliente consulta las ofertas disponibles para su solicitud
        final clientOffersResult = await getOffersUseCase(requestAlpha.id);
        expect(clientOffersResult.isSuccess, isTrue);
        final clientOffers = clientOffersResult.dataOrNull!;
        expect(clientOffers.length, equals(2));

        // Paso 6: Cliente rechaza la oferta 2 de Carla Zambrano (400 centavos)
        final rejectOffer2 = await rejectOfferUseCase(
          offerId: offer2.id,
          requesterIdentity: makeIdentity(
            id: requestAlpha.customerId,
            role: UserRole.client,
          ),
        );
        expect(rejectOffer2.isSuccess, isTrue);
        expect(rejectOffer2.dataOrNull!.status, equals(OfferStatus.rejected));

        // Paso 7: La solicitud continúa en pendingOffer sin asignación
        final reqAfterReject = (await repository.getDeliveryRequestById(
          requestAlpha.id,
        )).dataOrNull!;
        expect(reqAfterReject.status, equals(DeliveryStatus.pendingOffer));
        expect(reqAfterReject.assignedDriverId, isNull);

        // Paso 8: Repartidor 2 aprovecha su segunda oportunidad y envía contraoferta rectificada (350 centavos)
        final offer2RetryResult = await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver2.id,
          driverIdentity: makeIdentity(id: driver2.id, role: UserRole.driver),
          offeredFareInCents: 350,
          comment: 'Ajuste de tarifa acordada',
        );
        expect(offer2RetryResult.isSuccess, isTrue);
        final offer2Retry = offer2RetryResult.dataOrNull!;

        // Paso 9: Tienda dueña acepta la oferta de Roberto Valdivieso (oferta 1: 325 centavos)
        final acceptResult = await acceptOfferUseCase(
          offerId: offer1.id,
          requesterIdentity: makeIdentity(
            id: requestAlpha.storeId,
            role: UserRole.store,
          ),
        );
        expect(acceptResult.isSuccess, isTrue);
        final assignedRequest = acceptResult.dataOrNull!;

        // Verificaciones finales de consistencia del flujo:
        // A) Solicitud pasa a driverAssigned con tarifa y repartidor acordados
        expect(assignedRequest.status, equals(DeliveryStatus.driverAssigned));
        expect(assignedRequest.assignedDriverId, equals(driver1.id));
        expect(assignedRequest.agreedFareInCents, equals(325));
        expect(assignedRequest.agreedFare, equals(3.25));

        // B) Repartidor 1 pasa a busy
        final driver1Status = (await repository.getDriverAvailability(
          driver1.id,
        )).dataOrNull!;
        expect(driver1Status, equals(DriverStatus.busy));

        // C) Oferta ganadora pasa a accepted
        final winningOffer = (await repository.getDeliveryOfferById(offer1.id))
            .dataOrNull!;
        expect(winningOffer.status, equals(OfferStatus.accepted));

        // D) Oferta competidora en pending (oferta 2 rectificada) pasa automáticamente a discarded
        final discardedOffer = (await repository.getDeliveryOfferById(
          offer2Retry.id,
        )).dataOrNull!;
        expect(discardedOffer.status, equals(OfferStatus.discarded));

        // E) Repartidor competidor (driver2) permanece en available para otras solicitudes
        final driver2Status = (await repository.getDriverAvailability(
          driver2.id,
        )).dataOrNull!;
        expect(driver2Status, equals(DriverStatus.available));
      });
    });

    // =========================================================================
    // 2. Múltiples Ofertas y Descarte en Cascada
    // =========================================================================
    group('2. Múltiples Ofertas y Descarte en Cascada de Competidores', () {
      test('Tres ofertas competidoras: al aceptar una, las otras dos pasan a discarded', () async {
        final off1 = (await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver1.id,
          driverIdentity: makeIdentity(id: driver1.id, role: UserRole.driver),
          offeredFareInCents: 325,
        )).dataOrNull!;

        final off2 = (await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver2.id,
          driverIdentity: makeIdentity(id: driver2.id, role: UserRole.driver),
          offeredFareInCents: 340,
        )).dataOrNull!;

        final off3 = (await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver3.id,
          driverIdentity: makeIdentity(id: driver3.id, role: UserRole.driver),
          offeredFareInCents: 350,
        )).dataOrNull!;

        // Cliente acepta oferta 2 (driver2)
        final accept = await acceptOfferUseCase(
          offerId: off2.id,
          requesterIdentity: makeIdentity(
            id: requestAlpha.customerId,
            role: UserRole.client,
          ),
        );
        expect(accept.isSuccess, isTrue);

        final off1Check = (await repository.getDeliveryOfferById(off1.id))
            .dataOrNull!;
        final off2Check = (await repository.getDeliveryOfferById(off2.id))
            .dataOrNull!;
        final off3Check = (await repository.getDeliveryOfferById(off3.id))
            .dataOrNull!;

        expect(off2Check.status, equals(OfferStatus.accepted));
        expect(off1Check.status, equals(OfferStatus.discarded));
        expect(off3Check.status, equals(OfferStatus.discarded));

        // Driver 2 busy, Driver 1 y Driver 3 available
        expect(
          (await repository.getDriverAvailability(driver2.id)).dataOrNull,
          DriverStatus.busy,
        );
        expect(
          (await repository.getDriverAvailability(driver1.id)).dataOrNull,
          DriverStatus.available,
        );
        expect(
          (await repository.getDriverAvailability(driver3.id)).dataOrNull,
          DriverStatus.available,
        );
      });
    });

    // =========================================================================
    // 3. Cancelación de Solicitud y Limpieza de Ofertas
    // =========================================================================
    group('3. Cancelación de Solicitud y Descarte de Ofertas', () {
      test('Cancelar solicitud descarta todas las ofertas pendientes y bloquea nuevas acciones', () async {
        final off1 = (await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver1.id,
          driverIdentity: makeIdentity(id: driver1.id, role: UserRole.driver),
          offeredFareInCents: 325,
        )).dataOrNull!;

        final off2 = (await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver2.id,
          driverIdentity: makeIdentity(id: driver2.id, role: UserRole.driver),
          offeredFareInCents: 350,
        )).dataOrNull!;

        // Cancelación de la solicitud
        final cancelResult = await repository.updateDeliveryStatus(
          requestAlpha.id,
          DeliveryStatus.cancelled,
        );
        expect(cancelResult.isSuccess, isTrue);

        // Ambas ofertas deben haber sido descartadas
        final off1Check = (await repository.getDeliveryOfferById(off1.id))
            .dataOrNull!;
        final off2Check = (await repository.getDeliveryOfferById(off2.id))
            .dataOrNull!;
        expect(off1Check.status, equals(OfferStatus.discarded));
        expect(off2Check.status, equals(OfferStatus.discarded));

        // Intento de enviar nueva oferta a solicitud cancelada: bloqueado
        final submitCancelled = await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver3.id,
          driverIdentity: makeIdentity(id: driver3.id, role: UserRole.driver),
          offeredFareInCents: 300,
        );
        expect(submitCancelled.isFailure, isTrue);
        expect(submitCancelled.failureOrNull, isA<BusinessRuleFailure>());
        expect(submitCancelled.failureOrNull!.message, contains('cancelada'));

        // Intento de aceptar oferta de solicitud cancelada: bloqueado
        final acceptCancelled = await acceptOfferUseCase(
          offerId: off1.id,
          requesterIdentity: makeIdentity(
            id: requestAlpha.customerId,
            role: UserRole.client,
          ),
        );
        expect(acceptCancelled.isFailure, isTrue);
        expect(acceptCancelled.failureOrNull, isA<BusinessRuleFailure>());

        // Intento de rechazar oferta de solicitud cancelada: bloqueado
        final rejectCancelled = await rejectOfferUseCase(
          offerId: off2.id,
          requesterIdentity: makeIdentity(
            id: requestAlpha.customerId,
            role: UserRole.client,
          ),
        );
        expect(rejectCancelled.isFailure, isTrue);
        expect(rejectCancelled.failureOrNull, isA<BusinessRuleFailure>());
      });
    });

    // =========================================================================
    // 4. Concurrencia y Prevención de Doble Asignación
    // =========================================================================
    group('4. Control de Concurrencia y Prevención de Doble Asignación', () {
      test(
        'Solicitud previamente asignada no admite una segunda aceptación',
        () async {
          final off1 = (await submitOfferUseCase(
            deliveryRequestId: requestAlpha.id,
            driverId: driver1.id,
            driverIdentity: makeIdentity(id: driver1.id, role: UserRole.driver),
            offeredFareInCents: 325,
          )).dataOrNull!;

          final off2 = (await submitOfferUseCase(
            deliveryRequestId: requestAlpha.id,
            driverId: driver2.id,
            driverIdentity: makeIdentity(id: driver2.id, role: UserRole.driver),
            offeredFareInCents: 350,
          )).dataOrNull!;

          // Aceptación 1 exitosa
          final accept1 = await acceptOfferUseCase(
            offerId: off1.id,
            requesterIdentity: makeIdentity(
              id: requestAlpha.customerId,
              role: UserRole.client,
            ),
          );
          expect(accept1.isSuccess, isTrue);

          // Aceptación 2 sobre la misma solicitud ya asignada falla
          final accept2 = await acceptOfferUseCase(
            offerId: off2.id,
            requesterIdentity: makeIdentity(
              id: requestAlpha.customerId,
              role: UserRole.client,
            ),
          );
          expect(accept2.isFailure, isTrue);
          expect(accept2.failureOrNull, isA<BusinessRuleFailure>());

          // El ganador original se preserva
          final finalReq = (await repository.getDeliveryRequestById(
            requestAlpha.id,
          )).dataOrNull!;
          expect(finalReq.assignedDriverId, equals(driver1.id));
          expect(finalReq.agreedFareInCents, equals(325));
        },
      );

      test('Repartidor asignado a solicitud A no puede ser asignado simultáneamente a solicitud B', () async {
        // Driver 1 postula a Solicitud Alpha y Beta
        final offAlpha = (await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver1.id,
          driverIdentity: makeIdentity(id: driver1.id, role: UserRole.driver),
          offeredFareInCents: 325,
        )).dataOrNull!;

        final offBeta = (await submitOfferUseCase(
          deliveryRequestId: requestBeta.id,
          driverId: driver1.id,
          driverIdentity: makeIdentity(id: driver1.id, role: UserRole.driver),
          offeredFareInCents: 250,
        )).dataOrNull!;

        // Solicitud Alpha acepta a Driver 1
        final acceptAlpha = await acceptOfferUseCase(
          offerId: offAlpha.id,
          requesterIdentity: makeIdentity(
            id: requestAlpha.customerId,
            role: UserRole.client,
          ),
        );
        expect(acceptAlpha.isSuccess, isTrue);

        // Solicitud Beta intenta aceptar a Driver 1 (ahora ocupado)
        final acceptBeta = await acceptOfferUseCase(
          offerId: offBeta.id,
          requesterIdentity: makeIdentity(
            id: requestBeta.customerId,
            role: UserRole.client,
          ),
        );
        expect(acceptBeta.isFailure, isTrue);
        expect(acceptBeta.failureOrNull, isA<BusinessRuleFailure>());
        expect(
          acceptBeta.failureOrNull!.message,
          contains('no se encuentra disponible'),
        );

        // Solicitud Beta sigue intacta y sin repartidor
        final betaReq = (await repository.getDeliveryRequestById(
          requestBeta.id,
        )).dataOrNull!;
        expect(betaReq.status, equals(DeliveryStatus.pendingOffer));
        expect(betaReq.assignedDriverId, isNull);
      });
    });

    // =========================================================================
    // 5. Autorización Estricta y Ausencia de Mutaciones Parciales
    // =========================================================================
    group('5. Autorización Estricta y Ausencia de Mutaciones Parciales', () {
      test('Falla de autorización al ofertar, aceptar o rechazar no altera ninguna entidad', () async {
        // 1. Intento de ofertar sin identidad autenticada
        final noAuthOffer = await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver1.id,
          driverIdentity: null,
          offeredFareInCents: 325,
        );
        expect(noAuthOffer.isFailure, isTrue);
        expect(noAuthOffer.failureOrNull, isA<UnauthorizedFailure>());

        // 2. Intento de ofertar con repartidor inactivo
        final inactiveDriverOffer = await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver1.id,
          driverIdentity: makeIdentity(
            id: driver1.id,
            role: UserRole.driver,
            isActive: false,
          ),
          offeredFareInCents: 325,
        );
        expect(inactiveDriverOffer.isFailure, isTrue);
        expect(inactiveDriverOffer.failureOrNull, isA<UnauthorizedFailure>());

        // 3. Intento de ofertar con ID discrepante
        final mismatchOffer = await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver1.id,
          driverIdentity: makeIdentity(id: 'otro-drv', role: UserRole.driver),
          offeredFareInCents: 325,
        );
        expect(mismatchOffer.isFailure, isTrue);
        expect(mismatchOffer.failureOrNull, isA<UnauthorizedFailure>());

        // Verificar que no se creó ninguna oferta espuria
        final offersCheck = (await repository.getOffersByDeliveryRequestId(
          requestAlpha.id,
        )).dataOrNull!;
        expect(offersCheck, isEmpty);

        // Oferta válida
        final validOffer = (await submitOfferUseCase(
          deliveryRequestId: requestAlpha.id,
          driverId: driver1.id,
          driverIdentity: makeIdentity(id: driver1.id, role: UserRole.driver),
          offeredFareInCents: 325,
        )).dataOrNull!;

        // 4. Intento de aceptar con cliente impostor (no dueño)
        final impostorAccept = await acceptOfferUseCase(
          offerId: validOffer.id,
          requesterIdentity: makeIdentity(
            id: 'cliente-impostor',
            role: UserRole.client,
          ),
        );
        expect(impostorAccept.isFailure, isTrue);
        expect(impostorAccept.failureOrNull, isA<UnauthorizedFailure>());

        // 5. Intento de rechazar con identidad nula
        final noAuthReject = await rejectOfferUseCase(
          offerId: validOffer.id,
          requesterIdentity: null,
        );
        expect(noAuthReject.isFailure, isTrue);
        expect(noAuthReject.failureOrNull, isA<UnauthorizedFailure>());

        // Verificar que tras los fallos de autorización ninguna entidad fue mutada
        final freshReq = (await repository.getDeliveryRequestById(
          requestAlpha.id,
        )).dataOrNull!;
        expect(freshReq.status, equals(DeliveryStatus.pendingOffer));
        expect(freshReq.assignedDriverId, isNull);

        final freshOffer = (await repository.getDeliveryOfferById(
          validOffer.id,
        )).dataOrNull!;
        expect(freshOffer.status, equals(OfferStatus.pending));

        final freshDriver = (await repository.getDriverAvailability(driver1.id))
            .dataOrNull!;
        expect(freshDriver, equals(DriverStatus.available));
      });
    });
  });
}
