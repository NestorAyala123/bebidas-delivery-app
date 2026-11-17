import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../entities/delivery_request.dart';
import '../repositories/delivery_repository.dart';

/// Caso de uso para consultar el historial de delivery de un usuario autenticado.
///
/// Recupera las operaciones relevantes según el rol:
/// - Cliente: solicitudes asociadas a su customerId (incluye negociaciones activas).
/// - Comercio: solicitudes asociadas a su storeId (incluye negociaciones activas).
/// - Repartidor: operaciones en las que participó (asignaciones vigentes o
///   negociaciones en las que presentó ofertas).
///
/// Las operaciones se devuelven con el estado vigente, la tarifa de referencia,
/// la tarifa acordada (cuando existe), el repartidor asignado y las ofertas
/// asociadas (consultables vía `GetDeliveryOffersUseCase`).
/// 100% pure Dart, independiente de Flutter y Firebase.
class GetDeliveryHistoryUseCase {
  final DeliveryRepository repository;

  const GetDeliveryHistoryUseCase(this.repository);

  Future<Result<List<DeliveryRequest>, Failure>> call({
    required IdentityContract identity,
  }) async {
    if (!identity.isActive) {
      return const FailureResult(
        UnauthorizedFailure('El usuario autenticado se encuentra inactivo.'),
      );
    }

    final effectiveRole = identity.rbacRole;

    switch (effectiveRole) {
      case Role.client:
        return repository.getDeliveryRequestsByCustomer(identity.id);
      case Role.store:
        return repository.getDeliveryRequestsByStore(identity.id);
      case Role.driver:
        return repository.getDeliveryRequestsByDriver(identity.id);
      case Role.eventProvider:
        // El historial de delivery no aplica para proveedores de eventos.
        return const Success<List<DeliveryRequest>, Failure>(
          <DeliveryRequest>[],
        );
    }
  }
}
