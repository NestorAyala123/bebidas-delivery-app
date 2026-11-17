import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/location_fix.dart';
import '../repositories/location_repository.dart';

/// Obtiene la ubicación junto con su precisión aproximada.
///
/// Permite que el cálculo de tarifa y la pantalla de destino adviertan cuando
/// la lectura GPS es imprecisa.
class ObtenerUbicacionPrecisaUseCase {
  final LocationRepository _repository;

  const ObtenerUbicacionPrecisaUseCase(this._repository);

  Future<Result<LocationFix, Failure>> call() {
    return _repository.getCurrentFix();
  }
}
