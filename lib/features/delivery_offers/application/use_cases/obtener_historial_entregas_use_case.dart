import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../../domain/repositories/delivery_negotiation_repository.dart';

/// Obtiene el historial de entregas de un cliente.
class ObtenerHistorialEntregasUseCase {
  final DeliveryNegotiationRepository _repository;

  const ObtenerHistorialEntregasUseCase(this._repository);

  Future<Result<List<DeliveryNegotiation>, Failure>> call(String customerId) {
    return _repository.getHistory(customerId);
  }
}
