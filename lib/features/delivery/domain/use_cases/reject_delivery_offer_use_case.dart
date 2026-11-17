import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../entities/delivery_offer.dart';
import '../repositories/delivery_repository.dart';

/// Caso de uso para rechazar una oferta o contraoferta de repartidor.
/// Aplica RN-NEG-05: Validación estricta de autorización vinculada al contexto
/// de identidad autenticada (Role.client correspondiente a customerId, o
/// Role.store correspondiente a storeId).
/// 100% pure Dart, independiente de Flutter y Firebase.
class RejectDeliveryOfferUseCase {
  final DeliveryRepository repository;

  const RejectDeliveryOfferUseCase(this.repository);

  Future<Result<DeliveryOffer, Failure>> call({
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
        UnauthorizedFailure('El usuario autenticado se encuentra inactivo.'),
      );
    }

    final effectiveRole = requesterIdentity.rbacRole;
    if (effectiveRole != Role.client && effectiveRole != Role.store) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-NEG-05: Solo clientes o tiendas pueden rechazar ofertas.',
        ),
      );
    }

    return repository.rejectDeliveryOffer(
      offerId: offerId,
      requesterUserId: requesterIdentity.id,
      requesterRole: effectiveRole,
      respondedAt: respondedAt,
    );
  }
}
