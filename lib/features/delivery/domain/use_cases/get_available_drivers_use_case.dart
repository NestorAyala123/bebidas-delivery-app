import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/driver.dart';
import '../entities/driver_status.dart';
import '../repositories/delivery_repository.dart';

/// Caso de uso para consultar los repartidores registrados y filtrar
/// exclusivamente aquellos que se encuentran en estado disponible (DriverStatus.available).
/// Excluye explícitamente a los repartidores ocupados (busy) y desconectados (offline).
/// 100% pure Dart, independiente de Flutter y Firebase.
class GetAvailableDriversUseCase {
  final DeliveryRepository repository;

  const GetAvailableDriversUseCase(this.repository);

  Future<Result<List<Driver>, Failure>> call() async {
    final result = await repository.getRegisteredDrivers();
    if (result.isFailure) {
      return result;
    }

    final drivers = result.dataOrNull ?? [];
    final availableDrivers = drivers
        .where((driver) => driver.status == DriverStatus.available)
        .toList();

    return Success(availableDrivers);
  }
}
