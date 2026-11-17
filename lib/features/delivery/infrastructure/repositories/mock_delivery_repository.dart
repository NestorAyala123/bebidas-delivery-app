import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/domain/entities/role.dart';
import '../../domain/entities/delivery_offer.dart';
import '../../domain/entities/delivery_request.dart';
import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_status.dart';
import '../../domain/entities/offer_status.dart';
import '../../domain/repositories/delivery_repository.dart';

/// Implementación en memoria del repositorio de delivery con datos mock.
/// 100% pure Dart, independiente de Flutter y Firebase.
class MockDeliveryRepository implements DeliveryRepository {
  final Duration latency;
  final DateTime _seedTime;

  final Map<String, DriverStatus> _driverStatuses = {};
  final Map<String, Driver> _drivers = {};
  final Map<String, DeliveryRequest> _requests = {};
  final Map<String, DeliveryOffer> _offers = {};

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
    // Repartidor asociado a la cuenta demo de autenticación
    // (repartidor@demo.com -> seed-driver). Inicia desconectado para que el
    // usuario active su disponibilidad desde la pantalla de delivery.
    final demoDriver = Driver(
      id: 'seed-driver',
      name: 'Repartidor Demo',
      phoneNumber: '+59399000111',
      status: DriverStatus.offline,
      createdAt: _seedTime.subtract(const Duration(days: 5)),
    );

    _drivers[driver1.id] = driver1;
    _drivers[driver2.id] = driver2;
    _drivers[driver3.id] = driver3;
    _drivers[demoDriver.id] = demoDriver;

    _driverStatuses[driver1.id] = driver1.status;
    _driverStatuses[driver2.id] = driver2.status;
    _driverStatuses[driver3.id] = driver3.status;
    _driverStatuses[demoDriver.id] = demoDriver.status;

    // 1 solicitud de delivery de ejemplo con tarifa referencial calculada.
    // Los propietarios coinciden con las cuentas demo de autenticación para
    // poder recorrer el flujo completo de negociación en la aplicación.
    final initialRequest = DeliveryRequest(
      id: 'req-001',
      orderId: 'order-001',
      customerId: 'seed-client',
      storeId: 'seed-store',
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

  /// Permite registrar una oferta en el mock para escenarios de prueba.
  void registerOffer(DeliveryOffer offer) {
    _offers[offer.id] = offer;
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
  Future<Result<void, Failure>> updateStatus(String id, String status) async {
    await _simulateLatency();
    final request = _requests[id];
    if (request == null) {
      return FailureResult(
        NotFoundFailure('Solicitud no encontrada con id: $id'),
      );
    }

    final normalized = status.trim().toLowerCase();
    final newStatus = DeliveryStatus.values.cast<DeliveryStatus?>().firstWhere(
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
    if (newStatus == DeliveryStatus.cancelled) {
      final now = DateTime.now();
      for (final offer
          in _offers.values
              .where(
                (o) =>
                    o.deliveryRequestId == id &&
                    o.status == OfferStatus.pending,
              )
              .toList()) {
        _offers[offer.id] = offer.discard(respondedAt: now);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> updateDeliveryStatus(
    String id,
    DeliveryStatus status,
  ) async {
    await _simulateLatency();
    final request = _requests[id];
    if (request == null) {
      return FailureResult(
        NotFoundFailure('Solicitud no encontrada con id: $id'),
      );
    }

    _requests[id] = request.copyWithStatus(status);
    if (status == DeliveryStatus.cancelled) {
      final now = DateTime.now();
      for (final offer
          in _offers.values
              .where(
                (o) =>
                    o.deliveryRequestId == id &&
                    o.status == OfferStatus.pending,
              )
              .toList()) {
        _offers[offer.id] = offer.discard(respondedAt: now);
      }
    }
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
  Future<Result<List<DeliveryRequest>, Failure>>
  getPendingDeliveryRequests() async {
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

  // ── Implementación de Semana 5 (Negociación de Ofertas) ──────────────────

  @override
  Future<Result<DeliveryOffer, Failure>> createDeliveryOffer(
    DeliveryOffer offer,
  ) async {
    await _simulateLatency();

    // 1. Validar que la solicitud exista y esté en pendingOffer
    final request = _requests[offer.deliveryRequestId];
    if (request == null) {
      return FailureResult(
        NotFoundFailure(
          'Solicitud no encontrada con id: ${offer.deliveryRequestId}',
        ),
      );
    }
    if (request.status == DeliveryStatus.cancelled) {
      return const FailureResult(
        BusinessRuleFailure(
          'La solicitud ha sido cancelada y no admite nuevas ofertas.',
        ),
      );
    }
    if (request.status != DeliveryStatus.pendingOffer ||
        request.assignedDriverId != null) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-NEG-01: Solo se puede ofertar a solicitudes pendientes sin asignación previa.',
        ),
      );
    }

    // 2. Validar que el repartidor exista y esté disponible
    final driver = _drivers[offer.driverId];
    if (driver == null) {
      return FailureResult(
        NotFoundFailure('Repartidor no encontrado con id: ${offer.driverId}'),
      );
    }
    final currentStatus = _driverStatuses[offer.driverId] ?? driver.status;
    if (driver.status != DriverStatus.available ||
        currentStatus != DriverStatus.available) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-NEG-02: El repartidor debe estar en estado disponible para ofertar.',
        ),
      );
    }

    // 3. Validar límite de intentos del repartidor para esta solicitud
    final driverOffers = _offers.values
        .where(
          (o) =>
              o.deliveryRequestId == offer.deliveryRequestId &&
              o.driverId == offer.driverId,
        )
        .toList();

    if (driverOffers.any((o) => o.status == OfferStatus.pending)) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-NEG-04: El repartidor ya tiene una oferta pendiente para esta solicitud.',
        ),
      );
    }

    if (driverOffers.length >= 2) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-NEG-04: El repartidor ha alcanzado el límite máximo de 2 ofertas para esta solicitud.',
        ),
      );
    }

    if (driverOffers.length == 1 &&
        driverOffers.first.status != OfferStatus.rejected) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-NEG-04: La segunda oferta solo se permite si la primera fue rechazada.',
        ),
      );
    }

    _offers[offer.id] = offer;
    return Success(offer);
  }

  @override
  Future<Result<DeliveryOffer, Failure>> getDeliveryOfferById(
    String offerId,
  ) async {
    await _simulateLatency();
    final offer = _offers[offerId];
    if (offer == null) {
      return FailureResult(
        NotFoundFailure('Oferta no encontrada con id: $offerId'),
      );
    }
    return Success(offer);
  }

  @override
  Future<Result<List<DeliveryOffer>, Failure>> getOffersByDeliveryRequestId(
    String deliveryRequestId,
  ) async {
    await _simulateLatency();
    final offers = _offers.values
        .where((o) => o.deliveryRequestId == deliveryRequestId)
        .toList();
    return Success(offers);
  }

  @override
  Future<Result<List<DeliveryOffer>, Failure>> getOffersByDriverAndRequest({
    required String deliveryRequestId,
    required String driverId,
  }) async {
    await _simulateLatency();
    final offers = _offers.values
        .where(
          (o) =>
              o.deliveryRequestId == deliveryRequestId &&
              o.driverId == driverId,
        )
        .toList();
    return Success(offers);
  }

  @override
  Future<Result<DeliveryRequest, Failure>> acceptDeliveryOffer({
    required String offerId,
    required String requesterUserId,
    required Role requesterRole,
    DateTime? respondedAt,
  }) async {
    await _simulateLatency();

    // 1. Autorización por rol
    if (requesterRole != Role.client && requesterRole != Role.store) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-NEG-05: Solo clientes o tiendas pueden aceptar ofertas.',
        ),
      );
    }

    // 2. Existencia de oferta y estado pendiente
    final offer = _offers[offerId];
    if (offer == null) {
      return FailureResult(
        NotFoundFailure('Oferta no encontrada con id: $offerId'),
      );
    }
    if (offer.status != OfferStatus.pending) {
      return const FailureResult(
        BusinessRuleFailure(
          'Solo se pueden aceptar ofertas en estado pendiente.',
        ),
      );
    }

    // 3. Existencia de solicitud y correspondencia estricta de autorización
    final request = _requests[offer.deliveryRequestId];
    if (request == null) {
      return FailureResult(
        NotFoundFailure(
          'Solicitud no encontrada con id: ${offer.deliveryRequestId}',
        ),
      );
    }

    final isAuthorized = switch (requesterRole) {
      Role.client => requesterUserId == request.customerId,
      Role.store => requesterUserId == request.storeId,
      _ => false,
    };

    if (!isAuthorized) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-NEG-05: El usuario autenticado no está autorizado para gestionar esta solicitud.',
        ),
      );
    }

    // 4. Bloque síncrono atómico de asignación (garantizado en un único Isolate de Dart):
    // Precondición 1: Solicitud aún pendiente y sin asignar
    if (request.status == DeliveryStatus.cancelled) {
      return const FailureResult(
        BusinessRuleFailure(
          'La solicitud ha sido cancelada y no admite nuevas asignaciones.',
        ),
      );
    }
    if (request.status != DeliveryStatus.pendingOffer ||
        request.assignedDriverId != null) {
      // Carrera de concurrencia: otra operación ya asignó la solicitud.
      // NO se modifica ninguna entidad ni se descartan ofertas adicionales.
      return const FailureResult(
        BusinessRuleFailure(
          'La solicitud ya cuenta con un repartidor asignado.',
        ),
      );
    }

    // Precondición 2: Disponibilidad del repartidor al momento de aceptar
    final driver = _drivers[offer.driverId];
    final currentDriverStatus =
        _driverStatuses[offer.driverId] ?? driver?.status;
    if (driver == null ||
        driver.status != DriverStatus.available ||
        currentDriverStatus != DriverStatus.available) {
      // Repartidor ya no disponible: se descarta esta oferta pero la solicitud permanece en pendingOffer.
      _offers[offer.id] = offer.discard(respondedAt: respondedAt);
      return const FailureResult(
        BusinessRuleFailure(
          'RN-NEG-06: El repartidor seleccionado ya no se encuentra disponible.',
        ),
      );
    }

    final effectiveResponseTime = respondedAt ?? DateTime.now();

    try {
      // Mutación atómica en memoria (All-or-Nothing):
      // Paso 1: Preparación y validación de todas las entidades de dominio inmutables
      final updatedRequest = request.assignDriver(
        driverId: driver.id,
        agreedFareInCents: offer.offeredFareInCents,
      );
      final updatedDriver = driver.copyWithStatus(DriverStatus.busy);
      final acceptedWinningOffer = offer.accept(
        respondedAt: effectiveResponseTime,
      );
      final discardedOtherOffers = _offers.values
          .where(
            (o) =>
                o.deliveryRequestId == request.id &&
                o.id != offer.id &&
                o.status == OfferStatus.pending,
          )
          .map((o) => o.discard(respondedAt: effectiveResponseTime))
          .toList();

      // Paso 2: Commit atómico sincronizado: se mutan las colecciones únicamente
      // si todas las entidades fueron creadas y validadas exitosamente sin excepciones.
      _requests[request.id] = updatedRequest;
      _drivers[driver.id] = updatedDriver;
      _driverStatuses[driver.id] = DriverStatus.busy;
      _offers[offer.id] = acceptedWinningOffer;
      for (final otherOffer in discardedOtherOffers) {
        _offers[otherOffer.id] = otherOffer;
      }

      return Success(updatedRequest);
    } catch (e) {
      return FailureResult(
        ServerFailure('Error técnico durante la asignación atómica: $e'),
      );
    }
  }

  @override
  Future<Result<DeliveryOffer, Failure>> rejectDeliveryOffer({
    required String offerId,
    required String requesterUserId,
    required Role requesterRole,
    DateTime? respondedAt,
  }) async {
    await _simulateLatency();

    // 1. Autorización por rol
    if (requesterRole != Role.client && requesterRole != Role.store) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-NEG-05: Solo clientes o tiendas pueden rechazar ofertas.',
        ),
      );
    }

    // 2. Existencia de oferta y estado pendiente
    final offer = _offers[offerId];
    if (offer == null) {
      return FailureResult(
        NotFoundFailure('Oferta no encontrada con id: $offerId'),
      );
    }
    if (offer.status != OfferStatus.pending) {
      return const FailureResult(
        BusinessRuleFailure(
          'Solo se pueden rechazar ofertas en estado pendiente.',
        ),
      );
    }

    // 3. Existencia de solicitud y correspondencia estricta de autorización
    final request = _requests[offer.deliveryRequestId];
    if (request == null) {
      return FailureResult(
        NotFoundFailure(
          'Solicitud no encontrada con id: ${offer.deliveryRequestId}',
        ),
      );
    }

    final isAuthorized = switch (requesterRole) {
      Role.client => requesterUserId == request.customerId,
      Role.store => requesterUserId == request.storeId,
      _ => false,
    };

    if (!isAuthorized) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-NEG-05: El usuario autenticado no está autorizado para gestionar esta solicitud.',
        ),
      );
    }

    if (request.status == DeliveryStatus.cancelled) {
      return const FailureResult(
        BusinessRuleFailure('La solicitud ha sido cancelada.'),
      );
    }

    // 4. Rechazar oferta: la solicitud permanece intacta en pendingOffer
    try {
      final rejectedOffer = offer.reject(
        respondedAt: respondedAt ?? DateTime.now(),
      );
      _offers[offer.id] = rejectedOffer;
      return Success(rejectedOffer);
    } catch (e) {
      return FailureResult(
        ServerFailure('Error técnico al rechazar la oferta: $e'),
      );
    }
  }

  @override
  Future<Result<List<DeliveryRequest>, Failure>> getDeliveryRequestsByCustomer(
    String customerId,
  ) async {
    await _simulateLatency();
    final requests = _requests.values
        .where((r) => r.customerId == customerId)
        .toList();
    return Success(requests);
  }

  @override
  Future<Result<List<DeliveryRequest>, Failure>> getDeliveryRequestsByStore(
    String storeId,
  ) async {
    await _simulateLatency();
    final requests = _requests.values
        .where((r) => r.storeId == storeId)
        .toList();
    return Success(requests);
  }

  @override
  Future<Result<List<DeliveryRequest>, Failure>> getDeliveryRequestsByDriver(
    String driverId,
  ) async {
    await _simulateLatency();
    final requests = <DeliveryRequest>[];
    for (final request in _requests.values) {
      final assignedToDriver = request.assignedDriverId == driverId;
      final driverMadeOffer = _offers.values.any(
        (o) => o.deliveryRequestId == request.id && o.driverId == driverId,
      );
      if (assignedToDriver || driverMadeOffer) {
        requests.add(request);
      }
    }
    return Success(requests);
  }
}
