import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../../domain/repositories/delivery_negotiation_repository.dart';

/// Obtiene el agregado completo de una negociación de entrega.
class ObtenerNegociacionUseCase {
  final DeliveryNegotiationRepository _repository;

  const ObtenerNegociacionUseCase(this._repository);

  Future<Result<DeliveryNegotiation, Failure>> call(String negotiationId) {
    return _repository.getNegotiation(negotiationId);
  }
}
