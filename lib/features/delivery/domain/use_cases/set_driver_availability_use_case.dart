import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/driver_status.dart';
import '../repositories/delivery_repository.dart';

/// Caso de uso para actualizar la disponibilidad operativa de un repartidor.
/// 100% pure Dart, independiente de Flutter y Firebase.
class SetDriverAvailabilityUseCase {
  final DeliveryRepository repository;

  const SetDriverAvailabilityUseCase(this.repository);

  Future<Result<void, Failure>> call({
    required String driverId,
    required DriverStatus status,
  }) {
    if (driverId.trim().isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('El id del repartidor no puede estar vacío'),
        ),
      );
    }
    return repository.setDriverAvailability(driverId.trim(), status);
  }
}
