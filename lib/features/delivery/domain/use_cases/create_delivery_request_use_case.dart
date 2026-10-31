import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/delivery_fee.dart';
import '../entities/delivery_request.dart';
import '../repositories/delivery_repository.dart';

/// Caso de uso para registrar una solicitud de delivery con tarifa referencial calculada.
/// 100% pure Dart, independiente de Flutter y Firebase.
class CreateDeliveryRequestUseCase {
  final DeliveryRepository repository;
  final DeliveryFee feeCalculator;

  const CreateDeliveryRequestUseCase(
    this.repository, {
    this.feeCalculator = const DeliveryFee(),
  });

  Future<Result<DeliveryRequest, Failure>> call(DeliveryRequest request) {
    if (request.distanceInKm == null || request.distanceInKm! < 0) {
      return Future.value(
        const FailureResult(
          ValidationFailure(
            'La distancia en kilómetros es obligatoria y debe ser mayor o igual a 0',
          ),
        ),
      );
    }
    if (request.originAddress.trim().isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('La dirección de origen es obligatoria'),
        ),
      );
    }
    if (request.destinationAddress.trim().isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('La dirección de destino es obligatoria'),
        ),
      );
    }

    final calculatedFare = feeCalculator.calculate(request.distanceInKm!);
    final requestToPersist = request.copyWith(referenceFare: calculatedFare);

    return repository.createDeliveryRequest(requestToPersist);
  }
}
