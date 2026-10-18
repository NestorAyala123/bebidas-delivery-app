import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/driver_status.dart';
import '../repositories/delivery_repository.dart';

/// Caso de uso para consultar la disponibilidad operativa de un repartidor.
/// 100% pure Dart, independiente de Flutter y Firebase.
class GetDriverAvailabilityUseCase {
  final DeliveryRepository repository;

  const GetDriverAvailabilityUseCase(this.repository);

  Future<Result<DriverStatus, Failure>> call(String driverId) {
    if (driverId.trim().isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('El id del repartidor no puede estar vacío'),
        ),
      );
    }
    return repository.getDriverAvailability(driverId.trim());
  }
}
