import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../ratings/domain/entities/rating.dart';
import '../../../ratings/domain/repositories/rating_repository.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../entities/delivery_status.dart';
import '../repositories/delivery_repository.dart';

/// Caso de uso para registrar la calificación de una entrega completada.
///
/// Aplica las reglas de negocio de calificación (RN-RATING):
/// - RN-RATING-01: Solo el cliente propietario de la solicitud puede calificar.
/// - RN-RATING-02: Solo entregas en estado `delivered` pueden calificarse.
/// - RN-RATING-03: La calificación debe corresponder al repartidor asignado
///   (`assignedDriverId`) de la entrega.
/// - RN-RATING-04: Una sola calificación por solicitud de delivery.
/// - RN-RATING-05: Puntaje entero entre 1 y 5; comentario opcional de máximo
///   500 caracteres.
/// - RN-RATING-06: Un usuario no puede calificar su propia entrega.
///
/// La validación definitiva de autorización y estado vive aquí, en la capa
/// de aplicación, no en la interfaz.
class RegisterDeliveryRatingUseCase {
  final DeliveryRepository deliveryRepository;
  final RatingRepository ratingRepository;
  final String Function()? idGenerator;

  const RegisterDeliveryRatingUseCase({
    required this.deliveryRepository,
    required this.ratingRepository,
    this.idGenerator,
  });

  Future<Result<Rating, Failure>> call({
    required String deliveryRequestId,
    required int score,
    String? comment,
    IdentityContract? customerIdentity,
    DateTime? createdAt,
  }) async {
    // 1. Autorización: solo clientes autenticados y activos pueden calificar.
    if (customerIdentity == null) {
      return const FailureResult(
        UnauthorizedFailure(
          'Se requiere la identidad autenticada del cliente para calificar la entrega.',
        ),
      );
    }

    if (!customerIdentity.isActive) {
      return const FailureResult(
        UnauthorizedFailure('El usuario autenticado se encuentra inactivo.'),
      );
    }

    if (customerIdentity.rbacRole != Role.client) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-RATING: Solo usuarios con rol de cliente pueden calificar entregas.',
        ),
      );
    }

    // 2. Validaciones de la calificación.
    if (score < Rating.minScore || score > Rating.maxScore) {
      return const FailureResult(
        ValidationFailure(
          'RN-RATING: La calificación debe ser un entero entre 1 y 5 estrellas.',
        ),
      );
    }

    String? normalizedComment;
    if (comment != null) {
      final trimmed = comment.trim();
      if (trimmed.length > Rating.maxCommentLength) {
        return const FailureResult(
          ValidationFailure(
            'RN-RATING: El comentario no puede exceder los 500 caracteres.',
          ),
        );
      }
      normalizedComment = trimmed.isEmpty ? null : trimmed;
    }

    // 3. Validar la entrega: debe existir y estar completada.
    final requestResult = await deliveryRepository.getDeliveryRequestById(
      deliveryRequestId,
    );
    if (requestResult.isFailure) {
      return FailureResult(requestResult.failureOrNull!);
    }

    final request = requestResult.dataOrNull!;

    if (request.status != DeliveryStatus.delivered) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-RATING: Solo se puede calificar una entrega en estado delivered.',
        ),
      );
    }

    if (request.assignedDriverId == null) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-RATING: La entrega no tiene un repartidor asignado y no puede ser calificada.',
        ),
      );
    }

    // 4. Autorización: el cliente autenticado debe ser el propietario de la solicitud.
    if (customerIdentity.id != request.customerId) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-RATING: Solo el cliente propietario de la solicitud puede calificar.',
        ),
      );
    }

    // RN-RATING-06: Un usuario no puede calificar su propia entrega.
    if (customerIdentity.id == request.assignedDriverId ||
        request.customerId == request.assignedDriverId) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-RATING: Un usuario no puede calificar su propia entrega.',
        ),
      );
    }

    // 5. Evitar calificaciones duplicadas.
    final existingResult = await ratingRepository.getRatingByDeliveryRequestId(
      deliveryRequestId,
    );
    if (existingResult.isFailure) {
      return FailureResult(existingResult.failureOrNull!);
    }

    if (existingResult.dataOrNull != null) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-RATING: La solicitud de delivery ya fue calificada.',
        ),
      );
    }

    // 6. Registrar la calificación.
    final rating = Rating(
      id:
          idGenerator?.call() ??
          'rating-$deliveryRequestId-${DateTime.now().microsecondsSinceEpoch}',
      deliveryRequestId: deliveryRequestId,
      customerId: request.customerId,
      driverId: request.assignedDriverId!,
      score: score,
      comment: normalizedComment,
      createdAt: createdAt ?? DateTime.now(),
    );

    final submission = await ratingRepository.submitRating(rating);
    if (submission.isFailure) {
      return FailureResult(submission.failureOrNull!);
    }

    return Success(rating);
  }
}
