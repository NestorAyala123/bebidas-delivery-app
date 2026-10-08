import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/delivery_request.dart';
import '../entities/driver_status.dart';

abstract class DeliveryRepository {
  // ── Métodos existentes de Semana 1 (conservados sin cambios) ─────────────
  Future<Result<DeliveryRequest, Failure>> createDeliveryRequest(
    DeliveryRequest request,
  );
  Future<Result<DeliveryRequest, Failure>> getDeliveryRequestById(String id);
  // TODO(week5): tipar como DeliveryStatus en lugar de String
  Future<Result<void, Failure>> updateStatus(String id, String status);

  // ── Métodos de Semana 2 (Disponibilidad de Repartidor) ───────────────────
  Future<Result<DriverStatus, Failure>> getDriverAvailability(String driverId);
  Future<Result<void, Failure>> setDriverAvailability(
    String driverId,
    DriverStatus status,
  );
}
