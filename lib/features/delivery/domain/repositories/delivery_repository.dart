import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/delivery_request.dart';
import '../entities/driver.dart';
import '../entities/driver_status.dart';

abstract class DeliveryRepository {
  // ── Metodos existentes de Semana 1 (conservados sin cambios) ─────────────
  Future<Result<DeliveryRequest, Failure>> createDeliveryRequest(
    DeliveryRequest request,
  );
  Future<Result<DeliveryRequest, Failure>> getDeliveryRequestById(String id);
  // TODO(week5): tipar como DeliveryStatus en lugar de String
  Future<Result<void, Failure>> updateStatus(String id, String status);

  // ── Metodos de Semana 2 (Disponibilidad de Repartidor) ───────────────────
  Future<Result<DriverStatus, Failure>> getDriverAvailability(String driverId);
  Future<Result<void, Failure>> setDriverAvailability(
    String driverId,
    DriverStatus status,
  );

  // ── Metodos de Semana 3 (Solicitudes Pendientes para Repartidor) ───────────
  Future<Result<List<DeliveryRequest>, Failure>> getPendingDeliveryRequests();

  // ── Metodos de Semana 4 (Prevención de Duplicados y Repartidores Registrados)
  /// Obtiene la solicitud activa asociada a un pedido si existe.
  /// Se consideran activas aquellas cuyo estado no sea terminal (delivered o cancelled).
  Future<Result<DeliveryRequest?, Failure>> getActiveDeliveryRequestByOrderId(
    String orderId,
  );

  /// Consulta la lista de todos los repartidores registrados en la plataforma.
  Future<Result<List<Driver>, Failure>> getRegisteredDrivers();
}
