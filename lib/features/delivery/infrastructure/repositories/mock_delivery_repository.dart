import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/delivery_request.dart';
import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/driver_status.dart';
import '../../domain/repositories/delivery_repository.dart';

/// Implementación en memoria del repositorio de delivery con datos mock.
/// 100% pure Dart, independiente de Flutter y Firebase.
class MockDeliveryRepository implements DeliveryRepository {
  final Duration latency;
  final DateTime _seedTime;

  final Map<String, DriverStatus> _driverStatuses = {};
  final Map<String, DeliveryRequest> _requests = {};

  MockDeliveryRepository({
    this.latency = const Duration(milliseconds: 100),
    DateTime? seedTime,
  }) : _seedTime = seedTime ?? DateTime.now() {
    _initMockData();
  }

  void _initMockData() {
    // 2 repartidores de prueba con distinta disponibilidad
    _driverStatuses['driver-1'] = DriverStatus.available;
    _driverStatuses['driver-2'] = DriverStatus.busy;

    // 1 solicitud de delivery de ejemplo con tarifa referencial calculada
    final initialRequest = DeliveryRequest(
      id: 'req-001',
      orderId: 'order-101',
      customerId: 'customer-001',
      storeId: 'store-001',
      originAddress: 'Av. 4 de Noviembre, Manta',
      destinationAddress: 'Calle 12 y Av. 24, Manta',
      distanceInKm: 3.5,
      referenceFare: 3.25, // 1.50 base + (3.5 * 0.50)
      isOrderConfirmedByStore: true,
      status: DeliveryStatus.pendingOffer,
      createdAt: _seedTime.subtract(const Duration(minutes: 15)),
    );
    _requests[initialRequest.id] = initialRequest;
  }

  Future<void> _simulateLatency() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
  }

  @override
  Future<Result<DeliveryRequest, Failure>> createDeliveryRequest(
    DeliveryRequest request,
  ) async {
    await _simulateLatency();
    _requests[request.id] = request;
    return Success(request);
  }

  @override
  Future<Result<DeliveryRequest, Failure>> getDeliveryRequestById(
    String id,
  ) async {
    await _simulateLatency();
    final request = _requests[id];
    if (request == null) {
      return FailureResult(
        NotFoundFailure('Solicitud no encontrada con id: $id'),
      );
    }
    return Success(request);
  }

  @override
  Future<Result<void, Failure>> updateStatus(
    String id,
    String status,
  ) async {
    await _simulateLatency();
    final request = _requests[id];
    if (request == null) {
      return FailureResult(
        NotFoundFailure('Solicitud no encontrada con id: $id'),
      );
    }

    final normalized = status.trim().toLowerCase();
    final newStatus = DeliveryStatus.values
        .cast<DeliveryStatus?>()
        .firstWhere(
          (s) => s?.name.toLowerCase() == normalized,
          orElse: () => null,
        );

    if (newStatus == null) {
      return FailureResult(
        ValidationFailure(
          'Estado no válido: $status. Valores permitidos: ${DeliveryStatus.values.map((s) => s.name).join(', ')}',
        ),
      );
    }

    // TODO(week5): evaluar si debe usar request.transitionTo() con validación RN05
    // en lugar de copyWithStatus(). Por ahora el mock no valida transiciones.
    _requests[id] = request.copyWithStatus(newStatus);
    return const Success(null);
  }

  @override
  Future<Result<DriverStatus, Failure>> getDriverAvailability(
    String driverId,
  ) async {
    await _simulateLatency();
    final status = _driverStatuses[driverId];
    if (status == null) {
      return FailureResult(
        NotFoundFailure('Repartidor no encontrado con id: $driverId'),
      );
    }
    return Success(status);
  }

  @override
  Future<Result<void, Failure>> setDriverAvailability(
    String driverId,
    DriverStatus status,
  ) async {
    await _simulateLatency();
    _driverStatuses[driverId] = status;
    return const Success(null);
  }
}
