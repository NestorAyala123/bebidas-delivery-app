import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../ratings/domain/entities/rating.dart';
import '../../../ratings/domain/repositories/rating_repository.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../repositories/delivery_repository.dart';

/// Caso de uso para consultar la calificación registrada de una entrega.
///
/// Permite consultar la calificación de una solicitud de delivery y, con el
/// semántica de retorno nulo, también consultar si la entrega ya fue calificada
/// (`dataOrNull != null`).
/// 100% pure Dart, independiente de Flutter y Firebase.
class GetDeliveryRatingUseCase {
  final DeliveryRepository deliveryRepository;
  final RatingRepository ratingRepository;

  const GetDeliveryRatingUseCase({
    required this.deliveryRepository,
    required this.ratingRepository,
  });

  Future<Result<Rating?, Failure>> call({
    required String deliveryRequestId,
    IdentityContract? requesterIdentity,
  }) async {
    // 1. Autorización: la identidad debe existir y estar activa.
    if (requesterIdentity == null) {
      return const FailureResult(
        UnauthorizedFailure(
          'Se requiere la identidad autenticada para consultar la calificación de la entrega.',
        ),
      );
    }

    if (!requesterIdentity.isActive) {
      return const FailureResult(
        UnauthorizedFailure('El usuario autenticado se encuentra inactivo.'),
      );
    }

    // 2. Validar que la entrega exista.
    final requestResult = await deliveryRepository.getDeliveryRequestById(
      deliveryRequestId,
    );
    if (requestResult.isFailure) {
      return FailureResult(requestResult.failureOrNull!);
    }

    final request = requestResult.dataOrNull!;

    // 3. Autorización: cliente propietario o repartidor asignado.
    final isOwner =
        requesterIdentity.rbacRole == Role.client &&
        requesterIdentity.id == request.customerId;
    final isAssignedDriver =
        requesterIdentity.rbacRole == Role.driver &&
        request.assignedDriverId != null &&
        requesterIdentity.id == request.assignedDriverId;

    if (!isOwner && !isAssignedDriver) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-RATING: No está autorizado para consultar la calificación de esta entrega.',
        ),
      );
    }

    // 4. Consultar la calificación (null cuando no existe).
    return ratingRepository.getRatingByDeliveryRequestId(deliveryRequestId);
  }
}
