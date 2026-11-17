import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/rating.dart';

abstract class RatingRepository {
  Future<Result<void, Failure>> submitRating(Rating rating);

  /// Consulta las calificaciones recibidas por un usuario (repartidor).
  Future<Result<List<Rating>, Failure>> getRatingsForUser(String userId);

  /// Consulta la calificación registrada para una solicitud de delivery.
  /// Devuelve `null` cuando la entrega aún no ha sido calificada.
  Future<Result<Rating?, Failure>> getRatingByDeliveryRequestId(
    String deliveryRequestId,
  );
}
