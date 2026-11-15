import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../delivery/domain/entities/delivery_status.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../../domain/entities/delivery_negotiation_event.dart';
import '../../domain/repositories/delivery_negotiation_repository.dart';

/// Cancela una entrega activa conservándola en el historial.
class CancelarEntregaUseCase {
  final DeliveryNegotiationRepository _repository;

  const CancelarEntregaUseCase(this._repository);

  Future<Result<DeliveryNegotiation, Failure>> call({
    required String negotiationId,
    String reason = '',
  }) async {
    final loaded = await _repository.getNegotiation(negotiationId);
    final failure = loaded.failureOrNull;
    if (failure != null) return FailureResult(failure);

    final negotiation = loaded.dataOrNull!;
    if (negotiation.isFinished) {
      return const FailureResult(
        BusinessRuleFailure('La entrega ya finalizó y no puede cancelarse'),
      );
    }

    final now = DateTime.now();
    final event = DeliveryNegotiationEvent(
      id: 'evt-${now.microsecondsSinceEpoch}-cancelled',
      type: DeliveryNegotiationEventType.deliveryCancelled,
      description: reason.trim().isEmpty
          ? 'Entrega cancelada por el cliente'
          : 'Entrega cancelada: ${reason.trim()}',
      createdAt: now,
    );

    final updated = negotiation.copyWith(
      request: negotiation.request.copyWithStatus(DeliveryStatus.cancelled),
      history: [...negotiation.history, event],
    );

    return _repository.saveNegotiation(updated);
  }
}
