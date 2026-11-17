import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/core/result/result.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/accept_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_delivery_history_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_delivery_offers_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_pending_delivery_requests_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/reject_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/submit_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/infrastructure/repositories/mock_delivery_repository.dart';
import 'package:bebidas_delivery_app/features/delivery/presentation/pages/delivery_offers_page.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/app_user.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';

/// Repositorio que simula una falla al consultar solicitudes pendientes.
class _FailingPendingRequestsRepository extends MockDeliveryRepository {
  _FailingPendingRequestsRepository() : super(latency: Duration.zero);

  @override
  Future<Result<List<DeliveryRequest>, Failure>>
  getPendingDeliveryRequests() async {
    return const FailureResult(
      ServerFailure('No se pudieron cargar las solicitudes'),
    );
  }
}

IdentityContract _identity({
  required String id,
  required UserRole role,
  String? displayName,
}) {
  return IdentityContract(
    id: id,
    email: '$id@demo.com',
    displayName: displayName ?? 'Usuario $id',
    phoneNumber: null,
    role: role,
    isActive: true,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

DeliveryRequest _request({
  required String id,
  required String orderId,
  String customerId = 'seed-client',
  String storeId = 'seed-store',
}) {
  return DeliveryRequest(
    id: id,
    orderId: orderId,
    customerId: customerId,
    storeId: storeId,
    originAddress: 'Av. 4 de Noviembre, Manta',
    destinationAddress: 'Calle 12 y Av. 24, Manta',
    distanceInKm: 2.5,
    referenceFare: 2.75,
    isOrderConfirmedByStore: true,
    status: DeliveryStatus.pendingOffer,
    createdAt: DateTime.utc(2026, 1, 2),
  );
}

Widget _hubPage(MockDeliveryRepository repository, IdentityContract identity) {
  return MaterialApp(
    home: DeliveryOffersPage(
      identity: identity,
      getPendingRequestsUseCase: GetPendingDeliveryRequestsUseCase(repository),
      getDeliveryHistoryUseCase: GetDeliveryHistoryUseCase(repository),
      getOffersUseCase: GetDeliveryOffersUseCase(repository),
      submitOfferUseCase: SubmitDeliveryOfferUseCase(repository: repository),
      acceptOfferUseCase: AcceptDeliveryOfferUseCase(repository),
      rejectOfferUseCase: RejectDeliveryOfferUseCase(repository),
    ),
  );
}

void main() {
  group('DeliveryOffersPage - integración de solicitudes', () {
    testWidgets('muestra indicador de carga mientras consulta', (tester) async {
      final repository = MockDeliveryRepository(
        latency: const Duration(milliseconds: 100),
      );

      await tester.pumpWidget(
        _hubPage(
          repository,
          _identity(id: 'seed-driver', role: UserRole.driver),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('el repartidor ve las solicitudes pendientes', (tester) async {
      final repository = MockDeliveryRepository(latency: Duration.zero);

      await tester.pumpWidget(
        _hubPage(
          repository,
          _identity(id: 'seed-driver', role: UserRole.driver),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ofertas de Delivery'), findsOneWidget);
      expect(find.text('Solicitud #req-001'), findsOneWidget);
      expect(find.text('En oferta'), findsOneWidget);
      expect(
        find.byKey(const Key('manage-driver-availability')),
        findsOneWidget,
      );
    });

    testWidgets('el cliente solo ve sus propias solicitudes', (tester) async {
      final repository = MockDeliveryRepository(latency: Duration.zero);
      await repository.createDeliveryRequest(
        _request(
          id: 'req-other-customer',
          orderId: 'order-other-customer',
          customerId: 'otro-cliente',
        ),
      );

      await tester.pumpWidget(
        _hubPage(
          repository,
          _identity(id: 'seed-client', role: UserRole.client),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mis Solicitudes de Delivery'), findsOneWidget);
      expect(find.text('Solicitud #req-001'), findsOneWidget);
      expect(find.text('Solicitud #req-other-customer'), findsNothing);
    });

    testWidgets('el comercio solo ve sus propias solicitudes', (tester) async {
      final repository = MockDeliveryRepository(latency: Duration.zero);
      await repository.createDeliveryRequest(
        _request(
          id: 'req-other-store',
          orderId: 'order-other-store',
          storeId: 'otro-comercio',
        ),
      );

      await tester.pumpWidget(
        _hubPage(repository, _identity(id: 'seed-store', role: UserRole.store)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delivery del Comercio'), findsOneWidget);
      expect(find.text('Solicitud #req-001'), findsOneWidget);
      expect(find.text('Solicitud #req-other-store'), findsNothing);
      expect(
        find.text('Toca para comparar las ofertas recibidas.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra estado vacío cuando no hay solicitudes', (
      tester,
    ) async {
      final repository = MockDeliveryRepository(latency: Duration.zero);
      await repository.updateStatus('req-001', DeliveryStatus.cancelled.name);

      await tester.pumpWidget(
        _hubPage(
          repository,
          _identity(id: 'seed-driver', role: UserRole.driver),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No hay solicitudes pendientes para ofertar.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra error y permite reintentar', (tester) async {
      final repository = _FailingPendingRequestsRepository();

      await tester.pumpWidget(
        _hubPage(
          repository,
          _identity(id: 'seed-driver', role: UserRole.driver),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudieron cargar las solicitudes'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('al tocar una solicitud abre el detalle de negociación', (
      tester,
    ) async {
      final repository = MockDeliveryRepository(latency: Duration.zero);

      await tester.pumpWidget(
        _hubPage(
          repository,
          _identity(id: 'seed-driver', role: UserRole.driver),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('request-req-001')));
      await tester.pumpAndSettle();

      expect(find.text('Negociación de Delivery'), findsOneWidget);
      expect(find.text('Solicitud #req-001'), findsOneWidget);
      expect(find.text('Ofertas recibidas (0)'), findsOneWidget);
    });

    testWidgets('navega al historial desde el hub de delivery', (tester) async {
      final repository = MockDeliveryRepository(latency: Duration.zero);

      await tester.pumpWidget(
        _hubPage(
          repository,
          _identity(id: 'seed-driver', role: UserRole.driver),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Historial'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Historial de Delivery'), findsOneWidget);
    });

    testWidgets('un rol no participante ve un aviso informativo', (
      tester,
    ) async {
      final repository = MockDeliveryRepository(latency: Duration.zero);

      await tester.pumpWidget(
        _hubPage(
          repository,
          _identity(id: 'seed-event-provider', role: UserRole.eventProvider),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'El módulo de delivery está disponible para clientes, comercios y repartidores.',
        ),
        findsOneWidget,
      );
      expect(find.text('Solicitud #req-001'), findsNothing);
    });
  });
}
