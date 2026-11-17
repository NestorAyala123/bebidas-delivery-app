import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/core/result/result.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/accept_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_delivery_history_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_delivery_offers_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/reject_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/submit_delivery_offer_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/infrastructure/repositories/mock_delivery_repository.dart';
import 'package:bebidas_delivery_app/features/delivery/presentation/pages/delivery_history_page.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/app_user.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';

/// Repositorio que simula una falla al consultar el historial de delivery.
class _FailingHistoryRepository extends MockDeliveryRepository {
  _FailingHistoryRepository() : super(latency: Duration.zero);

  @override
  Future<Result<List<DeliveryRequest>, Failure>> getDeliveryRequestsByDriver(
    String driverId,
  ) async {
    return const FailureResult(ServerFailure('Error al cargar el historial'));
  }
}

Future<void> _pumpHistory(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(page);
  await tester.pumpAndSettle();
}

DeliveryRequest _request({
  required String id,
  required String orderId,
  required String customerId,
  required String storeId,
  required DeliveryStatus status,
  String? assignedDriverId,
  int? agreedFareInCents,
  DateTime? createdAt,
}) {
  return DeliveryRequest(
    id: id,
    orderId: orderId,
    customerId: customerId,
    storeId: storeId,
    originAddress: 'Av. 4 de Noviembre, Manta',
    destinationAddress: 'Calle 12 y Av. 24, Manta',
    distanceInKm: 3.0,
    referenceFare: 3.25,
    isOrderConfirmedByStore: true,
    status: status,
    assignedDriverId: assignedDriverId,
    agreedFareInCents: agreedFareInCents,
    createdAt: createdAt ?? DateTime.utc(2026, 11, 2, 12),
  );
}

IdentityContract _identity({required String id, required UserRole role}) {
  return IdentityContract(
    id: id,
    email: '$id@demo.com',
    displayName: 'Usuario $id',
    phoneNumber: null,
    role: role,
    isActive: true,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('DeliveryHistoryPage - historial de delivery', () {
    final fixedDate = DateTime.utc(2026, 11, 2, 12);

    late MockDeliveryRepository repository;

    setUp(() async {
      repository = MockDeliveryRepository(
        latency: Duration.zero,
        seedTime: fixedDate,
      );

      await repository.createDeliveryRequest(
        _request(
          id: 'req-h-01',
          orderId: 'ord-h-01',
          customerId: 'seed-client',
          storeId: 'seed-store',
          status: DeliveryStatus.delivered,
          assignedDriverId: 'seed-driver',
          agreedFareInCents: 350,
          createdAt: fixedDate,
        ),
      );
      await repository.createDeliveryRequest(
        _request(
          id: 'req-h-02',
          orderId: 'ord-h-02',
          customerId: 'seed-client',
          storeId: 'seed-store',
          status: DeliveryStatus.driverAssigned,
          assignedDriverId: 'seed-driver',
          agreedFareInCents: 325,
          createdAt: fixedDate,
        ),
      );
      await repository.createDeliveryRequest(
        _request(
          id: 'req-h-03',
          orderId: 'ord-h-03',
          customerId: 'seed-client',
          storeId: 'seed-store',
          status: DeliveryStatus.pendingOffer,
          createdAt: fixedDate,
        ),
      );
    });

    Widget buildPage(
      MockDeliveryRepository repo,
      IdentityContract identity, {
      DeliveryRequest? deliveryRequest,
    }) {
      return MaterialApp(
        home: DeliveryHistoryPage(
          identity: identity,
          getDeliveryHistoryUseCase: GetDeliveryHistoryUseCase(repo),
          getOffersUseCase: GetDeliveryOffersUseCase(repo),
          submitOfferUseCase: SubmitDeliveryOfferUseCase(
            repository: repo,
            idGenerator: () => 'off-h-01',
          ),
          acceptOfferUseCase: AcceptDeliveryOfferUseCase(repo),
          rejectOfferUseCase: RejectDeliveryOfferUseCase(repo),
        ),
      );
    }

    testWidgets('muestra indicador de carga mientras consulta el historial', (
      tester,
    ) async {
      final repo = MockDeliveryRepository(
        latency: const Duration(milliseconds: 100),
      );

      await tester.pumpWidget(
        buildPage(repo, _identity(id: 'seed-client', role: UserRole.client)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('el cliente ve sus operaciones con estado y tarifa acordada', (
      tester,
    ) async {
      await _pumpHistory(
        tester,
        buildPage(
          repository,
          _identity(id: 'seed-client', role: UserRole.client),
        ),
      );

      expect(find.text('Historial de Delivery'), findsOneWidget);
      expect(find.text('Solicitud #req-h-01'), findsOneWidget);
      expect(find.text('Solicitud #req-h-02'), findsOneWidget);
      expect(find.text('Solicitud #req-h-03'), findsOneWidget);
      expect(find.text('Solicitud #req-001'), findsOneWidget);
      expect(find.text('Entregado'), findsOneWidget);
      expect(find.text('Tarifa acordada'), findsNWidgets(2));
      expect(find.text('Repartidor asignado: seed-driver'), findsNWidgets(2));
    });

    testWidgets('el comercio solo ve sus operaciones', (tester) async {
      await repository.createDeliveryRequest(
        _request(
          id: 'req-h-04',
          orderId: 'ord-h-04',
          customerId: 'seed-client',
          storeId: 'otro-comercio',
          status: DeliveryStatus.delivered,
          assignedDriverId: 'seed-driver',
          agreedFareInCents: 300,
          createdAt: fixedDate,
        ),
      );

      await _pumpHistory(
        tester,
        buildPage(
          repository,
          _identity(id: 'seed-store', role: UserRole.store),
        ),
      );

      expect(find.text('Solicitud #req-h-01'), findsOneWidget);
      expect(find.text('Solicitud #req-h-04'), findsNothing);
      expect(find.text('Solicitud #req-h-02'), findsOneWidget);
      expect(find.text('Solicitud #req-h-03'), findsOneWidget);
    });

    testWidgets('el repartidor ve sus operaciones asignadas o negociaciones', (
      tester,
    ) async {
      await _pumpHistory(
        tester,
        buildPage(
          repository,
          _identity(id: 'seed-driver', role: UserRole.driver),
        ),
      );

      expect(find.text('Solicitud #req-h-02'), findsOneWidget);
      expect(find.text('Solicitud #req-h-01'), findsOneWidget);
      expect(find.text('Solicitud #req-h-03'), findsNothing);
      expect(find.text('Repartidor asignado: seed-driver'), findsNWidgets(2));
    });

    testWidgets('muestra estado vacío cuando no hay operaciones', (
      tester,
    ) async {
      await _pumpHistory(
        tester,
        buildPage(repository, _identity(id: 'drv-none', role: UserRole.driver)),
      );

      expect(
        find.text('No hay operaciones de delivery para este repartidor.'),
        findsOneWidget,
      );
    });

    testWidgets('muestra error y permite reintentar', (tester) async {
      final failingRepository = _FailingHistoryRepository();

      await _pumpHistory(
        tester,
        buildPage(
          failingRepository,
          _identity(id: 'seed-driver', role: UserRole.driver),
        ),
      );

      expect(find.text('Error al cargar el historial'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('al tocar una operación abre el detalle', (tester) async {
      await _pumpHistory(
        tester,
        buildPage(
          repository,
          _identity(id: 'seed-client', role: UserRole.client),
        ),
      );

      await tester.tap(find.byKey(const Key('history-req-h-01')));
      await tester.pumpAndSettle();

      expect(find.text('Negociación de Delivery'), findsOneWidget);
      expect(find.text('Entrega completada'), findsOneWidget);
    });
  });
}
