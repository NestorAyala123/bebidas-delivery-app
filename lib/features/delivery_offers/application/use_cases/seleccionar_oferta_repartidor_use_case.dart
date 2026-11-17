import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../../domain/repositories/delivery_negotiation_repository.dart';

/// Selecciona la oferta ganadora y cierra las demás (RN06).
class SeleccionarOfertaRepartidorUseCase {
  final DeliveryNegotiationRepository _repository;

  const SeleccionarOfertaRepartidorUseCase(this._repository);

  Future<Result<DeliveryNegotiation, Failure>> call({
    required String negotiationId,
    required String offerId,
  }) {
    if (offerId.trim().isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('Debes elegir una oferta de repartidor'),
        ),
      );
    }
    return _repository.selectOffer(
      negotiationId: negotiationId,
      offerId: offerId,
    );
  }
}
