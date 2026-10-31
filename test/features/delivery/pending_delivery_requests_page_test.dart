import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/core/result/result.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/driver_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/repositories/delivery_repository.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_pending_delivery_requests_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/infrastructure/repositories/mock_delivery_repository.dart';
import 'package:bebidas_delivery_app/features/delivery/presentation/pages/pending_delivery_requests_page.dart';

/// Repositorio doble de prueba para simular fallas en la consulta
class FakeErrorDeliveryRepository implements DeliveryRepository {
  @override
  Future<Result<List<DeliveryRequest>, Failure>> getPendingDeliveryRequests() async {
    return const FailureResult(
      ServerFailure('Error al cargar solicitudes pendientes'),
    );
  }

  @override
  Future<Result<DeliveryRequest, Failure>> createDeliveryRequest(
    DeliveryRequest request,
  ) =>
      throw UnimplementedError();

  @override
  Future<Result<DeliveryRequest, Failure>> getDeliveryRequestById(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> updateStatus(String id, String status) =>
      throw UnimplementedError();

  @override
  Future<Result<DriverStatus, Failure>> getDriverAvailability(String driverId) =>
      throw UnimplementedError();

  @override
  Future<Result<void, Failure>> setDriverAvailability(
    String driverId,
    DriverStatus status,
  ) =>
      throw UnimplementedError();
}

void main() {
  group('PendingDeliveryRequestsPage Widget Tests (Semana 3 - Entregable C)', () {
    // 1. Estado de carga: muestra CircularProgressIndicator mientras consulta
    testWidgets(
      '1. Muestra CircularProgressIndicator mientras carga las solicitudes',
      (tester) async {
        final repo = MockDeliveryRepository(
          latency: const Duration(milliseconds: 100),
        );
        final useCase = GetPendingDeliveryRequestsUseCase(repo);

        await tester.pumpWidget(
          MaterialApp(
            home: PendingDeliveryRequestsPage(
              getPendingRequestsUseCase: useCase,
            ),
          ),
        );

        // Verificar carga inmediatamente después de pumpWidget
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Avanzar el reloj virtual más allá de la latencia
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Ahora debe mostrar datos, no carga
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    // 2. Estado con datos: muestra solicitud req-001 precargada en MockDeliveryRepository
    testWidgets(
      '2. Muestra lista de solicitudes pendientes con datos correctos (req-001)',
      (tester) async {
        final repo = MockDeliveryRepository(latency: Duration.zero);
        final useCase = GetPendingDeliveryRequestsUseCase(repo);

        await tester.pumpWidget(
          MaterialApp(
            home: PendingDeliveryRequestsPage(
              getPendingRequestsUseCase: useCase,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Solicitud #req-001'), findsOneWidget);
        expect(find.text('Origen: Av. 4 de Noviembre, Manta'), findsOneWidget);
        expect(find.text('Destino: Calle 12 y Av. 24, Manta'), findsOneWidget);
        expect(find.text('3.5 km'), findsOneWidget);
        expect(find.text('\$3.25'), findsOneWidget);
        expect(find.text('Pendiente'), findsOneWidget);
      },
    );

    // 3. Estado vacío: muestra mensaje cuando no hay solicitudes en pendingOffer
    testWidgets(
      '3. Muestra mensaje cuando no hay solicitudes pendientes disponibles',
      (tester) async {
        final repo = MockDeliveryRepository(latency: Duration.zero);
        // Cancelamos la única solicitud inicial usando DeliveryStatus.cancelled para que no haya pendientes
        await repo.updateStatus('req-001', DeliveryStatus.cancelled.name);

        final useCase = GetPendingDeliveryRequestsUseCase(repo);

        await tester.pumpWidget(
          MaterialApp(
            home: PendingDeliveryRequestsPage(
              getPendingRequestsUseCase: useCase,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('No hay solicitudes pendientes disponibles'),
          findsOneWidget,
        );
      },
    );

    // 4. Estado de error: muestra mensaje de falla y botón de reintento
    testWidgets(
      '4. Muestra mensaje de error cuando el caso de uso devuelve falla',
      (tester) async {
        final repo = FakeErrorDeliveryRepository();
        final useCase = GetPendingDeliveryRequestsUseCase(repo);

        await tester.pumpWidget(
          MaterialApp(
            home: PendingDeliveryRequestsPage(
              getPendingRequestsUseCase: useCase,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Error al cargar solicitudes pendientes'),
          findsOneWidget,
        );
        expect(find.text('Reintentar'), findsOneWidget);
      },
    );
  });
}
