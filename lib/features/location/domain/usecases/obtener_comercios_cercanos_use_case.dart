import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/geo_coordinates.dart';
import '../entities/nearby_store.dart';
import '../repositories/location_repository.dart';

/// Caso de uso para obtener comercios cercanos a partir de unas coordenadas de origen.
class ObtenerComerciosCercanosUseCase {
  final LocationRepository _repository;

  const ObtenerComerciosCercanosUseCase(this._repository);

  Future<Result<List<NearbyStore>, Failure>> call({
    required GeoCoordinates origin,
    double radiusKm = 5.0,
  }) {
    return _repository.getNearbyStores(origin: origin, radiusKm: radiusKm);
  }
}
