import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/geo_coordinates.dart';
import '../repositories/location_repository.dart';

/// Use case: obtain the current GPS position.
///
/// On success returns [GeoCoordinates].
/// On failure returns:
///   - [PermissionFailure] when GPS permission is denied.
///   - [LocationUnavailableFailure] when the sensor is off or unreachable.
///   - Any other [Failure] propagated from the infrastructure layer.
class ObtenerUbicacionActualUseCase {
  final LocationRepository _repository;

  const ObtenerUbicacionActualUseCase(this._repository);

  Future<Result<GeoCoordinates, Failure>> call() async {
    final granted = await _repository.checkAndRequestPermission();

    if (!granted) {
      return const FailureResult(
        PermissionFailure('Permiso de ubicación denegado por el usuario'),
      );
    }

    return _repository.getCurrentPosition();
  }
}

// ---------------------------------------------------------------------------
// Location-specific failures (domain layer, no framework imports)
// ---------------------------------------------------------------------------

/// Thrown when the user denies the GPS permission.
class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'Permiso de ubicación denegado',
    super.code,
  ]);
}

/// Thrown when the GPS sensor is disabled or the position cannot be read.
class LocationUnavailableFailure extends Failure {
  const LocationUnavailableFailure([
    super.message = 'Ubicación no disponible',
    super.code,
  ]);
}
