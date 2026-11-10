import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/delivery_request.dart';
import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_status.dart';
import '../../domain/repositories/delivery_repository.dart';

/// Implementación en memoria del repositorio de delivery con datos mock.
/// 100% pure Dart, independiente de Flutter y Firebase.
class MockDeliveryRepository implements DeliveryRepository {
  final Duration latency;
  final DateTime _seedTime;

  final Map<String, DriverStatus> _driverStatuses = {};
  final Map<String, Driver> _drivers = {};
  final Map<String, DeliveryRequest> _requests = {};

  MockDeliveryRepository({
    this.latency = const Duration(milliseconds: 100),
    DateTime? seedTime,
  }) : _seedTime = seedTime ?? DateTime.now() {
    _initMockData();
  }

  void _initMockData() {
    // Repartidores registrados de prueba con distinta disponibilidad
    final driver1 = Driver(
      id: 'driver-1',
      name: 'Carlos Mendoza',
      phoneNumber: '+59399111222',
      status: DriverStatus.available,
      createdAt: _seedTime.subtract(const Duration(days: 30)),
    );
    final driver2 = Driver(
      id: 'driver-2',
      name: 'Ana Gómez',
      phoneNumber: '+59399222333',
      status: DriverStatus.busy,
      createdAt: _seedTime.subtract(const Duration(days: 20)),
    );
    final driver3 = Driver(
      id: 'driver-3',
      name: 'Luis Pérez',
      phoneNumber: '+59399333444',
      status: DriverStatus.offline,
      createdAt: _seedTime.subtract(const Duration(days: 10)),
    );

    _drivers[driver1.id] = driver1;
    _drivers[driver2.id] = driver2;
    _drivers[driver3.id] = driver3;

    _driverStatuses[driver1.id] = driver1.status;
    _driverStatuses[driver2.id] = driver2.status;
    _driverStatuses[driver3.id] = driver3.status;

    // 1 solicitud de delivery de ejemplo con tarifa referencial calculada
    final initialRequest = DeliveryRequest(
      id: 'req-001',
      orderId: 'order-001',
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

  /// Permite registrar o actualizar un repartidor en el mock para escenarios de prueba.
  void registerDriver(Driver driver) {
    _drivers[driver.id] = driver;
    _driverStatuses[driver.id] = driver.status;
  }

  @override
  Future<Result<DeliveryRequest, Failure>> createDeliveryRequest(
    DeliveryRequest request,
  ) async {
    await _simulateLatency();

    // Protección adicional en la persistencia mock contra duplicados activos
    final hasActiveDuplicate = _requests.values.any(
      (r) =>
          r.id != request.id &&
          r.orderId == request.orderId &&
          r.status.isActive,
    );
    if (hasActiveDuplicate) {
      return FailureResult(
        BusinessRuleFailure(
          'Ya existe una solicitud de delivery activa para el pedido ${request.orderId}.',
        ),
      );
    }

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
  Future<Result<DeliveryRequest?, Failure>> getActiveDeliveryRequestByOrderId(
    String orderId,
  ) async {
    await _simulateLatency();
    final activeRequest = _requests.values.cast<DeliveryRequest?>().firstWhere(
          (r) => r?.orderId == orderId && r!.status.isActive,
          orElse: () => null,
        );
    return Success(activeRequest);
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
    final driver = _drivers[driverId];
    if (driver != null) {
      _drivers[driverId] = driver.copyWithStatus(status);
    }
    return const Success(null);
  }

  @override
  Future<Result<List<DeliveryRequest>, Failure>> getPendingDeliveryRequests() async {
    await _simulateLatency();
    final pending = _requests.values
        .where((r) => r.status == DeliveryStatus.pendingOffer)
        .toList();
    return Success(pending);
  }

  @override
  Future<Result<List<Driver>, Failure>> getRegisteredDrivers() async {
    await _simulateLatency();
    return Success(List.unmodifiable(_drivers.values));
  }
}
