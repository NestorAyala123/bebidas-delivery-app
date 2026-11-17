import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/delivery_offer.dart';
import '../repositories/delivery_repository.dart';

/// Caso de uso para consultar todas las ofertas asociadas a una solicitud de delivery.
/// 100% pure Dart, independiente de Flutter y Firebase.
class GetDeliveryOffersUseCase {
  final DeliveryRepository repository;

  const GetDeliveryOffersUseCase(this.repository);

  Future<Result<List<DeliveryOffer>, Failure>> call(String deliveryRequestId) {
    if (deliveryRequestId.trim().isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('El id de la solicitud no puede estar vacío.'),
        ),
      );
    }
    return repository.getOffersByDeliveryRequestId(deliveryRequestId);
  }
}
