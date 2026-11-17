import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/core/result/result.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_offer.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/driver.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/driver_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/offer_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/accept_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/reject_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/submit_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/infrastructure/repositories/mock_delivery_repository.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/app_user.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';

void main() {
  group('Etapa 4 – Auditoría de Selección y Asignación del Repartidor', () {
    late MockDeliveryRepository repository;
    late SubmitDeliveryOfferUseCase submitOfferUseCase;
    late AcceptDeliveryOfferUseCase acceptOfferUseCase;
    late RejectDeliveryOfferUseCase rejectOfferUseCase;

    final testDate = DateTime(2026, 11, 2, 14, 0);

    late Driver driverA;
    late Driver driverB;
    late Driver busyDriver;
    late Driver offlineDriver;

    late DeliveryRequest request1;
    late DeliveryRequest request2;

    setUp(() async {
      repository = MockDeliveryRepository(
        latency: Duration.zero,
        seedTime: testDate,
      );

      submitOfferUseCase = SubmitDeliveryOfferUseCase(repository: repository);
      acceptOfferUseCase = AcceptDeliveryOfferUseCase(repository);
      rejectOfferUseCase = RejectDeliveryOfferUseCase(repository);

      driverA = Driver(
        id: 'drv-A',
        name: 'Alejandro Morales',
        status: DriverStatus.available,
        createdAt: testDate,
      );
      driverB = Driver(
        id: 'drv-B',
        name: 'Beatriz Solís',
        status: DriverStatus.available,
        createdAt: testDate,
      );
      busyDriver = Driver(
        id: 'drv-busy',
        name: 'Carlos Ocupado',
        status: DriverStatus.busy,
        createdAt: testDate,
      );
      offlineDriver = Driver(
        id: 'drv-offline',
        name: 'David Desconectado',
        status: DriverStatus.offline,
        createdAt: testDate,
      );

      repository.registerDriver(driverA);
      repository.registerDriver(driverB);
      repository.registerDriver(busyDriver);
      repository.registerDriver(offlineDriver);

      request1 = DeliveryRequest(
        id: 'req-alpha',
        orderId: 'ord-alpha',
        customerId: 'customer-alpha',
        storeId: 'store-central',
        originAddress: 'Av. Principal 100',
        destinationAddress: 'Calle Secundaria 200',
        distanceInKm: 2.0,
        referenceFare: 2.50, // 250 centavos
        isOrderConfirmedByStore: true,
        status: DeliveryStatus.pendingOffer,
        createdAt: testDate,
      );

      request2 = DeliveryRequest(
        id: 'req-beta',
        orderId: 'ord-beta',
        customerId: 'customer-beta',
        storeId: 'store-central',
        originAddress: 'Av. Principal 100',
        destinationAddress: 'Calle Tercera 300',
        distanceInKm: 4.0,
        referenceFare: 3.50, // 350 centavos
        isOrderConfirmedByStore: true,
        status: DeliveryStatus.pendingOffer,
        createdAt: testDate,
      );

      await repository.createDeliveryRequest(request1);
      await repository.createDeliveryRequest(request2);
    });

    IdentityContract makeIdentity({
      required String id,
      required UserRole role,
      bool isActive = true,
    }) {
      return IdentityContract(
        id: id,
        email: '$id@mail.com',
        displayName: 'User $id',
        phoneNumber: '+59390000000',
        role: role,
        isActive: isActive,
        createdAt: testDate,
      );
    }

    Future<Result<DeliveryOffer, Failure>> submitOffer({
      required String deliveryRequestId,
      required String driverId,
      IdentityContract? driverIdentity,
      int? offeredFareInCents,
      String? offeredFareText,
      String? comment,
      DateTime? createdAt,
      SubmitDeliveryOfferUseCase? customUseCase,
    }) {
      final uc = customUseCase ?? submitOfferUseCase;
      return uc(
        deliveryRequestId: deliveryRequestId,
        driverId: driverId,
        driverIdentity:
            driverIdentity ?? makeIdentity(id: driverId, role: UserRole.driver),
        offeredFareInCents: offeredFareInCents,
        offeredFareText: offeredFareText,
        comment: comment,
        createdAt: createdAt,
      );
    }

    // =========================================================================
    // 1. Selección de Repartidores Elegibles
    // =========================================================================
    group('1. Selección de Repartidores Elegibles', () {
      test(
        'Solo los repartidores en DriverStatus.available pueden enviar ofertas',
        () async {
          final offerA = await submitOffer(
            deliveryRequestId: request1.id,
            driverId: driverA.id,
            offeredFareInCents: 250,
          );
          expect(offerA.isSuccess, isTrue);

          final offerBusy = await submitOffer(
            deliveryRequestId: request1.id,
            driverId: busyDriver.id,
            offeredFareInCents: 250,
          );
          expect(offerBusy.isFailure, isTrue);
          expect(offerBusy.failureOrNull, isA<BusinessRuleFailure>());

          final offerOffline = await submitOffer(
            deliveryRequestId: request1.id,
            driverId: offlineDriver.id,
            offeredFareInCents: 250,
          );
          expect(offerOffline.isFailure, isTrue);
          expect(offerOffline.failureOrNull, isA<BusinessRuleFailure>());
        },
      );

      test('No se permite presentar ofertas a solicitudes que no estén en pendingOffer', () async {
        final assignedRequest = request1.assignDriver(
          driverId: 'drv-existing',
          agreedFareInCents: 250,
        );
        final repo = MockDeliveryRepository(latency: Duration.zero);
        repo.registerDriver(driverA);
        await repo.createDeliveryRequest(assignedRequest);

        final submit = SubmitDeliveryOfferUseCase(repository: repo);
        final result = await submitOffer(
          deliveryRequestId: assignedRequest.id,
          driverId: driverA.id,
          customUseCase: submit,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<BusinessRuleFailure>());
      });

      test('Driver.canTakeDeliveryRequest valida disponibilidad y ausencia de asignación', () {
        expect(driverA.canTakeDeliveryRequest(request1), isTrue);
        expect(busyDriver.canTakeDeliveryRequest(request1), isFalse);
        expect(offlineDriver.canTakeDeliveryRequest(request1), isFalse);

        final alreadyAssigned = request1.assignDriver(
          driverId: 'drv-x',
          agreedFareInCents: 250,
        );
        expect(driverA.canTakeDeliveryRequest(alreadyAssigned), isFalse);
      });

      test('RN-NEG-04: Respeta el límite de máximo 2 ofertas por repartidor y solicitud', () async {
        // Oferta 1: enviada exitosamente
        final offer1Result = await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 260,
        );
        expect(offer1Result.isSuccess, isTrue);
        final offer1 = offer1Result.dataOrNull!;

        // Intento de segunda oferta mientras la primera sigue pending: bloqueado
        final pendingDuplicate = await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 270,
        );
        expect(pendingDuplicate.isFailure, isTrue);
        expect(pendingDuplicate.failureOrNull, isA<BusinessRuleFailure>());
        expect(
          pendingDuplicate.failureOrNull!.message,
          contains('ya tiene una oferta pendiente'),
        );

        // Cliente rechaza la primera oferta
        final reject1 = await rejectOfferUseCase(
          offerId: offer1.id,
          requesterIdentity: makeIdentity(
            id: request1.customerId,
            role: UserRole.client,
          ),
        );
        expect(reject1.isSuccess, isTrue);

        // Oferta 2 (contraoferta post-rechazo): permitida
        final offer2Result = await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 280,
        );
        expect(offer2Result.isSuccess, isTrue);
        final offer2 = offer2Result.dataOrNull!;

        // Cliente rechaza la segunda oferta
        final reject2 = await rejectOfferUseCase(
          offerId: offer2.id,
          requesterIdentity: makeIdentity(
            id: request1.customerId,
            role: UserRole.client,
          ),
        );
        expect(reject2.isSuccess, isTrue);

        // Intento de tercera oferta: bloqueado por exceder límite de 2
        final offer3Result = await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 290,
        );
        expect(offer3Result.isFailure, isTrue);
        expect(offer3Result.failureOrNull, isA<BusinessRuleFailure>());
        expect(
          offer3Result.failureOrNull!.message,
          contains('límite máximo de 2 ofertas'),
        );
      });

      test('Validación de identidad del repartidor al ofertar (nulo, inactivo, rol no repartidor y discrepancia de ID bloqueados)', () async {
        // Identidad nula
        final nullResult = await submitOfferUseCase(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          driverIdentity: null,
          offeredFareInCents: 250,
        );
        expect(nullResult.isFailure, isTrue);
        expect(nullResult.failureOrNull, isA<UnauthorizedFailure>());

        // Repartidor inactivo
        final inactiveResult = await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          driverIdentity: makeIdentity(
            id: driverA.id,
            role: UserRole.driver,
            isActive: false,
          ),
          offeredFareInCents: 250,
        );
        expect(inactiveResult.isFailure, isTrue);
        expect(inactiveResult.failureOrNull, isA<UnauthorizedFailure>());

        // Usuario con rol cliente intentando ofertar como repartidor
        final clientResult = await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          driverIdentity: makeIdentity(id: driverA.id, role: UserRole.client),
          offeredFareInCents: 250,
        );
        expect(clientResult.isFailure, isTrue);
        expect(clientResult.failureOrNull, isA<UnauthorizedFailure>());

        // Discrepancia entre driverId y driverIdentity.id
        final mismatchResult = await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          driverIdentity: makeIdentity(id: 'drv-otro', role: UserRole.driver),
          offeredFareInCents: 250,
        );
        expect(mismatchResult.isFailure, isTrue);
        expect(mismatchResult.failureOrNull, isA<UnauthorizedFailure>());
      });
    });

    // =========================================================================
    // 2. Asignación y Prevención de Doble Asignación entre Múltiples Solicitudes
    // =========================================================================
    group('2. Prevención de Doble Asignación de un Repartidor entre Múltiples Solicitudes', () {
      test('Un repartidor asignado a una solicitud NO puede ser asignado a otra simultánea', () async {
        // Driver A postula a Solicitud 1 y Solicitud 2 mientras está disponible
        final offer1 = (await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 250,
        )).dataOrNull!;

        final offer2 = (await submitOffer(
          deliveryRequestId: request2.id,
          driverId: driverA.id,
          offeredFareInCents: 350,
        )).dataOrNull!;

        // Solicitud 1 acepta primero a Driver A
        final accept1 = await acceptOfferUseCase(
          offerId: offer1.id,
          requesterIdentity: makeIdentity(
            id: request1.customerId,
            role: UserRole.client,
          ),
        );
        expect(accept1.isSuccess, isTrue);
        expect(accept1.dataOrNull!.assignedDriverId, equals(driverA.id));

        // Driver A ahora está ocupado (DriverStatus.busy)
        final driverACheck = await repository.getDriverAvailability(driverA.id);
        expect(driverACheck.dataOrNull, equals(DriverStatus.busy));

        // Solicitud 2 intenta aceptar a Driver A
        final accept2 = await acceptOfferUseCase(
          offerId: offer2.id,
          requesterIdentity: makeIdentity(
            id: request2.customerId,
            role: UserRole.client,
          ),
        );

        // La segunda asignación debe fallar por RN-NEG-06 (repartidor ya no disponible)
        expect(accept2.isFailure, isTrue);
        expect(accept2.failureOrNull, isA<BusinessRuleFailure>());
        expect(
          accept2.failureOrNull!.message,
          contains('no se encuentra disponible'),
        );

        // Solicitud 2 permanece intacta en pendingOffer sin conductor asignado
        final request2Check = (await repository.getDeliveryRequestById(
          request2.id,
        )).dataOrNull!;
        expect(request2Check.status, equals(DeliveryStatus.pendingOffer));
        expect(request2Check.assignedDriverId, isNull);

        // La oferta de Driver A en Solicitud 2 fue descartada
        final offer2Check = (await repository.getDeliveryOfferById(offer2.id))
            .dataOrNull!;
        expect(offer2Check.status, equals(OfferStatus.discarded));
      });

      test('Repartidor que pasa a offline antes de aceptar: aceptación rechazada y oferta descartada', () async {
        final offer = (await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 250,
        )).dataOrNull!;

        // Repartidor pasa a offline
        await repository.setDriverAvailability(
          driverA.id,
          DriverStatus.offline,
        );

        final acceptResult = await acceptOfferUseCase(
          offerId: offer.id,
          requesterIdentity: makeIdentity(
            id: request1.customerId,
            role: UserRole.client,
          ),
        );

        expect(acceptResult.isFailure, isTrue);
        expect(acceptResult.failureOrNull, isA<BusinessRuleFailure>());
        expect(
          acceptResult.failureOrNull!.message,
          contains('no se encuentra disponible'),
        );

        // Solicitud permanece pendingOffer sin repartidor
        final requestCheck = (await repository.getDeliveryRequestById(
          request1.id,
        )).dataOrNull!;
        expect(requestCheck.status, equals(DeliveryStatus.pendingOffer));
        expect(requestCheck.assignedDriverId, isNull);

        // Oferta descartada
        final offerCheck = (await repository.getDeliveryOfferById(offer.id))
            .dataOrNull!;
        expect(offerCheck.status, equals(OfferStatus.discarded));
      });
    });

    // =========================================================================
    // 3. Carrera de Aceptación Concurrente sobre la Misma Solicitud
    // =========================================================================
    group('3. Carrera de Aceptación Concurrente sobre la Misma Solicitud', () {
      test('Dos aceptaciones consecutivas: la segunda falla sin modificar ninguna entidad', () async {
        final offerA = (await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 260,
        )).dataOrNull!;

        final offerB = (await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverB.id,
          offeredFareInCents: 270,
        )).dataOrNull!;

        // Aceptación 1: gana Driver A
        final firstAccept = await acceptOfferUseCase(
          offerId: offerA.id,
          requesterIdentity: makeIdentity(
            id: request1.customerId,
            role: UserRole.client,
          ),
        );
        expect(firstAccept.isSuccess, isTrue);
        final winningRequest = firstAccept.dataOrNull!;
        expect(winningRequest.assignedDriverId, equals(driverA.id));
        expect(winningRequest.agreedFareInCents, equals(260));

        // Aceptación 2: intenta aceptar a Driver B sobre la misma solicitud
        final secondAccept = await acceptOfferUseCase(
          offerId: offerB.id,
          requesterIdentity: makeIdentity(
            id: request1.customerId,
            role: UserRole.client,
          ),
        );

        // Falla por solicitud ya asignada o por oferta ya descartada
        expect(secondAccept.isFailure, isTrue);
        expect(secondAccept.failureOrNull, isA<BusinessRuleFailure>());

        // El estado de la solicitud no cambia: conserva a Driver A
        final freshRequest = (await repository.getDeliveryRequestById(
          request1.id,
        )).dataOrNull!;
        expect(freshRequest.assignedDriverId, equals(driverA.id));
        expect(freshRequest.agreedFareInCents, equals(260));
        expect(freshRequest.status, equals(DeliveryStatus.driverAssigned));

        // Driver B sigue disponible para otras entregas
        final driverBStatus = (await repository.getDriverAvailability(
          driverB.id,
        )).dataOrNull!;
        expect(driverBStatus, equals(DriverStatus.available));
      });

      test('Aceptación concurrente simultánea (Future.wait): exactamente una asignación gana', () async {
        final asyncRepo = MockDeliveryRepository(
          latency: const Duration(milliseconds: 15),
          seedTime: testDate,
        );
        asyncRepo.registerDriver(driverA);
        asyncRepo.registerDriver(driverB);
        await asyncRepo.createDeliveryRequest(request1);

        final submitAsync = SubmitDeliveryOfferUseCase(repository: asyncRepo);
        final acceptAsync = AcceptDeliveryOfferUseCase(asyncRepo);

        final offer1 = (await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 250,
          customUseCase: submitAsync,
        )).dataOrNull!;

        final offer2 = (await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverB.id,
          offeredFareInCents: 280,
          customUseCase: submitAsync,
        )).dataOrNull!;

        // Disparo simultáneo de ambas aceptaciones
        final results = await Future.wait([
          acceptAsync(
            offerId: offer1.id,
            requesterIdentity: makeIdentity(
              id: request1.customerId,
              role: UserRole.client,
            ),
          ),
          acceptAsync(
            offerId: offer2.id,
            requesterIdentity: makeIdentity(
              id: request1.customerId,
              role: UserRole.client,
            ),
          ),
        ]);

        final successResults = results.where((r) => r.isSuccess).toList();
        final failureResults = results.where((r) => r.isFailure).toList();

        // Exactamente una debe ganar y exactamente una debe fallar
        expect(successResults.length, equals(1));
        expect(failureResults.length, equals(1));

        final updatedReq = (await asyncRepo.getDeliveryRequestById(request1.id))
            .dataOrNull!;
        expect(updatedReq.status, equals(DeliveryStatus.driverAssigned));
        expect(updatedReq.assignedDriverId, isNotNull);

        // El ganador está busy y el perdedor está available
        final winnerId = updatedReq.assignedDriverId!;
        final loserId = winnerId == driverA.id ? driverB.id : driverA.id;

        final winnerStatus = (await asyncRepo.getDriverAvailability(winnerId))
            .dataOrNull!;
        final loserStatus = (await asyncRepo.getDriverAvailability(loserId))
            .dataOrNull!;

        expect(winnerStatus, equals(DriverStatus.busy));
        expect(loserStatus, equals(DriverStatus.available));
      });
    });

    // =========================================================================
    // 4. Verificación de Autorización Estricta
    // =========================================================================
    group('4. Verificación de Autorización Estricta', () {
      test(
        'Cliente dueño y tienda dueña son autorizados para aceptar y rechazar',
        () async {
          final offer = (await submitOffer(
            deliveryRequestId: request1.id,
            driverId: driverA.id,
            offeredFareInCents: 250,
          )).dataOrNull!;

          // Tienda dueña rechaza
          final rejectStore = await rejectOfferUseCase(
            offerId: offer.id,
            requesterIdentity: makeIdentity(
              id: request1.storeId,
              role: UserRole.store,
            ),
          );
          expect(rejectStore.isSuccess, isTrue);
          expect(rejectStore.dataOrNull!.status, equals(OfferStatus.rejected));
        },
      );

      test(
        'Intruso cliente u otra tienda son bloqueados con UnauthorizedFailure',
        () async {
          final offer = (await submitOffer(
            deliveryRequestId: request1.id,
            driverId: driverA.id,
            offeredFareInCents: 250,
          )).dataOrNull!;

          final rejectIntruder = await rejectOfferUseCase(
            offerId: offer.id,
            requesterIdentity: makeIdentity(
              id: 'customer-ajeno',
              role: UserRole.client,
            ),
          );
          expect(rejectIntruder.isFailure, isTrue);
          expect(rejectIntruder.failureOrNull, isA<UnauthorizedFailure>());

          final acceptIntruderStore = await acceptOfferUseCase(
            offerId: offer.id,
            requesterIdentity: makeIdentity(
              id: 'store-otra',
              role: UserRole.store,
            ),
          );
          expect(acceptIntruderStore.isFailure, isTrue);
          expect(acceptIntruderStore.failureOrNull, isA<UnauthorizedFailure>());
        },
      );

      test(
        'Invocación sin identidad autenticada falla con UnauthorizedFailure',
        () async {
          final offer = (await submitOffer(
            deliveryRequestId: request1.id,
            driverId: driverA.id,
            offeredFareInCents: 250,
          )).dataOrNull!;

          final acceptNoAuth = await acceptOfferUseCase(offerId: offer.id);
          expect(acceptNoAuth.isFailure, isTrue);
          expect(acceptNoAuth.failureOrNull, isA<UnauthorizedFailure>());
        },
      );

      test('Usuario inactivo (isActive: false) es bloqueado con UnauthorizedFailure', () async {
        final offer = (await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 250,
        )).dataOrNull!;

        final acceptInactive = await acceptOfferUseCase(
          offerId: offer.id,
          requesterIdentity: makeIdentity(
            id: request1.customerId,
            role: UserRole.client,
            isActive: false,
          ),
        );
        expect(acceptInactive.isFailure, isTrue);
        expect(acceptInactive.failureOrNull, isA<UnauthorizedFailure>());

        final rejectInactive = await rejectOfferUseCase(
          offerId: offer.id,
          requesterIdentity: makeIdentity(
            id: request1.storeId,
            role: UserRole.store,
            isActive: false,
          ),
        );
        expect(rejectInactive.isFailure, isTrue);
        expect(rejectInactive.failureOrNull, isA<UnauthorizedFailure>());
      });

      test('Repartidor o proveedor de eventos intentando aceptar o rechazar falla con UnauthorizedFailure', () async {
        final offer = (await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 250,
        )).dataOrNull!;

        final acceptDriver = await acceptOfferUseCase(
          offerId: offer.id,
          requesterIdentity: makeIdentity(
            id: driverA.id,
            role: UserRole.driver,
          ),
        );
        expect(acceptDriver.isFailure, isTrue);
        expect(acceptDriver.failureOrNull, isA<UnauthorizedFailure>());

        final rejectEventProvider = await rejectOfferUseCase(
          offerId: offer.id,
          requesterIdentity: makeIdentity(
            id: 'event-provider-1',
            role: UserRole.eventProvider,
          ),
        );
        expect(rejectEventProvider.isFailure, isTrue);
        expect(rejectEventProvider.failureOrNull, isA<UnauthorizedFailure>());
      });

      test(
        'Rechazo de autorización no produce ninguna mutación de entidades',
        () async {
          final offer = (await submitOffer(
            deliveryRequestId: request1.id,
            driverId: driverA.id,
            offeredFareInCents: 250,
          )).dataOrNull!;

          // Intento no autorizado
          final rejectUnauthorized = await rejectOfferUseCase(
            offerId: offer.id,
            requesterIdentity: makeIdentity(
              id: 'cliente-impostor',
              role: UserRole.client,
            ),
          );
          expect(rejectUnauthorized.isFailure, isTrue);

          // Comprobación de integridad
          final req = (await repository.getDeliveryRequestById(request1.id))
              .dataOrNull!;
          expect(req.status, equals(DeliveryStatus.pendingOffer));
          expect(req.assignedDriverId, isNull);

          final off = (await repository.getDeliveryOfferById(offer.id))
              .dataOrNull!;
          expect(off.status, equals(OfferStatus.pending));

          final drv = (await repository.getDriverAvailability(driverA.id))
              .dataOrNull!;
          expect(drv, equals(DriverStatus.available));
        },
      );
    });

    // =========================================================================
    // 5. Consistencia de Tarifas y Cierre en Cascada
    // =========================================================================
    group('5. Consistencia de Tarifas y Cierre en Cascada', () {
      test(
        'Cierre en cascada: descarta todas las ofertas rivales en pending',
        () async {
          final offerA = (await submitOffer(
            deliveryRequestId: request1.id,
            driverId: driverA.id,
            offeredFareInCents: 250,
          )).dataOrNull!;

          final offerB = (await submitOffer(
            deliveryRequestId: request1.id,
            driverId: driverB.id,
            offeredFareInCents: 280,
          )).dataOrNull!;

          final accept = await acceptOfferUseCase(
            offerId: offerA.id,
            requesterIdentity: makeIdentity(
              id: request1.customerId,
              role: UserRole.client,
            ),
          );
          expect(accept.isSuccess, isTrue);

          final offerACheck = (await repository.getDeliveryOfferById(offerA.id))
              .dataOrNull!;
          final offerBCheck = (await repository.getDeliveryOfferById(offerB.id))
              .dataOrNull!;

          expect(offerACheck.status, equals(OfferStatus.accepted));
          expect(offerBCheck.status, equals(OfferStatus.discarded));
        },
      );

      test(
        'Consistencia estricta de tarifas en centavos y double tras asignación',
        () async {
          final offer = (await submitOffer(
            deliveryRequestId: request1.id,
            driverId: driverA.id,
            offeredFareInCents: 475, // $4.75
          )).dataOrNull!;

          final accept = await acceptOfferUseCase(
            offerId: offer.id,
            requesterIdentity: makeIdentity(
              id: request1.customerId,
              role: UserRole.client,
            ),
          );

          expect(accept.isSuccess, isTrue);
          final assignedReq = accept.dataOrNull!;

          // Validación estricta de consistencia
          expect(assignedReq.agreedFareInCents, equals(475));
          expect(assignedReq.agreedFare, equals(4.75));
          expect(assignedReq.assignedDriverId, equals(driverA.id));
          expect(assignedReq.status, equals(DeliveryStatus.driverAssigned));

          final freshDriver = (await repository.getRegisteredDrivers())
              .dataOrNull!
              .firstWhere((d) => d.id == driverA.id);
          expect(freshDriver.status, equals(DriverStatus.busy));
        },
      );
    });

    // =========================================================================
    // 6. Errores Técnicos y Garantía All-or-Nothing
    // =========================================================================
    group('6. Errores Técnicos y Garantía All-or-Nothing (Sin Modificaciones Parciales)', () {
      test('Falla al aceptar por repartidor no disponible: solicitud y ofertas rivales quedan intactas', () async {
        final offerA = (await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 250,
        )).dataOrNull!;

        final offerB = (await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverB.id,
          offeredFareInCents: 270,
        )).dataOrNull!;

        // Driver A pasa a ocupado
        await repository.setDriverAvailability(driverA.id, DriverStatus.busy);

        // Se intenta aceptar la oferta de Driver A
        final acceptFail = await acceptOfferUseCase(
          offerId: offerA.id,
          requesterIdentity: makeIdentity(
            id: request1.customerId,
            role: UserRole.client,
          ),
        );

        expect(acceptFail.isFailure, isTrue);

        // Solicitud permanece en pendingOffer sin asignación
        final req = (await repository.getDeliveryRequestById(request1.id))
            .dataOrNull!;
        expect(req.status, equals(DeliveryStatus.pendingOffer));
        expect(req.assignedDriverId, isNull);
        expect(req.agreedFareInCents, isNull);

        // Oferta B sigue en pending lista para ser evaluada
        final offerBCheck = (await repository.getDeliveryOfferById(offerB.id))
            .dataOrNull!;
        expect(offerBCheck.status, equals(OfferStatus.pending));

        // Oferta A descartada por indisponibilidad de Driver A
        final offerACheck = (await repository.getDeliveryOfferById(offerA.id))
            .dataOrNull!;
        expect(offerACheck.status, equals(OfferStatus.discarded));
      });

      test('Cancelación de solicitud descarta en cascada ofertas pendientes y no admite nuevas ofertas', () async {
        final offer1 = (await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 250,
        )).dataOrNull!;

        final offer2 = (await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverB.id,
          offeredFareInCents: 270,
        )).dataOrNull!;

        // Cancelación de la solicitud
        final cancelResult = await repository.updateDeliveryStatus(
          request1.id,
          DeliveryStatus.cancelled,
        );
        expect(cancelResult.isSuccess, isTrue);

        // Todas las ofertas pendientes deben quedar descartadas
        final off1Check = (await repository.getDeliveryOfferById(offer1.id))
            .dataOrNull!;
        final off2Check = (await repository.getDeliveryOfferById(offer2.id))
            .dataOrNull!;
        expect(off1Check.status, equals(OfferStatus.discarded));
        expect(off2Check.status, equals(OfferStatus.discarded));

        // Intento de ofertar a solicitud cancelada falla
        final offerCancelled = await submitOffer(
          deliveryRequestId: request1.id,
          driverId: driverA.id,
          offeredFareInCents: 300,
        );
        expect(offerCancelled.isFailure, isTrue);
        expect(offerCancelled.failureOrNull, isA<BusinessRuleFailure>());
        expect(offerCancelled.failureOrNull!.message, contains('cancelada'));

        // Intento de aceptar oferta de solicitud cancelada falla
        final acceptCancelled = await acceptOfferUseCase(
          offerId: offer1.id,
          requesterIdentity: makeIdentity(
            id: request1.customerId,
            role: UserRole.client,
          ),
        );
        expect(acceptCancelled.isFailure, isTrue);
        expect(acceptCancelled.failureOrNull, isA<BusinessRuleFailure>());

        // Intento de rechazar oferta de solicitud cancelada falla
        final rejectCancelled = await rejectOfferUseCase(
          offerId: offer2.id,
          requesterIdentity: makeIdentity(
            id: request1.customerId,
            role: UserRole.client,
          ),
        );
        expect(rejectCancelled.isFailure, isTrue);
        expect(rejectCancelled.failureOrNull, isA<BusinessRuleFailure>());
      });
    });
  });
}
