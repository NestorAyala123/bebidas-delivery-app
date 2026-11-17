import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../../domain/entities/delivery_negotiation_event.dart';
import '../../domain/repositories/delivery_negotiation_repository.dart';
import '../../domain/services/offer_negotiation_service.dart';

/// Registra o actualiza la propuesta económica del cliente.
class ProponerOfertaClienteUseCase {
  final DeliveryNegotiationRepository _repository;
  final OfferNegotiationService negotiationService;

  const ProponerOfertaClienteUseCase(
    this._repository, {
    this.negotiationService = const OfferNegotiationService(),
  });

  Future<Result<DeliveryNegotiation, Failure>> call({
    required String negotiationId,
    required double amount,
  }) async {
    final loaded = await _repository.getNegotiation(negotiationId);
    final failure = loaded.failureOrNull;
    if (failure != null) return FailureResult(failure);

    final negotiation = loaded.dataOrNull!;
    if (!negotiation.isAwaitingOffers) {
      return const FailureResult(
        BusinessRuleFailure(
          'La propuesta solo puede modificarse mientras se buscan repartidores',
        ),
      );
    }

    if (!negotiationService.isValidClientOffer(
      amount: amount,
      referenceFare: negotiation.referenceFare,
    )) {
      return FailureResult(
        ValidationFailure(
          'La propuesta debe estar entre \$1.00 y \$200.00 y no superar '
          '3 veces la tarifa referencial (\$${negotiation.referenceFare.toStringAsFixed(2)})',
        ),
      );
    }

    final now = DateTime.now();
    final event = DeliveryNegotiationEvent(
      id: 'evt-${now.microsecondsSinceEpoch}-client-offer',
      type: DeliveryNegotiationEventType.clientOfferUpdated,
      description:
          'Propuesta del cliente actualizada a \$${amount.toStringAsFixed(2)}',
      amount: amount,
      createdAt: now,
    );

    final updated = negotiation.copyWith(
      request: negotiation.request.copyWithInitialCustomerOffer(amount),
      history: [...negotiation.history, event],
    );

    return _repository.saveNegotiation(updated);
  }
}
