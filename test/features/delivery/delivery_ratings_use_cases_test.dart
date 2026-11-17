import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_delivery_rating_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_driver_ratings_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/register_delivery_rating_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/infrastructure/repositories/mock_delivery_repository.dart';
import 'package:bebidas_delivery_app/features/ratings/domain/entities/rating.dart';
import 'package:bebidas_delivery_app/features/ratings/infrastructure/repositories/mock_rating_repository.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/app_user.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

IdentityContract _makeIdentity({
  required String id,
  required UserRole role,
  bool isActive = true,
}) {
  return IdentityContract(
    id: id,
    email: '$id@test.com',
    displayName: 'Usuario $id',
    phoneNumber: null,
    role: role,
    isActive: isActive,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

/// Creates a [DeliveryRequest] seeded into [repo] with
/// [status] = `delivered` and [assignedDriverId] = `driverId`.
/// Both `customerId` and `driverId` can be overridden.
Future<DeliveryRequest> _seedDeliveredRequest(
  MockDeliveryRepository repo, {
  String id = 'req-rating-test',
  String customerId = 'client-1',
  String driverId = 'driver-1',
  DeliveryStatus status = DeliveryStatus.delivered,
  bool includeDriver = true,
}) async {
  final request = DeliveryRequest(
    id: id,
    orderId: 'order-$id',
    customerId: customerId,
    storeId: 'store-1',
    originAddress: 'Origen',
    destinationAddress: 'Destino',
    referenceFare: 3.00,
    isOrderConfirmedByStore: true,
    status: status,
    assignedDriverId: includeDriver ? driverId : null,
    createdAt: DateTime.utc(2026, 11, 1),
  );
  await repo.createDeliveryRequest(request);
  return request;
}

void main() {
  group('Etapa 8 - Sistema de Calificaciones', () {
    late MockDeliveryRepository deliveryRepo;
    late MockRatingRepository ratingRepo;
    late RegisterDeliveryRatingUseCase registerRatingUseCase;
    late GetDeliveryRatingUseCase getDeliveryRatingUseCase;
    late GetDriverRatingsUseCase getDriverRatingsUseCase;

    final fixedDate = DateTime.utc(2026, 11, 12);

    setUp(() {
      deliveryRepo = MockDeliveryRepository(latency: Duration.zero);
      ratingRepo = MockRatingRepository(latency: Duration.zero);
      registerRatingUseCase = RegisterDeliveryRatingUseCase(
        deliveryRepository: deliveryRepo,
        ratingRepository: ratingRepo,
        idGenerator: () => 'generated-rating-id',
      );
      getDeliveryRatingUseCase = GetDeliveryRatingUseCase(
        deliveryRepository: deliveryRepo,
        ratingRepository: ratingRepo,
      );
      getDriverRatingsUseCase = GetDriverRatingsUseCase(
        ratingRepository: ratingRepo,
      );
    });

    // ─── RegisterDeliveryRatingUseCase ──────────────────────────────────────

    group('RegisterDeliveryRatingUseCase', () {
      test('Calificación válida registra exitosamente', () async {
        await _seedDeliveredRequest(deliveryRepo);

        final clientIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
        );

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          score: 5,
          comment: 'Excelente servicio',
          customerIdentity: clientIdentity,
          createdAt: fixedDate,
        );

        expect(result.isSuccess, isTrue);
        final rating = result.dataOrNull!;
        expect(rating.score, 5);
        expect(rating.comment, 'Excelente servicio');
        expect(rating.customerId, 'client-1');
        expect(rating.driverId, 'driver-1');
        expect(rating.deliveryRequestId, 'req-rating-test');
      });

      test('Falla si puntuación es menor que 1', () async {
        await _seedDeliveredRequest(deliveryRepo);

        final clientIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
        );

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          score: 0,
          customerIdentity: clientIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
      });

      test('Falla si puntuación es mayor que 5', () async {
        await _seedDeliveredRequest(deliveryRepo);

        final clientIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
        );

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          score: 6,
          customerIdentity: clientIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
      });

      test('Falla si comentario supera 500 caracteres', () async {
        await _seedDeliveredRequest(deliveryRepo);

        final clientIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
        );
        final longComment = 'x' * 501;

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          score: 4,
          comment: longComment,
          customerIdentity: clientIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
      });

      test('Falla si identity es null', () async {
        await _seedDeliveredRequest(deliveryRepo);

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          score: 4,
          customerIdentity: null,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });

      test('Falla si identity está inactiva', () async {
        await _seedDeliveredRequest(deliveryRepo);

        final inactiveIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
          isActive: false,
        );

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          score: 4,
          customerIdentity: inactiveIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });

      test('Falla si rol no es cliente', () async {
        await _seedDeliveredRequest(deliveryRepo);

        final driverIdentity = _makeIdentity(
          id: 'driver-1',
          role: UserRole.driver,
        );

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          score: 4,
          customerIdentity: driverIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });

      test('Falla si cliente no es propietario de la solicitud', () async {
        await _seedDeliveredRequest(deliveryRepo);

        final otherClientIdentity = _makeIdentity(
          id: 'client-other',
          role: UserRole.client,
        );

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          score: 4,
          customerIdentity: otherClientIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });

      test('Falla si cliente intenta calificar su propia entrega', () async {
        await _seedDeliveredRequest(
          deliveryRepo,
          id: 'req-own-delivery',
          customerId: 'user-same',
          driverId: 'user-same',
        );

        final clientIdentity = _makeIdentity(
          id: 'user-same',
          role: UserRole.client,
        );

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-own-delivery',
          score: 5,
          customerIdentity: clientIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<BusinessRuleFailure>());
      });

      test('Falla si solicitud no está en estado delivered', () async {
        // Status pendingOffer (default)
        await _seedDeliveredRequest(
          deliveryRepo,
          id: 'req-not-delivered',
          status: DeliveryStatus.pendingOffer,
          includeDriver: false,
        );

        final clientIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
        );

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-not-delivered',
          score: 4,
          customerIdentity: clientIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<BusinessRuleFailure>());
      });

      test('Falla si solicitud no tiene repartidor asignado', () async {
        await _seedDeliveredRequest(
          deliveryRepo,
          id: 'req-no-driver',
          status: DeliveryStatus.delivered,
          includeDriver: false,
        );

        final clientIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
        );

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-no-driver',
          score: 4,
          customerIdentity: clientIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<BusinessRuleFailure>());
      });

      test('Falla en calificación duplicada', () async {
        await _seedDeliveredRequest(deliveryRepo);

        final clientIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
        );

        // First rating should succeed
        final first = await registerRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          score: 5,
          customerIdentity: clientIdentity,
          createdAt: fixedDate,
        );
        expect(first.isSuccess, isTrue);

        // Second rating should fail
        final second = await registerRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          score: 3,
          customerIdentity: clientIdentity,
          createdAt: fixedDate,
        );
        expect(second.isFailure, isTrue);
        expect(second.failureOrNull, isA<BusinessRuleFailure>());
      });

      test('Comentario vacío se normaliza a null', () async {
        await _seedDeliveredRequest(deliveryRepo);

        final clientIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
        );

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          score: 4,
          comment: '   ',
          customerIdentity: clientIdentity,
          createdAt: fixedDate,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!.comment, isNull);
      });

      test('Comentario de exactamente 500 caracteres es válido', () async {
        await _seedDeliveredRequest(deliveryRepo);

        final clientIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
        );
        final exactly500 = 'a' * 500;

        final result = await registerRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          score: 3,
          comment: exactly500,
          customerIdentity: clientIdentity,
          createdAt: fixedDate,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!.comment, exactly500);
      });
    });

    // ─── GetDeliveryRatingUseCase ────────────────────────────────────────────

    group('GetDeliveryRatingUseCase', () {
      setUp(() async {
        // Seed a delivered request for most tests
        await _seedDeliveredRequest(deliveryRepo);
      });

      test('Consulta calificación existente exitosamente', () async {
        // Pre-seed a rating
        final rating = Rating(
          id: 'rating-1',
          deliveryRequestId: 'req-rating-test',
          customerId: 'client-1',
          driverId: 'driver-1',
          score: 4,
          createdAt: fixedDate,
        );
        await ratingRepo.submitRating(rating);

        final clientIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
        );

        final result = await getDeliveryRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          requesterIdentity: clientIdentity,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isNotNull);
        expect(result.dataOrNull!.score, 4);
      });

      test('Retorna null cuando no hay calificación', () async {
        final clientIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
        );

        final result = await getDeliveryRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          requesterIdentity: clientIdentity,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isNull);
      });

      test('Falla si identity es null', () async {
        final result = await getDeliveryRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          requesterIdentity: null,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });

      test('Falla si identity está inactiva', () async {
        final inactiveIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
          isActive: false,
        );

        final result = await getDeliveryRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          requesterIdentity: inactiveIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });

      test('Cliente propietario puede consultar', () async {
        final clientIdentity = _makeIdentity(
          id: 'client-1',
          role: UserRole.client,
        );

        final result = await getDeliveryRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          requesterIdentity: clientIdentity,
        );

        expect(result.isSuccess, isTrue);
      });

      test('Repartidor asignado puede consultar', () async {
        final driverIdentity = _makeIdentity(
          id: 'driver-1',
          role: UserRole.driver,
        );

        final result = await getDeliveryRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          requesterIdentity: driverIdentity,
        );

        expect(result.isSuccess, isTrue);
      });

      test('Usuario no autorizado falla', () async {
        // A different client who doesn't own the request
        final strangerIdentity = _makeIdentity(
          id: 'client-stranger',
          role: UserRole.client,
        );

        final result = await getDeliveryRatingUseCase(
          deliveryRequestId: 'req-rating-test',
          requesterIdentity: strangerIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });
    });

    // ─── GetDriverRatingsUseCase ─────────────────────────────────────────────

    group('GetDriverRatingsUseCase', () {
      test('Repartidor consulta sus calificaciones', () async {
        // Add a rating
        final rating = Rating(
          id: 'rating-a',
          deliveryRequestId: 'req-a',
          customerId: 'client-1',
          driverId: 'driver-1',
          score: 5,
          createdAt: fixedDate,
        );
        await ratingRepo.submitRating(rating);

        final driverIdentity = _makeIdentity(
          id: 'driver-1',
          role: UserRole.driver,
        );

        final result = await getDriverRatingsUseCase(
          driverId: 'driver-1',
          driverIdentity: driverIdentity,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, hasLength(1));
        expect(result.dataOrNull!.first.score, 5);
      });

      test('Lista vacía cuando no hay calificaciones', () async {
        final driverIdentity = _makeIdentity(
          id: 'driver-1',
          role: UserRole.driver,
        );

        final result = await getDriverRatingsUseCase(
          driverId: 'driver-1',
          driverIdentity: driverIdentity,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isEmpty);
      });

      test('Falla si identity es null', () async {
        final result = await getDriverRatingsUseCase(
          driverId: 'driver-1',
          driverIdentity: null,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });

      test('Falla si identity está inactiva', () async {
        final inactiveIdentity = _makeIdentity(
          id: 'driver-1',
          role: UserRole.driver,
          isActive: false,
        );

        final result = await getDriverRatingsUseCase(
          driverId: 'driver-1',
          driverIdentity: inactiveIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });

      test('Falla si rol no es repartidor', () async {
        final clientIdentity = _makeIdentity(
          id: 'driver-1',
          role: UserRole.client,
        );

        final result = await getDriverRatingsUseCase(
          driverId: 'driver-1',
          driverIdentity: clientIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });

      test('Falla si driverId no coincide con identity.id', () async {
        final driverIdentity = _makeIdentity(
          id: 'driver-1',
          role: UserRole.driver,
        );

        final result = await getDriverRatingsUseCase(
          driverId: 'driver-99-other',
          driverIdentity: driverIdentity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });

      test('Calcula promedio correctamente', () async {
        // Submit 3 ratings for driver-1
        await ratingRepo.submitRating(
          Rating(
            id: 'rating-r1',
            deliveryRequestId: 'req-r1',
            customerId: 'client-a',
            driverId: 'driver-1',
            score: 5,
            createdAt: fixedDate,
          ),
        );
        await ratingRepo.submitRating(
          Rating(
            id: 'rating-r2',
            deliveryRequestId: 'req-r2',
            customerId: 'client-b',
            driverId: 'driver-1',
            score: 3,
            createdAt: fixedDate,
          ),
        );
        await ratingRepo.submitRating(
          Rating(
            id: 'rating-r3',
            deliveryRequestId: 'req-r3',
            customerId: 'client-c',
            driverId: 'driver-1',
            score: 4,
            createdAt: fixedDate,
          ),
        );

        final driverIdentity = _makeIdentity(
          id: 'driver-1',
          role: UserRole.driver,
        );

        final result = await getDriverRatingsUseCase(
          driverId: 'driver-1',
          driverIdentity: driverIdentity,
        );

        expect(result.isSuccess, isTrue);
        final ratings = result.dataOrNull!;
        final total = ratings.fold<int>(0, (sum, r) => sum + r.score);
        final avg = total / ratings.length;
        expect(avg, closeTo(4.0, 0.001)); // (5+3+4)/3 = 4.0
      });

      test('Cuenta calificaciones correctamente', () async {
        await ratingRepo.submitRating(
          Rating(
            id: 'rating-c1',
            deliveryRequestId: 'req-c1',
            customerId: 'client-a',
            driverId: 'driver-1',
            score: 5,
            createdAt: fixedDate,
          ),
        );
        await ratingRepo.submitRating(
          Rating(
            id: 'rating-c2',
            deliveryRequestId: 'req-c2',
            customerId: 'client-b',
            driverId: 'driver-1',
            score: 2,
            createdAt: fixedDate,
          ),
        );

        final driverIdentity = _makeIdentity(
          id: 'driver-1',
          role: UserRole.driver,
        );

        final result = await getDriverRatingsUseCase(
          driverId: 'driver-1',
          driverIdentity: driverIdentity,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, hasLength(2));
      });
    });
  });
}
