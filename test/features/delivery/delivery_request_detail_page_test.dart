import 'package:flutter/material.dart';
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
import 'package:bebidas_delivery_app/features/delivery/presentation/pages/delivery_request_detail_page.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/app_user.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';

/// Repositorio que simula una falla al consultar las ofertas.
class _FailingOffersRepository extends MockDeliveryRepository {
  _FailingOffersRepository() : super(latency: Duration.zero);

  @override
  Future<Result<List<DeliveryOffer>, Failure>> getOffersByDeliveryRequestId(
    String deliveryRequestId,
  ) async {
    return const FailureResult(ServerFailure('Error al cargar las ofertas'));
  }
}

/// Monta el detalle con una superficie alta para que el `ListView` construya
/// también las acciones que en un teléfono quedan debajo del pliegue.
Future<void> _pumpDetail(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(page);
  await tester.pumpAndSettle();
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

void main() {
  group('DeliveryRequestDetailPage - negociación y asignación', () {
    final fixedDate = DateTime.utc(2026, 11, 2, 12);

    late MockDeliveryRepository repository;
    late DeliveryRequest request;

    setUp(() async {
      repository = MockDeliveryRepository(
        latency: Duration.zero,
        seedTime: fixedDate,
      );

      request = DeliveryRequest(
        id: 'req-detail',
        orderId: 'ord-detail',
        customerId: 'seed-client',
        storeId: 'seed-store',
        originAddress: 'Av. 4 de Noviembre, Manta',
        destinationAddress: 'Calle 12 y Av. 24, Manta',
        distanceInKm: 2.0,
        referenceFare: 3.25,
        isOrderConfirmedByStore: true,
        createdAt: fixedDate,
      );

      await repository.createDeliveryRequest(request);

      repository.registerDriver(
        Driver(
          id: 'seed-driver',
          name: 'Repartidor Demo',
          status: DriverStatus.available,
          createdAt: fixedDate,
        ),
      );
      repository.registerDriver(
        Driver(
          id: 'driver-2',
          name: 'Ana Gómez',
          status: DriverStatus.available,
          createdAt: fixedDate,
        ),
      );
    });

    DeliveryOffer buildOffer({
      required String id,
      required String driverId,
      required String driverName,
      required int cents,
      OfferStatus status = OfferStatus.pending,
    }) {
      return DeliveryOffer(
        id: id,
        deliveryRequestId: request.id,
        driverId: driverId,
        driverName: driverName,
        referenceFareInCents: 325,
        offeredFareInCents: cents,
        status: status,
        createdAt: fixedDate,
      );
    }

    Widget buildPage(
      MockDeliveryRepository repo,
      IdentityContract identity, {
      DeliveryRequest? deliveryRequest,
    }) {
      return MaterialApp(
        home: DeliveryRequestDetailPage(
          request: deliveryRequest ?? request,
          identity: identity,
          getOffersUseCase: GetDeliveryOffersUseCase(repo),
          submitOfferUseCase: SubmitDeliveryOfferUseCase(repository: repo),
          acceptOfferUseCase: AcceptDeliveryOfferUseCase(repo),
          rejectOfferUseCase: RejectDeliveryOfferUseCase(repo),
        ),
      );
    }

    testWidgets('muestra el detalle y compara las ofertas por tarifa', (
      tester,
    ) async {
      repository.registerOffer(
        buildOffer(
          id: 'off-a',
          driverId: 'seed-driver',
          driverName: 'Repartidor Demo',
          cents: 300,
        ),
      );
      repository.registerOffer(
        buildOffer(
          id: 'off-b',
          driverId: 'driver-2',
          driverName: 'Ana Gómez',
          cents: 280,
        ),
      );

      await _pumpDetail(
        tester,
        buildPage(
          repository,
          _identity(id: 'seed-client', role: UserRole.client),
        ),
      );

      expect(find.text('Solicitud #req-detail'), findsOneWidget);
      expect(find.text('Negociación en curso'), findsOneWidget);
      expect(find.text('Ofertas recibidas (2)'), findsOneWidget);
      expect(find.text('Mejor tarifa'), findsOneWidget);
      expect(find.text('Ana Gómez'), findsOneWidget);
      expect(find.text('\$2.80'), findsOneWidget);
      expect(find.text('\$3.00'), findsOneWidget);
      expect(find.text('Contraoferta'), findsNWidgets(2));
    });

    testWidgets('el cliente acepta una oferta y ve el repartidor asignado', (
      tester,
    ) async {
      repository.registerOffer(
        buildOffer(
          id: 'off-a',
          driverId: 'seed-driver',
          driverName: 'Repartidor Demo',
          cents: 300,
        ),
      );
      repository.registerOffer(
        buildOffer(
          id: 'off-b',
          driverId: 'driver-2',
          driverName: 'Ana Gómez',
          cents: 280,
        ),
      );

      await _pumpDetail(
        tester,
        buildPage(
          repository,
          _identity(id: 'seed-client', role: UserRole.client),
        ),
      );

      await tester.tap(find.byKey(const Key('accept-offer-off-b')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirm-accept-offer')), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-accept-offer')));
      await tester.pumpAndSettle();

      expect(
        find.text('Oferta aceptada. Repartidor asignado.'),
        findsOneWidget,
      );
      expect(find.text('Repartidor asignado'), findsWidgets);
      expect(find.text('Repartidor: Ana Gómez'), findsOneWidget);
      expect(find.text('Tarifa acordada: \$2.80'), findsOneWidget);
      expect(find.text('Aceptada'), findsOneWidget);
      expect(find.text('Descartada'), findsOneWidget);

      final driverStatus = await repository.getDriverAvailability('driver-2');
      expect(driverStatus.dataOrNull, DriverStatus.busy);

      final stored = await repository.getDeliveryRequestById(request.id);
      expect(stored.dataOrNull!.assignedDriverId, 'driver-2');
      expect(stored.dataOrNull!.agreedFareInCents, 280);
      expect(stored.dataOrNull!.status, DeliveryStatus.driverAssigned);
    });

    testWidgets(
      'el cliente rechaza una oferta y la solicitud sigue en oferta',
      (tester) async {
        repository.registerOffer(
          buildOffer(
            id: 'off-a',
            driverId: 'seed-driver',
            driverName: 'Repartidor Demo',
            cents: 300,
          ),
        );

        await _pumpDetail(
          tester,
          buildPage(
            repository,
            _identity(id: 'seed-client', role: UserRole.client),
          ),
        );

        await tester.tap(find.byKey(const Key('reject-offer-off-a')));
        await tester.pumpAndSettle();

        expect(find.text('Oferta rechazada.'), findsOneWidget);
        expect(find.text('Rechazada'), findsOneWidget);
        expect(find.text('Negociación en curso'), findsOneWidget);
        expect(
          find.text('0 oferta(s) pendiente(s) de respuesta.'),
          findsOneWidget,
        );

        final stored = await repository.getDeliveryRequestById(request.id);
        expect(stored.dataOrNull!.status, DeliveryStatus.pendingOffer);
        expect(stored.dataOrNull!.assignedDriverId, isNull);
      },
    );

    testWidgets('el repartidor envía una oferta y se refleja en la lista', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        buildPage(
          repository,
          _identity(
            id: 'seed-driver',
            role: UserRole.driver,
            displayName: 'Repartidor Demo',
          ),
        ),
      );

      expect(
        find.text('Aún no hay ofertas. Envía la primera propuesta.'),
        findsOneWidget,
      );
      expect(find.text('Enviar oferta'), findsOneWidget);

      await tester.tap(find.byKey(const Key('submit-offer')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('offer-amount-field')),
        '3.50',
      );
      await tester.tap(find.byKey(const Key('confirm-submit-offer')));
      await tester.pumpAndSettle();

      expect(find.text('Oferta enviada correctamente.'), findsOneWidget);
      expect(find.text('Ofertas recibidas (1)'), findsOneWidget);
      expect(find.text('Repartidor Demo'), findsWidgets);
      expect(find.text('\$3.50'), findsOneWidget);
      expect(find.text('Contraoferta'), findsOneWidget);
      expect(
        find.text('Tu oferta está pendiente de respuesta.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('submit-offer')), findsNothing);

      final offers = await repository.getOffersByDeliveryRequestId(request.id);
      expect(offers.dataOrNull, hasLength(1));
      expect(offers.dataOrNull!.single.offeredFareInCents, 350);
      expect(offers.dataOrNull!.single.driverId, 'seed-driver');
    });

    testWidgets(
      'el repartidor puede enviar una segunda oferta tras un rechazo',
      (tester) async {
        repository.registerOffer(
          buildOffer(
            id: 'off-rejected',
            driverId: 'seed-driver',
            driverName: 'Repartidor Demo',
            cents: 320,
            status: OfferStatus.rejected,
          ),
        );

        await _pumpDetail(
          tester,
          buildPage(
            repository,
            _identity(
              id: 'seed-driver',
              role: UserRole.driver,
              displayName: 'Repartidor Demo',
            ),
          ),
        );

        expect(find.text('Enviar segunda oferta'), findsOneWidget);

        await tester.tap(find.byKey(const Key('submit-offer')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('offer-amount-field')),
          '3.40',
        );
        await tester.tap(find.byKey(const Key('confirm-submit-offer')));
        await tester.pumpAndSettle();

        expect(find.text('Ofertas recibidas (2)'), findsOneWidget);
        expect(find.text('Rechazada'), findsOneWidget);
        expect(find.text('Pendiente'), findsOneWidget);
      },
    );

    testWidgets('no permite una tercera oferta al alcanzar el límite', (
      tester,
    ) async {
      repository.registerOffer(
        buildOffer(
          id: 'off-1',
          driverId: 'seed-driver',
          driverName: 'Repartidor Demo',
          cents: 320,
          status: OfferStatus.rejected,
        ),
      );
      repository.registerOffer(
        buildOffer(
          id: 'off-2',
          driverId: 'seed-driver',
          driverName: 'Repartidor Demo',
          cents: 340,
          status: OfferStatus.rejected,
        ),
      );

      await _pumpDetail(
        tester,
        buildPage(
          repository,
          _identity(id: 'seed-driver', role: UserRole.driver),
        ),
      );

      expect(find.byKey(const Key('submit-offer')), findsNothing);
      expect(
        find.text('Has alcanzado el límite de 2 ofertas para esta solicitud.'),
        findsOneWidget,
      );
    });

    testWidgets('un cliente no propietario no ve acciones de respuesta', (
      tester,
    ) async {
      repository.registerOffer(
        buildOffer(
          id: 'off-a',
          driverId: 'seed-driver',
          driverName: 'Repartidor Demo',
          cents: 300,
        ),
      );

      await _pumpDetail(
        tester,
        buildPage(
          repository,
          _identity(id: 'otro-cliente', role: UserRole.client),
        ),
      );

      expect(find.byKey(const Key('accept-offer-off-a')), findsNothing);
      expect(find.byKey(const Key('reject-offer-off-a')), findsNothing);
      expect(
        find.text(
          'Solo el cliente o comercio propietario puede aceptar o rechazar '
          'estas ofertas.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('una solicitud cancelada se muestra sin acciones', (
      tester,
    ) async {
      final cancelled = DeliveryRequest(
        id: 'req-cancelled',
        orderId: 'ord-cancelled',
        customerId: 'seed-client',
        storeId: 'seed-store',
        originAddress: 'Origen',
        destinationAddress: 'Destino',
        distanceInKm: 1.0,
        referenceFare: 2.00,
        isOrderConfirmedByStore: true,
        status: DeliveryStatus.cancelled,
        createdAt: fixedDate,
      );

      await _pumpDetail(
        tester,
        buildPage(
          repository,
          _identity(id: 'seed-client', role: UserRole.client),
          deliveryRequest: cancelled,
        ),
      );

      expect(find.text('Solicitud cancelada'), findsWidgets);
      expect(
        find.text('No se admiten nuevas ofertas ni asignaciones.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('submit-offer')), findsNothing);
    });

    testWidgets('muestra error al cargar ofertas y permite reintentar', (
      tester,
    ) async {
      final failingRepository = _FailingOffersRepository();

      await _pumpDetail(
        tester,
        buildPage(
          failingRepository,
          _identity(id: 'seed-client', role: UserRole.client),
        ),
      );

      expect(find.text('Error al cargar las ofertas'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
