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
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_delivery_offers_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/reject_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/submit_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/infrastructure/repositories/mock_delivery_repository.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/app_user.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';

void main() {
  group('Semana 5 - Casos de Uso y Negociación de Delivery', () {
    late MockDeliveryRepository repository;
    late SubmitDeliveryOfferUseCase submitOfferUseCase;
    late GetDeliveryOffersUseCase getOffersUseCase;
    late AcceptDeliveryOfferUseCase acceptOfferUseCase;
    late RejectDeliveryOfferUseCase rejectOfferUseCase;

    final fixedDate = DateTime(2026, 11, 2, 12, 0);

    late Driver availableDriver1;
    late Driver availableDriver2;
    late Driver busyDriver;
    late Driver offlineDriver;
    late DeliveryRequest pendingRequest;

    setUp(() async {
      repository = MockDeliveryRepository(
        latency: Duration.zero,
        seedTime: fixedDate,
      );

      submitOfferUseCase = SubmitDeliveryOfferUseCase(
        repository: repository,
        idGenerator: () => 'off-generated-01',
      );
      getOffersUseCase = GetDeliveryOffersUseCase(repository);
      acceptOfferUseCase = AcceptDeliveryOfferUseCase(repository);
      rejectOfferUseCase = RejectDeliveryOfferUseCase(repository);

      availableDriver1 = Driver(
        id: 'drv-avail-1',
        name: 'Carlos Mendoza',
        status: DriverStatus.available,
        createdAt: fixedDate,
      );
      availableDriver2 = Driver(
        id: 'drv-avail-2',
        name: 'Ana Gómez',
        status: DriverStatus.available,
        createdAt: fixedDate,
      );
      busyDriver = Driver(
        id: 'drv-busy',
        name: 'Luis Pérez',
        status: DriverStatus.busy,
        createdAt: fixedDate,
      );
      offlineDriver = Driver(
        id: 'drv-off',
        name: 'Mario Rossi',
        status: DriverStatus.offline,
        createdAt: fixedDate,
      );

      repository.registerDriver(availableDriver1);
      repository.registerDriver(availableDriver2);
      repository.registerDriver(busyDriver);
      repository.registerDriver(offlineDriver);

      pendingRequest = DeliveryRequest(
        id: 'req-neg-01',
        orderId: 'ord-neg-01',
        customerId: 'cust-100',
        storeId: 'store-200',
        originAddress: 'Av. 4 de Noviembre, Manta',
        destinationAddress: 'Calle 12 y Av. 24, Manta',
        distanceInKm: 3.5,
        referenceFare: 3.25, // 325 centavos
        isOrderConfirmedByStore: true,
        status: DeliveryStatus.pendingOffer,
        createdAt: fixedDate,
      );

      await repository.createDeliveryRequest(pendingRequest);
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
    // 1. SubmitDeliveryOfferUseCase
    // =========================================================================
    group('1. SubmitDeliveryOfferUseCase (Crear ofertas y contraofertas)', () {
      test(
        'Crea una oferta base directa si no se especifica monto distinto',
        () async {
          final result = await submitOffer(
            deliveryRequestId: pendingRequest.id,
            driverId: availableDriver1.id,
          );

          expect(result.isSuccess, isTrue);
          final offer = result.dataOrNull!;
          expect(offer.deliveryRequestId, equals(pendingRequest.id));
          expect(offer.driverId, equals(availableDriver1.id));
          expect(offer.driverName, equals('Carlos Mendoza'));
          expect(offer.referenceFareInCents, equals(325));
          expect(offer.offeredFareInCents, equals(325));
          expect(offer.isCounterOffer, isFalse);
          expect(offer.status, equals(OfferStatus.pending));
        },
      );

      test('Crea una contraoferta con monto numérico en centavos', () async {
        final result = await submitOffer(
          deliveryRequestId: pendingRequest.id,
          driverId: availableDriver1.id,
          offeredFareInCents: 450,
          comment: 'Ruta con congestión',
        );

        expect(result.isSuccess, isTrue);
        final offer = result.dataOrNull!;
        expect(offer.offeredFareInCents, equals(450));
        expect(offer.offeredFare, equals(4.50));
        expect(offer.isCounterOffer, isTrue);
        expect(offer.comment, equals('Ruta con congestión'));
      });

      test('Crea una contraoferta con entrada textual validada', () async {
        final result = await submitOffer(
          deliveryRequestId: pendingRequest.id,
          driverId: availableDriver1.id,
          offeredFareText: '4.75',
        );

        expect(result.isSuccess, isTrue);
        final offer = result.dataOrNull!;
        expect(offer.offeredFareInCents, equals(475));
        expect(offer.isCounterOffer, isTrue);
      });

      test('Falla si la solicitud no existe', () async {
        final result = await submitOffer(
          deliveryRequestId: 'req-inexistente',
          driverId: availableDriver1.id,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<NotFoundFailure>());
      });

      test(
        'Falla si la solicitud ya está asignada o cancelada (RN-NEG-01)',
        () async {
          final assignedRequest = pendingRequest.assignDriver(
            driverId: 'drv-other',
            agreedFareInCents: 350,
          );
          final mockRepo = MockDeliveryRepository(latency: Duration.zero);
          mockRepo.registerDriver(availableDriver1);
          await mockRepo.createDeliveryRequest(assignedRequest);

          final submit = SubmitDeliveryOfferUseCase(repository: mockRepo);
          final result = await submitOffer(
            deliveryRequestId: assignedRequest.id,
            driverId: availableDriver1.id,
            customUseCase: submit,
          );

          expect(result.isFailure, isTrue);
          expect(result.failureOrNull, isA<BusinessRuleFailure>());
        },
      );

      test('Falla si la solicitud está cancelada', () async {
        final mockRepo = MockDeliveryRepository(latency: Duration.zero);
        mockRepo.registerDriver(availableDriver1);
        await mockRepo.createDeliveryRequest(pendingRequest);
        await mockRepo.updateDeliveryStatus(
          pendingRequest.id,
          DeliveryStatus.cancelled,
        );

        final submit = SubmitDeliveryOfferUseCase(repository: mockRepo);
        final result = await submitOffer(
          deliveryRequestId: pendingRequest.id,
          driverId: availableDriver1.id,
          customUseCase: submit,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<BusinessRuleFailure>());
        expect(result.failureOrNull!.message, contains('cancelada'));
      });

      test(
        'Falla si el repartidor está ocupado u offline (RN-NEG-02)',
        () async {
          final busyResult = await submitOffer(
            deliveryRequestId: pendingRequest.id,
            driverId: busyDriver.id,
          );
          expect(busyResult.isFailure, isTrue);
          expect(busyResult.failureOrNull, isA<BusinessRuleFailure>());

          final offlineResult = await submitOffer(
            deliveryRequestId: pendingRequest.id,
            driverId: offlineDriver.id,
          );
          expect(offlineResult.isFailure, isTrue);
          expect(offlineResult.failureOrNull, isA<BusinessRuleFailure>());
        },
      );

      test('RN-NEG-04: No permite dos ofertas en pending simultáneas para la misma solicitud', () async {
        final first = await submitOffer(
          deliveryRequestId: pendingRequest.id,
          driverId: availableDriver1.id,
          offeredFareInCents: 400,
        );
        expect(first.isSuccess, isTrue);

        final second = await submitOffer(
          deliveryRequestId: pendingRequest.id,
          driverId: availableDriver1.id,
          offeredFareInCents: 450,
        );
        expect(second.isFailure, isTrue);
        expect(second.failureOrNull, isA<BusinessRuleFailure>());
      });

      test('RN-NEG-04: Permite segunda oferta únicamente después de que la primera fue rechazada', () async {
        final customSubmit = SubmitDeliveryOfferUseCase(
          repository: repository,
          idGenerator: () => 'off-intento-1',
        );

        final first = await submitOffer(
          deliveryRequestId: pendingRequest.id,
          driverId: availableDriver1.id,
          offeredFareInCents: 500,
          customUseCase: customSubmit,
        );
        expect(first.isSuccess, isTrue);

        // Cliente rechaza la primera oferta
        await rejectOfferUseCase(
          offerId: first.dataOrNull!.id,
          requesterIdentity: makeIdentity(
            id: 'cust-100',
            role: UserRole.client,
          ),
        );

        // Repartidor envía segunda oferta (contraoferta de rectificación)
        final customSubmit2 = SubmitDeliveryOfferUseCase(
          repository: repository,
          idGenerator: () => 'off-intento-2',
        );
        final second = await submitOffer(
          deliveryRequestId: pendingRequest.id,
          driverId: availableDriver1.id,
          offeredFareInCents: 425,
          customUseCase: customSubmit2,
        );
        expect(second.isSuccess, isTrue);
        expect(second.dataOrNull!.offeredFareInCents, equals(425));

        // Cliente rechaza la segunda oferta
        await rejectOfferUseCase(
          offerId: second.dataOrNull!.id,
          requesterIdentity: makeIdentity(
            id: 'cust-100',
            role: UserRole.client,
          ),
        );

        // Intento de una tercera oferta falla por límite máximo de 2 acumuladas
        final customSubmit3 = SubmitDeliveryOfferUseCase(
          repository: repository,
          idGenerator: () => 'off-intento-3',
        );
        final third = await submitOffer(
          deliveryRequestId: pendingRequest.id,
          driverId: availableDriver1.id,
          offeredFareInCents: 380,
          customUseCase: customSubmit3,
        );
        expect(third.isFailure, isTrue);
        expect(third.failureOrNull, isA<BusinessRuleFailure>());
      });

      test(
        'Rechaza tarifas con formato inválido o más de dos decimales',
        () async {
          final invalidText = await submitOffer(
            deliveryRequestId: pendingRequest.id,
            driverId: availableDriver1.id,
            offeredFareText: '4.555',
          );
          expect(invalidText.isFailure, isTrue);
          expect(invalidText.failureOrNull, isA<ValidationFailure>());

          final negativeCents = await submitOffer(
            deliveryRequestId: pendingRequest.id,
            driverId: availableDriver1.id,
            offeredFareInCents: -50,
          );
          expect(negativeCents.isFailure, isTrue);
          expect(negativeCents.failureOrNull, isA<ValidationFailure>());
        },
      );

      test(
        'Autorización obligatoria al ofertar: falla si driverIdentity es null',
        () async {
          final result = await submitOfferUseCase(
            deliveryRequestId: pendingRequest.id,
            driverId: availableDriver1.id,
            driverIdentity: null,
          );
          expect(result.isFailure, isTrue);
          expect(result.failureOrNull, isA<UnauthorizedFailure>());
        },
      );

      test('Autorización obligatoria al ofertar: falla si driverIdentity está inactiva', () async {
        final result = await submitOfferUseCase(
          deliveryRequestId: pendingRequest.id,
          driverId: availableDriver1.id,
          driverIdentity: makeIdentity(
            id: availableDriver1.id,
            role: UserRole.driver,
            isActive: false,
          ),
        );
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });

      test(
        'Autorización obligatoria al ofertar: falla si el rol no es repartidor',
        () async {
          final result = await submitOfferUseCase(
            deliveryRequestId: pendingRequest.id,
            driverId: availableDriver1.id,
            driverIdentity: makeIdentity(
              id: availableDriver1.id,
              role: UserRole.client,
            ),
          );
          expect(result.isFailure, isTrue);
          expect(result.failureOrNull, isA<UnauthorizedFailure>());
        },
      );

      test('Autorización obligatoria al ofertar: falla si driverId no coincide con la identidad', () async {
        final result = await submitOfferUseCase(
          deliveryRequestId: pendingRequest.id,
          driverId: availableDriver1.id,
          driverIdentity: makeIdentity(
            id: 'otro-repartidor-id',
            role: UserRole.driver,
          ),
        );
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });
    });

    // =========================================================================
    // 2. GetDeliveryOffersUseCase
    // =========================================================================
    group('2. GetDeliveryOffersUseCase (Consultar ofertas)', () {
      test('Retorna lista de ofertas registradas para la solicitud', () async {
        await submitOffer(
          deliveryRequestId: pendingRequest.id,
          driverId: availableDriver1.id,
          offeredFareInCents: 350,
        );

        final submit2 = SubmitDeliveryOfferUseCase(
          repository: repository,
          idGenerator: () => 'off-drv2',
        );
        await submitOffer(
          deliveryRequestId: pendingRequest.id,
          driverId: availableDriver2.id,
          offeredFareInCents: 400,
          customUseCase: submit2,
        );

        final result = await getOffersUseCase(pendingRequest.id);
        expect(result.isSuccess, isTrue);
        final offers = result.dataOrNull!;
        expect(offers, hasLength(2));
      });

      test('Retorna lista vacía si no hay ofertas creadas', () async {
        final result = await getOffersUseCase(pendingRequest.id);
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!, isEmpty);
      });

      test('Falla de validación si deliveryRequestId está vacío', () async {
        final result = await getOffersUseCase('   ');
        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
      });
    });

    // =========================================================================
    // 3. RejectDeliveryOfferUseCase
    // =========================================================================
    group(
      '3. RejectDeliveryOfferUseCase (Rechazar ofertas con autorización)',
      () {
        test(
          'Cliente dueño de la orden rechaza una oferta exitosamente',
          () async {
            final offerResult = await submitOffer(
              deliveryRequestId: pendingRequest.id,
              driverId: availableDriver1.id,
              offeredFareInCents: 500,
            );
            final offer = offerResult.dataOrNull!;

            final rejectResult = await rejectOfferUseCase(
              offerId: offer.id,
              requesterIdentity: makeIdentity(
                id: 'cust-100',
                role: UserRole.client,
              ),
            );

            expect(rejectResult.isSuccess, isTrue);
            final rejected = rejectResult.dataOrNull!;
            expect(rejected.status, equals(OfferStatus.rejected));
            expect(rejected.isRejected, isTrue);

            // La solicitud permanece en pendingOffer
            final requestCheck = await repository.getDeliveryRequestById(
              pendingRequest.id,
            );
            expect(
              requestCheck.dataOrNull!.status,
              equals(DeliveryStatus.pendingOffer),
            );
          },
        );

        test(
          'Tienda dueña de la orden rechaza una oferta exitosamente',
          () async {
            final offerResult = await submitOffer(
              deliveryRequestId: pendingRequest.id,
              driverId: availableDriver1.id,
              offeredFareInCents: 500,
            );
            final offer = offerResult.dataOrNull!;

            final rejectResult = await rejectOfferUseCase(
              offerId: offer.id,
              requesterIdentity: makeIdentity(
                id: 'store-200',
                role: UserRole.store,
              ),
            );

            expect(rejectResult.isSuccess, isTrue);
            expect(
              rejectResult.dataOrNull!.status,
              equals(OfferStatus.rejected),
            );
          },
        );

        test(
          'Usuario no autorizado (otro cliente) falla con UnauthorizedFailure',
          () async {
            final offerResult = await submitOffer(
              deliveryRequestId: pendingRequest.id,
              driverId: availableDriver1.id,
              offeredFareInCents: 500,
            );
            final offer = offerResult.dataOrNull!;

            final rejectResult = await rejectOfferUseCase(
              offerId: offer.id,
              requesterIdentity: makeIdentity(
                id: 'cust-intruso',
                role: UserRole.client,
              ),
            );

            expect(rejectResult.isFailure, isTrue);
            expect(rejectResult.failureOrNull, isA<UnauthorizedFailure>());
          },
        );

        test(
          'Repartidor intentando rechazar falla con UnauthorizedFailure',
          () async {
            final offerResult = await submitOffer(
              deliveryRequestId: pendingRequest.id,
              driverId: availableDriver1.id,
              offeredFareInCents: 500,
            );
            final offer = offerResult.dataOrNull!;

            final rejectResult = await rejectOfferUseCase(
              offerId: offer.id,
              requesterIdentity: makeIdentity(
                id: availableDriver1.id,
                role: UserRole.driver,
              ),
            );

            expect(rejectResult.isFailure, isTrue);
            expect(rejectResult.failureOrNull, isA<UnauthorizedFailure>());
          },
        );

        test(
          'Falla al rechazar si requesterIdentity es null o inactiva',
          () async {
            final offer = (await submitOffer(
              deliveryRequestId: pendingRequest.id,
              driverId: availableDriver1.id,
            )).dataOrNull!;

            final rejectNull = await rejectOfferUseCase(
              offerId: offer.id,
              requesterIdentity: null,
            );
            expect(rejectNull.isFailure, isTrue);
            expect(rejectNull.failureOrNull, isA<UnauthorizedFailure>());

            final rejectInactive = await rejectOfferUseCase(
              offerId: offer.id,
              requesterIdentity: makeIdentity(
                id: 'cust-100',
                role: UserRole.client,
                isActive: false,
              ),
            );
            expect(rejectInactive.isFailure, isTrue);
            expect(rejectInactive.failureOrNull, isA<UnauthorizedFailure>());
          },
        );
      },
    );

    // =========================================================================
    // 4. AcceptDeliveryOfferUseCase & Asignación Atómica
    // =========================================================================
    group(
      '4. AcceptDeliveryOfferUseCase (Aceptación y Asignación Atómica)',
      () {
        test('Aceptación exitosa: actualiza solicitud, conductor y descarta ofertas rivales', () async {
          // Driver 1 envía oferta por 4.00
          final submit1 = SubmitDeliveryOfferUseCase(
            repository: repository,
            idGenerator: () => 'off-drv1',
          );
          final offer1Result = await submitOffer(
            deliveryRequestId: pendingRequest.id,
            driverId: availableDriver1.id,
            offeredFareInCents: 400,
            customUseCase: submit1,
          );
          final offer1 = offer1Result.dataOrNull!;

          // Driver 2 envía oferta por 3.80
          final submit2 = SubmitDeliveryOfferUseCase(
            repository: repository,
            idGenerator: () => 'off-drv2',
          );
          final offer2Result = await submitOffer(
            deliveryRequestId: pendingRequest.id,
            driverId: availableDriver2.id,
            offeredFareInCents: 380,
            customUseCase: submit2,
          );
          final offer2 = offer2Result.dataOrNull!;

          // Cliente acepta oferta 2 (Ana Gómez)
          final acceptResult = await acceptOfferUseCase(
            offerId: offer2.id,
            requesterIdentity: makeIdentity(
              id: 'cust-100',
              role: UserRole.client,
            ),
          );

          expect(acceptResult.isSuccess, isTrue);
          final updatedRequest = acceptResult.dataOrNull!;

          // 1. Solicitud asignada con repartidor y tarifa acordada
          expect(updatedRequest.status, equals(DeliveryStatus.driverAssigned));
          expect(updatedRequest.assignedDriverId, equals(availableDriver2.id));
          expect(updatedRequest.agreedFareInCents, equals(380));
          expect(updatedRequest.agreedFare, equals(3.80));

          // 2. Conductor ganador pasa a busy
          final driver2Check = await repository.getDriverAvailability(
            availableDriver2.id,
          );
          expect(driver2Check.dataOrNull, equals(DriverStatus.busy));

          // 3. Oferta ganadora pasa a accepted
          final offer2Check = await repository.getDeliveryOfferById(offer2.id);
          expect(offer2Check.dataOrNull!.status, equals(OfferStatus.accepted));

          // 4. Oferta rival pasa a discarded
          final offer1Check = await repository.getDeliveryOfferById(offer1.id);
          expect(offer1Check.dataOrNull!.status, equals(OfferStatus.discarded));

          // 5. Conductor 1 permanece available para otras solicitudes
          final driver1Check = await repository.getDriverAvailability(
            availableDriver1.id,
          );
          expect(driver1Check.dataOrNull, equals(DriverStatus.available));
        });

        test('Tienda autorizada acepta oferta exitosamente', () async {
          final offerResult = await submitOffer(
            deliveryRequestId: pendingRequest.id,
            driverId: availableDriver1.id,
            offeredFareInCents: 350,
          );
          final offer = offerResult.dataOrNull!;

          final acceptResult = await acceptOfferUseCase(
            offerId: offer.id,
            requesterIdentity: makeIdentity(
              id: 'store-200',
              role: UserRole.store,
            ),
          );

          expect(acceptResult.isSuccess, isTrue);
          expect(
            acceptResult.dataOrNull!.status,
            equals(DeliveryStatus.driverAssigned),
          );
        });

        test('RN-NEG-06: Si el repartidor dejó de estar disponible, la aceptación falla y solicitud sigue en pendingOffer', () async {
          final offerResult = await submitOffer(
            deliveryRequestId: pendingRequest.id,
            driverId: availableDriver1.id,
            offeredFareInCents: 350,
          );
          final offer = offerResult.dataOrNull!;

          // Conductor pasa a busy externamente antes de la aceptación
          await repository.setDriverAvailability(
            availableDriver1.id,
            DriverStatus.busy,
          );

          final acceptResult = await acceptOfferUseCase(
            offerId: offer.id,
            requesterIdentity: makeIdentity(
              id: 'cust-100',
              role: UserRole.client,
            ),
          );

          expect(acceptResult.isFailure, isTrue);
          expect(acceptResult.failureOrNull, isA<BusinessRuleFailure>());

          // Solicitud sigue en pendingOffer
          final requestCheck = await repository.getDeliveryRequestById(
            pendingRequest.id,
          );
          expect(
            requestCheck.dataOrNull!.status,
            equals(DeliveryStatus.pendingOffer),
          );
          expect(requestCheck.dataOrNull!.assignedDriverId, isNull);

          // Oferta fue descartada
          final offerCheck = await repository.getDeliveryOfferById(offer.id);
          expect(offerCheck.dataOrNull!.status, equals(OfferStatus.discarded));
        });

        test('Carrera de concurrencia: si solicitud ya fue asignada, la segunda aceptación falla sin mutar entidades', () async {
          final submit1 = SubmitDeliveryOfferUseCase(
            repository: repository,
            idGenerator: () => 'off-carrera-1',
          );
          final offer1 = (await submitOffer(
            deliveryRequestId: pendingRequest.id,
            driverId: availableDriver1.id,
            offeredFareInCents: 350,
            customUseCase: submit1,
          )).dataOrNull!;

          final submit2 = SubmitDeliveryOfferUseCase(
            repository: repository,
            idGenerator: () => 'off-carrera-2',
          );
          final offer2 = (await submitOffer(
            deliveryRequestId: pendingRequest.id,
            driverId: availableDriver2.id,
            offeredFareInCents: 360,
            customUseCase: submit2,
          )).dataOrNull!;

          // Primera aceptación triunfa
          final firstAccept = await acceptOfferUseCase(
            offerId: offer1.id,
            requesterIdentity: makeIdentity(
              id: 'cust-100',
              role: UserRole.client,
            ),
          );
          expect(firstAccept.isSuccess, isTrue);

          // Segunda llamada concurrente intenta aceptar oferta 2
          final secondAccept = await acceptOfferUseCase(
            offerId: offer2.id,
            requesterIdentity: makeIdentity(
              id: 'cust-100',
              role: UserRole.client,
            ),
          );

          // Falla sin tocar la solicitud ni cambiar el ganador previo
          expect(secondAccept.isFailure, isTrue);
          expect(secondAccept.failureOrNull, isA<BusinessRuleFailure>());

          final finalRequest = (await repository.getDeliveryRequestById(
            pendingRequest.id,
          )).dataOrNull!;
          expect(finalRequest.assignedDriverId, equals(availableDriver1.id));
          expect(finalRequest.agreedFareInCents, equals(350));
        });

        test('Usuario no autorizado falla con UnauthorizedFailure', () async {
          final offer = (await submitOffer(
            deliveryRequestId: pendingRequest.id,
            driverId: availableDriver1.id,
          )).dataOrNull!;

          final acceptResult = await acceptOfferUseCase(
            offerId: offer.id,
            requesterIdentity: makeIdentity(
              id: 'cust-otro',
              role: UserRole.client,
            ),
          );

          expect(acceptResult.isFailure, isTrue);
          expect(acceptResult.failureOrNull, isA<UnauthorizedFailure>());
        });

        test(
          'Falla al aceptar si requesterIdentity es null o inactiva',
          () async {
            final offer = (await submitOffer(
              deliveryRequestId: pendingRequest.id,
              driverId: availableDriver1.id,
            )).dataOrNull!;

            final acceptNull = await acceptOfferUseCase(
              offerId: offer.id,
              requesterIdentity: null,
            );
            expect(acceptNull.isFailure, isTrue);
            expect(acceptNull.failureOrNull, isA<UnauthorizedFailure>());

            final acceptInactive = await acceptOfferUseCase(
              offerId: offer.id,
              requesterIdentity: makeIdentity(
                id: 'cust-100',
                role: UserRole.client,
                isActive: false,
              ),
            );
            expect(acceptInactive.isFailure, isTrue);
            expect(acceptInactive.failureOrNull, isA<UnauthorizedFailure>());
          },
        );

        test(
          'Rechazo de autorización al aceptar no produce mutaciones',
          () async {
            final offer = (await submitOffer(
              deliveryRequestId: pendingRequest.id,
              driverId: availableDriver1.id,
              offeredFareInCents: 400,
            )).dataOrNull!;

            final acceptUnauthorized = await acceptOfferUseCase(
              offerId: offer.id,
              requesterIdentity: makeIdentity(
                id: 'cust-intruso',
                role: UserRole.client,
              ),
            );
            expect(acceptUnauthorized.isFailure, isTrue);

            final req = (await repository.getDeliveryRequestById(
              pendingRequest.id,
            )).dataOrNull!;
            expect(req.status, equals(DeliveryStatus.pendingOffer));
            expect(req.assignedDriverId, isNull);

            final off = (await repository.getDeliveryOfferById(offer.id))
                .dataOrNull!;
            expect(off.status, equals(OfferStatus.pending));

            final drv = (await repository.getDriverAvailability(
              availableDriver1.id,
            )).dataOrNull!;
            expect(drv, equals(DriverStatus.available));
          },
        );
      },
    );
  });
}
