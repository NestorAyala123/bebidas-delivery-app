import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/core/result/result.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/accept_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_delivery_offers_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_delivery_rating_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_driver_ratings_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/register_delivery_rating_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/reject_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/submit_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/infrastructure/repositories/mock_delivery_repository.dart';
import 'package:bebidas_delivery_app/features/delivery/presentation/pages/delivery_driver_ratings_page.dart';
import 'package:bebidas_delivery_app/features/delivery/presentation/pages/delivery_request_detail_page.dart';
import 'package:bebidas_delivery_app/features/ratings/domain/entities/rating.dart';
import 'package:bebidas_delivery_app/features/ratings/domain/repositories/rating_repository.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/app_user.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';

// ─── Stub use cases ──────────────────────────────────────────────────────────

/// Stub [RatingRepository] backed by an in-memory map.
class _StubRatingRepository implements RatingRepository {
  final Map<String, Rating> _ratings;

  _StubRatingRepository({Map<String, Rating>? ratings})
      : _ratings = ratings ?? {};

  @override
  Future<Result<void, Failure>> submitRating(Rating rating) async {
    _ratings[rating.deliveryRequestId] = rating;
    return const Success(null);
  }

  @override
  Future<Result<List<Rating>, Failure>> getRatingsForUser(
    String userId,
  ) async {
    final list = _ratings.values.where((r) => r.driverId == userId).toList();
    return Success(list);
  }

  @override
  Future<Result<Rating?, Failure>> getRatingByDeliveryRequestId(
    String deliveryRequestId,
  ) async {
    return Success(_ratings[deliveryRequestId]);
  }
}

/// Stub that always fails [getRatingByDeliveryRequestId].
class _FailingRatingRepository implements RatingRepository {
  final String errorMessage;
  _FailingRatingRepository(
      {this.errorMessage = 'Error al cargar la calificación'});

  @override
  Future<Result<void, Failure>> submitRating(Rating rating) async {
    return const FailureResult(ServerFailure('not implemented'));
  }

  @override
  Future<Result<List<Rating>, Failure>> getRatingsForUser(
    String userId,
  ) async {
    return FailureResult(ServerFailure(errorMessage));
  }

  @override
  Future<Result<Rating?, Failure>> getRatingByDeliveryRequestId(
    String deliveryRequestId,
  ) async {
    return FailureResult(ServerFailure(errorMessage));
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

IdentityContract _identity({
  required String id,
  required UserRole role,
  bool isActive = true,
}) {
  return IdentityContract(
    id: id,
    email: '$id@demo.com',
    displayName: 'Usuario $id',
    phoneNumber: null,
    role: role,
    isActive: isActive,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

DeliveryRequest _buildRequest({
  String id = 'req-rating-widget',
  String customerId = 'client-1',
  String? assignedDriverId = 'driver-1',
  DeliveryStatus status = DeliveryStatus.delivered,
}) {
  return DeliveryRequest(
    id: id,
    orderId: 'order-$id',
    customerId: customerId,
    storeId: 'store-1',
    originAddress: 'Origen',
    destinationAddress: 'Destino',
    referenceFare: 3.00,
    isOrderConfirmedByStore: true,
    status: status,
    assignedDriverId: assignedDriverId,
    createdAt: DateTime.utc(2026, 11, 1),
  );
}

/// Pumps the [DeliveryRequestDetailPage] with a tall screen so inner ListView
/// renders all items.
Future<void> _pumpDetailPage(
  WidgetTester tester,
  Widget page,
) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(page);
  await tester.pumpAndSettle();
}

Widget _detailPage({
  required DeliveryRequest request,
  required IdentityContract identity,
  required MockDeliveryRepository deliveryRepo,
  RatingRepository? ratingRepo,
}) {
  final effectiveRatingRepo = ratingRepo ?? _StubRatingRepository();

  return MaterialApp(
    home: DeliveryRequestDetailPage(
      request: request,
      identity: identity,
      getOffersUseCase: GetDeliveryOffersUseCase(deliveryRepo),
      submitOfferUseCase: SubmitDeliveryOfferUseCase(repository: deliveryRepo),
      acceptOfferUseCase: AcceptDeliveryOfferUseCase(deliveryRepo),
      rejectOfferUseCase: RejectDeliveryOfferUseCase(deliveryRepo),
      getDeliveryRatingUseCase: GetDeliveryRatingUseCase(
        deliveryRepository: deliveryRepo,
        ratingRepository: effectiveRatingRepo,
      ),
      registerDeliveryRatingUseCase: RegisterDeliveryRatingUseCase(
        deliveryRepository: deliveryRepo,
        ratingRepository: effectiveRatingRepo,
        idGenerator: () => 'widget-rating-id',
      ),
    ),
  );
}

void main() {
  final fixedDate = DateTime.utc(2026, 11, 12);

  group('Etapa 8 - Pantallas de Calificaciones', () {
    // ─── DeliveryRequestDetailPage - Rating Section ──────────────────────────
    group('DeliveryRequestDetailPage - Rating Section', () {
      late MockDeliveryRepository deliveryRepo;

      setUp(() async {
        deliveryRepo = MockDeliveryRepository(latency: Duration.zero);
        // Seed the delivered request into the repo
        await deliveryRepo.createDeliveryRequest(_buildRequest());
      });

      testWidgets(
        'Muestra opción de calificar cuando status es delivered y no hay rating',
        (tester) async {
          final clientIdentity = _identity(
            id: 'client-1',
            role: UserRole.client,
          );

          await _pumpDetailPage(
            tester,
            _detailPage(
              request: _buildRequest(),
              identity: clientIdentity,
              deliveryRepo: deliveryRepo,
            ),
          );

          // Should show the "Calificar al repartidor" section
          expect(find.text('Calificar al repartidor'), findsOneWidget);
          expect(find.byKey(const Key('open-rating-dialog')), findsOneWidget);
        },
      );

      testWidgets(
        'Permite registrar una calificación y actualiza la vista',
        (tester) async {
          final clientIdentity = _identity(
            id: 'client-1',
            role: UserRole.client,
          );

          await _pumpDetailPage(
            tester,
            _detailPage(
              request: _buildRequest(),
              identity: clientIdentity,
              deliveryRepo: deliveryRepo,
            ),
          );

          // Abrir diálogo de calificación
          await tester.tap(find.byKey(const Key('open-rating-dialog')));
          await tester.pumpAndSettle();

          // Seleccionar 5 estrellas
          expect(find.byKey(const Key('rating-star-5')), findsOneWidget);
          await tester.tap(find.byKey(const Key('rating-star-5')));
          await tester.pump();

          // Escribir comentario opcional
          await tester.enterText(
            find.byKey(const Key('rating-comment-field')),
            'Servicio impecable y puntual',
          );
          await tester.pump();

          // Confirmar calificación
          await tester.tap(find.byKey(const Key('confirm-rating')));
          await tester.pumpAndSettle();

          // Verificar que se registró y la vista cambió
          expect(find.text('Calificación registrada'), findsOneWidget);
          expect(find.text('Puntuación: 5 / 5'), findsOneWidget);
          expect(find.text('Comentario: Servicio impecable y puntual'), findsOneWidget);
          expect(find.byKey(const Key('open-rating-dialog')), findsNothing);
        },
      );

      testWidgets(
        'Oculta opción cuando ya existe una calificación',
        (tester) async {
          final existingRating = Rating(
            id: 'existing-rating',
            deliveryRequestId: 'req-rating-widget',
            customerId: 'client-1',
            driverId: 'driver-1',
            score: 4,
            createdAt: fixedDate,
          );
          final ratingRepo = _StubRatingRepository(
            ratings: {'req-rating-widget': existingRating},
          );

          final clientIdentity = _identity(
            id: 'client-1',
            role: UserRole.client,
          );

          await _pumpDetailPage(
            tester,
            _detailPage(
              request: _buildRequest(),
              identity: clientIdentity,
              deliveryRepo: deliveryRepo,
              ratingRepo: ratingRepo,
            ),
          );

          // The rating form button should NOT appear
          expect(find.byKey(const Key('open-rating-dialog')), findsNothing);
          // The registered rating section should appear
          expect(find.text('Calificación registrada'), findsOneWidget);
        },
      );

      testWidgets(
        'Muestra calificación registrada',
        (tester) async {
          final existingRating = Rating(
            id: 'registered-rating',
            deliveryRequestId: 'req-rating-widget',
            customerId: 'client-1',
            driverId: 'driver-1',
            score: 5,
            comment: 'Muy buen servicio',
            createdAt: fixedDate,
          );
          final ratingRepo = _StubRatingRepository(
            ratings: {'req-rating-widget': existingRating},
          );

          final clientIdentity = _identity(
            id: 'client-1',
            role: UserRole.client,
          );

          await _pumpDetailPage(
            tester,
            _detailPage(
              request: _buildRequest(),
              identity: clientIdentity,
              deliveryRepo: deliveryRepo,
              ratingRepo: ratingRepo,
            ),
          );

          expect(find.text('Calificación registrada'), findsOneWidget);
          expect(find.text('Puntuación: 5 / 5'), findsOneWidget);
          expect(find.text('Comentario: Muy buen servicio'), findsOneWidget);
        },
      );

      testWidgets(
        'No muestra sección de calificación si estado no es delivered',
        (tester) async {
          final pendingRequest = _buildRequest(
            id: 'req-pending',
            status: DeliveryStatus.pendingOffer,
            assignedDriverId: null,
          );
          await deliveryRepo.createDeliveryRequest(pendingRequest);

          final clientIdentity = _identity(
            id: 'client-1',
            role: UserRole.client,
          );

          await _pumpDetailPage(
            tester,
            _detailPage(
              request: pendingRequest,
              identity: clientIdentity,
              deliveryRepo: deliveryRepo,
            ),
          );

          expect(find.text('Calificar al repartidor'), findsNothing);
          expect(find.byKey(const Key('open-rating-dialog')), findsNothing);
          expect(find.text('Calificación registrada'), findsNothing);
        },
      );
    });

    // ─── DeliveryDriverRatingsPage ────────────────────────────────────────────
    group('DeliveryDriverRatingsPage', () {
      testWidgets(
        'Muestra lista vacía correctamente',
        (tester) async {
          final emptyRepo = _StubRatingRepository();

          final driverIdentity = _identity(
            id: 'driver-1',
            role: UserRole.driver,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: DeliveryDriverRatingsPage(
                identity: driverIdentity,
                getDriverRatingsUseCase: GetDriverRatingsUseCase(
                  ratingRepository: emptyRepo,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.text('Aún no tiene calificaciones recibidas.'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Muestra calificaciones recibidas',
        (tester) async {
          final ratingRepo = _StubRatingRepository(
            ratings: {
              'req-a': Rating(
                id: 'rating-a',
                deliveryRequestId: 'req-a',
                customerId: 'client-1',
                driverId: 'driver-1',
                score: 5,
                comment: 'Excelente',
                createdAt: fixedDate,
              ),
            },
          );

          final driverIdentity = _identity(
            id: 'driver-1',
            role: UserRole.driver,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: DeliveryDriverRatingsPage(
                identity: driverIdentity,
                getDriverRatingsUseCase: GetDriverRatingsUseCase(
                  ratingRepository: ratingRepo,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Entrega #req-a'), findsOneWidget);
          expect(find.text('5 / 5'), findsOneWidget);
          expect(find.text('Comentario: Excelente'), findsOneWidget);
        },
      );

      testWidgets(
        'Muestra promedio de calificaciones',
        (tester) async {
          final ratingRepo = _StubRatingRepository(
            ratings: {
              'req-x': Rating(
                id: 'rating-x',
                deliveryRequestId: 'req-x',
                customerId: 'client-1',
                driverId: 'driver-1',
                score: 4,
                createdAt: fixedDate,
              ),
              'req-y': Rating(
                id: 'rating-y',
                deliveryRequestId: 'req-y',
                customerId: 'client-2',
                driverId: 'driver-1',
                score: 2,
                createdAt: fixedDate,
              ),
            },
          );

          final driverIdentity = _identity(
            id: 'driver-1',
            role: UserRole.driver,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: DeliveryDriverRatingsPage(
                identity: driverIdentity,
                getDriverRatingsUseCase: GetDriverRatingsUseCase(
                  ratingRepository: ratingRepo,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Average of 4 + 2 = 3.0
          expect(find.text('3.0 / 5'), findsOneWidget);
          expect(find.text('Calificaciones recibidas (2)'), findsOneWidget);
        },
      );

      testWidgets(
        'Muestra error cuando falla la carga',
        (tester) async {
          final failingRepo =
              _FailingRatingRepository(errorMessage: 'Error de red');

          final driverIdentity = _identity(
            id: 'driver-1',
            role: UserRole.driver,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: DeliveryDriverRatingsPage(
                identity: driverIdentity,
                getDriverRatingsUseCase: GetDriverRatingsUseCase(
                  ratingRepository: failingRepo,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Error de red'), findsOneWidget);
          expect(find.text('Reintentar'), findsOneWidget);
        },
      );
    });
  });
}
