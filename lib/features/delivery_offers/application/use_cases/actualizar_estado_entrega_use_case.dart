import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../delivery/domain/entities/delivery_status.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../../domain/entities/delivery_negotiation_event.dart';
import '../../domain/repositories/delivery_negotiation_repository.dart';
import '../../domain/services/delivery_lifecycle_service.dart';

/// Avanza la entrega por los estados permitidos.
class ActualizarEstadoEntregaUseCase {
  final DeliveryNegotiationRepository _repository;
  final DeliveryLifecycleService lifecycleService;

  const ActualizarEstadoEntregaUseCase(
    this._repository, {
    this.lifecycleService = const DeliveryLifecycleService(),
  });

  Future<Result<DeliveryNegotiation, Failure>> call({
    required String negotiationId,
    required DeliveryStatus next,
  }) async {
    final loaded = await _repository.getNegotiation(negotiationId);
    final failure = loaded.failureOrNull;
    if (failure != null) return FailureResult(failure);

    final negotiation = loaded.dataOrNull!;
    if (!lifecycleService.canTransition(negotiation.status, next)) {
      return FailureResult(
        BusinessRuleFailure(
          'No se puede pasar de "${negotiation.status.label}" a "${next.label}"',
        ),
      );
    }

    if (next != DeliveryStatus.cancelled && !negotiation.hasSelection) {
      return const FailureResult(
        BusinessRuleFailure(
          'Primero debes seleccionar la oferta de un repartidor',
        ),
      );
    }

    final now = DateTime.now();
    final event = DeliveryNegotiationEvent(
      id: 'evt-${now.microsecondsSinceEpoch}-status',
      type: DeliveryNegotiationEventType.statusChanged,
      description: 'Estado actualizado a ${next.label}',
      createdAt: now,
    );

    final updated = negotiation.copyWith(
      request: negotiation.request.copyWithStatus(next),
      history: [...negotiation.history, event],
    );

    return _repository.saveNegotiation(updated);
  }
}
