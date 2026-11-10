import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/geo_coordinates.dart';
import '../repositories/location_repository.dart';

/// Caso de uso para obtener la ubicación actual por GPS.
///
/// Retorna [GeoCoordinates] en caso de éxito.
/// En caso de fallo propaga fallos específicos:
///   - [PermissionFailure] cuando el usuario deniega el permiso.
///   - [PermissionPermanentlyDeniedFailure] cuando se deniega permanentemente.
///   - [LocationUnavailableFailure] cuando el GPS está apagado o sin señal.
class ObtenerUbicacionActualUseCase {
  final LocationRepository _repository;

  const ObtenerUbicacionActualUseCase(this._repository);

  Future<Result<GeoCoordinates, Failure>> call() async {
    return _repository.getCurrentPosition();
  }
}

// ---------------------------------------------------------------------------
// Fallos específicos de ubicación (capa de dominio pura, sin frameworks)
// ---------------------------------------------------------------------------

/// Ocurre cuando el usuario deniega el permiso de GPS.
class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'Permiso de ubicación denegado por el usuario',
    super.code,
  ]);
}

/// Ocurre cuando el usuario deniega el permiso permanentemente (marcó "no volver a preguntar").
class PermissionPermanentlyDeniedFailure extends PermissionFailure {
  const PermissionPermanentlyDeniedFailure([
    super.message =
        'El permiso de ubicación fue denegado permanentemente. Habilítalo en los ajustes de la aplicación.',
    super.code,
  ]);
}

/// Ocurre cuando el sensor GPS está apagado en el dispositivo o no hay señal.
class LocationUnavailableFailure extends Failure {
  const LocationUnavailableFailure([
    super.message = 'El servicio de GPS está desactivado o la ubicación no está disponible',
    super.code,
  ]);
}

/// Ocurre cuando el GPS no responde dentro del tiempo límite (sin señal,
/// interiores, túnel o sensor bloqueado).
class LocationTimeoutFailure extends LocationUnavailableFailure {
  const LocationTimeoutFailure([
    super.message =
        'El GPS no respondió a tiempo. Puedes reintentar, usar coordenadas de prueba o ingresar tu dirección manualmente.',
    super.code = 'location_timeout',
  ]);
}
