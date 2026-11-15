import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../../domain/entities/delivery_negotiation_event.dart';
import '../../domain/entities/delivery_rating.dart';
import '../../domain/repositories/delivery_negotiation_repository.dart';

/// Registra la calificación del cliente al repartidor tras la entrega.
class CalificarEntregaUseCase {
  final DeliveryNegotiationRepository _repository;

  const CalificarEntregaUseCase(this._repository);

  Future<Result<DeliveryNegotiation, Failure>> call({
    required String negotiationId,
    required int stars,
    String comment = '',
  }) async {
    if (stars < 1 || stars > 5) {
      return const FailureResult(
        ValidationFailure('La calificación debe estar entre 1 y 5 estrellas'),
      );
    }

    final loaded = await _repository.getNegotiation(negotiationId);
    final failure = loaded.failureOrNull;
    if (failure != null) return FailureResult(failure);

    final negotiation = loaded.dataOrNull!;
    if (!negotiation.canRate) {
      return const FailureResult(
        BusinessRuleFailure(
          'Solo se puede calificar una entrega completada y sin calificación previa',
        ),
      );
    }

    final driverId =
        negotiation.acceptedOffer?.driverId ??
        negotiation.request.assignedDriverId ??
        '';
    if (driverId.isEmpty) {
      return const FailureResult(
        BusinessRuleFailure('La entrega no tiene un repartidor asignado'),
      );
    }

    final now = DateTime.now();
    final rating = DeliveryRating(
      stars: stars,
      comment: comment.trim(),
      driverId: driverId,
      createdAt: now,
    );
    final event = DeliveryNegotiationEvent(
      id: 'evt-${now.microsecondsSinceEpoch}-rating',
      type: DeliveryNegotiationEventType.deliveryRated,
      description: 'Calificación del cliente: $stars/5',
      driverId: driverId,
      createdAt: now,
    );

    final updated = negotiation.copyWith(
      rating: rating,
      history: [...negotiation.history, event],
    );

    return _repository.saveNegotiation(updated);
  }
}
