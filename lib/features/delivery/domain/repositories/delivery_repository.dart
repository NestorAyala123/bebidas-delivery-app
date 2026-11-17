import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/domain/entities/role.dart';
import '../entities/delivery_offer.dart';
import '../entities/delivery_request.dart';
import '../entities/delivery_status.dart';
import '../entities/driver.dart';
import '../entities/driver_status.dart';

abstract class DeliveryRepository {
  // ── Metodos existentes de Semana 1 (conservados sin cambios) ─────────────
  Future<Result<DeliveryRequest, Failure>> createDeliveryRequest(
    DeliveryRequest request,
  );
  Future<Result<DeliveryRequest, Failure>> getDeliveryRequestById(String id);
  Future<Result<void, Failure>> updateStatus(String id, String status);
  Future<Result<void, Failure>> updateDeliveryStatus(
    String id,
    DeliveryStatus status,
  );

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

  // ── Metodos de Semana 5 (Flujo de Negociación y Ofertas de Repartidores) ──

  /// Registra una nueva oferta o contraoferta para una solicitud de delivery.
  Future<Result<DeliveryOffer, Failure>> createDeliveryOffer(
    DeliveryOffer offer,
  );

  /// Consulta una oferta de delivery por su identificador.
  Future<Result<DeliveryOffer, Failure>> getDeliveryOfferById(String offerId);

  /// Consulta todas las ofertas asociadas a una solicitud de delivery.
  Future<Result<List<DeliveryOffer>, Failure>> getOffersByDeliveryRequestId(
    String deliveryRequestId,
  );

  /// Consulta las ofertas de un repartidor específico para una solicitud de delivery.
  Future<Result<List<DeliveryOffer>, Failure>> getOffersByDriverAndRequest({
    required String deliveryRequestId,
    required String driverId,
  });

  /// Ejecuta la asignación atómica de una oferta ganadora aceptada:
  /// 1. Verifica autorización del solicitante (cliente o tienda).
  /// 2. Valida que la solicitud esté en pendingOffer y sin repartidor asignado.
  /// 3. Valida que el repartidor continúe disponible.
  /// 4. Asigna el repartidor y fija la tarifa acordada en la solicitud (status: driverAssigned).
  /// 5. Actualiza el repartidor a DriverStatus.busy.
  /// 6. Marca la oferta ganadora como accepted.
  /// 7. Descarta en cascada las demás ofertas pendientes de esa solicitud.
  /// 8. Si la solicitud ya fue asignada por otra operación, no modifica ninguna entidad.
  Future<Result<DeliveryRequest, Failure>> acceptDeliveryOffer({
    required String offerId,
    required String requesterUserId,
    required Role requesterRole,
    DateTime? respondedAt,
  });

  /// Rechaza una oferta individual de una solicitud con autorización del cliente o tienda.
  Future<Result<DeliveryOffer, Failure>> rejectDeliveryOffer({
    required String offerId,
    required String requesterUserId,
    required Role requesterRole,
    DateTime? respondedAt,
  });

  // ── Metodos de la Semana 7 (Historial de Delivery) ────────────────────────

  /// Solicitudes de delivery asociadas a un cliente identificado por customerId.
  /// Incluye las negociaciones vigentes (pendingOffer) porque siguen activas
  /// para el cliente: su historial debe reflejar el estado actual de cada operación.
  Future<Result<List<DeliveryRequest>, Failure>> getDeliveryRequestsByCustomer(
    String customerId,
  );

  /// Solicitudes de delivery asociadas a un comercio identificado por storeId.
  /// Incluye negociaciones vigentes (pendingOffer) por las mismas razones de
  /// operación del propietario.
  Future<Result<List<DeliveryRequest>, Failure>> getDeliveryRequestsByStore(
    String storeId,
  );

  /// Operaciones de delivery en las que un repartidor participa: asignaciones
  /// vigentes (assignedDriverId) o negociaciones en las que presentó ofertas.
  /// Se usa para el historial del repartidor y cubre asignaciones, ofertas
  /// aceptadas y ofertas rechazadas/descartadas previas a una asignación.
  Future<Result<List<DeliveryRequest>, Failure>> getDeliveryRequestsByDriver(
    String driverId,
  );
}
