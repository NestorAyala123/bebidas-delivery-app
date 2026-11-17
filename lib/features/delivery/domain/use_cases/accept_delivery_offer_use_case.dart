import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../entities/delivery_request.dart';
import '../repositories/delivery_repository.dart';

/// Caso de uso para aceptar una oferta de delivery y ejecutar la asignación atómica.
/// Aplica:
/// - RN-NEG-01: Solicitud pendiente sin asignación previa.
/// - RN-NEG-05: Autorización vinculada a la identidad autenticada (Role.client o Role.store).
/// - RN-NEG-06: Verificación de disponibilidad del repartidor al momento de aceptar.
/// - RN-NEG-07: Asignación atómica (solicitud -> driverAssigned, repartidor -> busy, oferta -> accepted).
/// - RN-NEG-08: Cierre en cascada de ofertas rivales (pending -> discarded).
/// - Prevención de carreras de concurrencia: si la solicitud ya fue asignada, no modifica ninguna entidad.
/// 100% pure Dart, independiente de Flutter y Firebase.
class AcceptDeliveryOfferUseCase {
  final DeliveryRepository repository;

  const AcceptDeliveryOfferUseCase(this.repository);

  Future<Result<DeliveryRequest, Failure>> call({
    required String offerId,
    IdentityContract? requesterIdentity,
    DateTime? respondedAt,
  }) async {
    if (requesterIdentity == null) {
      return const FailureResult(
        UnauthorizedFailure(
          'Se requiere la identidad autenticada para responder a ofertas.',
        ),
      );
    }

    if (!requesterIdentity.isActive) {
      return const FailureResult(
        UnauthorizedFailure(
          'El usuario autenticado se encuentra inactivo.',
        ),
      );
    }

    final effectiveRole = requesterIdentity.rbacRole;
    if (effectiveRole != Role.client && effectiveRole != Role.store) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-NEG-05: Solo clientes o tiendas pueden aceptar ofertas.',
        ),
      );
    }

    return repository.acceptDeliveryOffer(
      offerId: offerId,
      requesterUserId: requesterIdentity.id,
      requesterRole: effectiveRole,
      respondedAt: respondedAt,
    );
  }
}
