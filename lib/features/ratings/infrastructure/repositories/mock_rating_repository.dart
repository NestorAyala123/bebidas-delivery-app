import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/rating_repository.dart';

/// Implementación en memoria del repositorio de calificaciones de delivery.
/// 100% pure Dart, independiente de Flutter y Firebase.
/// Permite una futura adaptación a Firestore manteniendo la misma interfaz.
class MockRatingRepository implements RatingRepository {
  final Duration latency;

  final Map<String, Rating> _ratingsByDeliveryRequestId = {};

  MockRatingRepository({this.latency = const Duration(milliseconds: 0)});

  Future<void> _simulateLatency() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
  }

  @override
  Future<Result<void, Failure>> submitRating(Rating rating) async {
    await _simulateLatency();

    // Regla de dominio/application: una sola calificación por solicitud.
    final existing = _ratingsByDeliveryRequestId[rating.deliveryRequestId];
    if (existing != null) {
      return const FailureResult(
        BusinessRuleFailure('RN-RATING: La solicitud ya fue calificada.'),
      );
    }

    _ratingsByDeliveryRequestId[rating.deliveryRequestId] = rating;
    return const Success<void, Failure>(null);
  }

  @override
  Future<Result<List<Rating>, Failure>> getRatingsForUser(String userId) async {
    await _simulateLatency();

    final ratings = _ratingsByDeliveryRequestId.values
        .where((r) => r.driverId == userId)
        .toList();
    return Success<List<Rating>, Failure>(ratings);
  }

  @override
  Future<Result<Rating?, Failure>> getRatingByDeliveryRequestId(
    String deliveryRequestId,
  ) async {
    await _simulateLatency();
    final rating = _ratingsByDeliveryRequestId[deliveryRequestId];
    return Success<Rating?, Failure>(rating);
  }
}
