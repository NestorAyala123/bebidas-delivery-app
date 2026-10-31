import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/delivery_request.dart';
import '../repositories/delivery_repository.dart';

/// Caso de uso para obtener las solicitudes de delivery en estado pendiente de oferta.
/// 100% pure Dart, independiente de Flutter y Firebase.
class GetPendingDeliveryRequestsUseCase {
  final DeliveryRepository repository;

  const GetPendingDeliveryRequestsUseCase(this.repository);

  Future<Result<List<DeliveryRequest>, Failure>> call() {
    return repository.getPendingDeliveryRequests();
  }
}
