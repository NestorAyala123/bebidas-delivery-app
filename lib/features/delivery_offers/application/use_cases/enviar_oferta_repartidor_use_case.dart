import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../../domain/entities/delivery_negotiation_event.dart';
import '../../domain/entities/delivery_offer.dart';
import '../../domain/repositories/delivery_negotiation_repository.dart';

/// Registra la aceptación o contraoferta de un repartidor.
class EnviarOfertaRepartidorUseCase {
  final DeliveryNegotiationRepository _repository;

  const EnviarOfertaRepartidorUseCase(this._repository);

  Future<Result<DeliveryNegotiation, Failure>> call({
    required String negotiationId,
    required String driverId,
    required String driverName,
    required double amount,
  }) async {
    if (driverId.trim().isEmpty || driverName.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('El repartidor debe estar identificado'),
      );
    }

    if (amount.isNaN || amount.isInfinite || amount <= 0 || amount > 200) {
      return const FailureResult(
        ValidationFailure(
          'La oferta del repartidor debe estar entre \$1.00 y \$200.00',
        ),
      );
    }

    final loaded = await _repository.getNegotiation(negotiationId);
    final failure = loaded.failureOrNull;
    if (failure != null) return FailureResult(failure);

    final negotiation = loaded.dataOrNull!;
    if (!negotiation.isAwaitingOffers) {
      return const FailureResult(
        BusinessRuleFailure('La entrega ya no admite nuevas ofertas'),
      );
    }

    final hasActiveOffer = negotiation.offers.any(
      (offer) => offer.driverId == driverId && offer.status.isActive,
    );
    if (hasActiveOffer) {
      return const FailureResult(
        BusinessRuleFailure('El repartidor ya tiene una oferta pendiente'),
      );
    }

    final now = DateTime.now();
    final isCounterOffer = (amount - negotiation.customerOffer).abs() >= 0.01;
    final offer = DeliveryOffer(
      id: 'offer-$negotiationId-${now.microsecondsSinceEpoch}-$driverId',
      deliveryRequestId: negotiationId,
      driverId: driverId,
      driverName: driverName,
      offeredAmount: amount,
      isCounterOffer: isCounterOffer,
      createdAt: now,
    );

    final event = DeliveryNegotiationEvent(
      id: 'evt-${now.microsecondsSinceEpoch}-driver-$driverId',
      type: DeliveryNegotiationEventType.driverOfferReceived,
      description: isCounterOffer
          ? '$driverName envió una contraoferta de \$${amount.toStringAsFixed(2)}'
          : '$driverName aceptó la propuesta de \$${amount.toStringAsFixed(2)}',
      amount: amount,
      driverId: driverId,
      createdAt: now,
    );

    final updated = negotiation.copyWith(
      offers: [...negotiation.offers, offer],
      history: [...negotiation.history, event],
    );

    return _repository.saveNegotiation(updated);
  }
}
