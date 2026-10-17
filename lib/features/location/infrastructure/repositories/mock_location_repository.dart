import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/geo_coordinates.dart';
import '../../domain/entities/nearby_store.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/obtener_ubicacion_actual_use_case.dart';

/// Implementación simulada / doble de prueba para el repositorio de ubicación.
/// Útil para pruebas automatizadas y demostraciones sin depender de sensores reales.
class MockLocationRepository implements LocationRepository {
  bool shouldGrantPermission;
  bool isServiceEnabled;
  GeoCoordinates simulatedPosition;
  List<NearbyStore> mockStores;

  MockLocationRepository({
    this.shouldGrantPermission = true,
    this.isServiceEnabled = true,
    this.simulatedPosition = const GeoCoordinates(
      latitude: -0.9676534,
      longitude: -80.7088841, // Manta, Manabí
    ),
    List<NearbyStore>? initialStores,
  }) : mockStores = initialStores ??
            const [
              NearbyStore(
                id: 'store-001',
                name: 'Licorera El Barril',
                coordinates:
                    GeoCoordinates(latitude: -0.9690, longitude: -80.7100),
                distanceKm: 0.3,
              ),
              NearbyStore(
                id: 'store-002',
                name: 'Distribuidora La Copa',
                coordinates:
                    GeoCoordinates(latitude: -0.9650, longitude: -80.7050),
                distanceKm: 0.8,
              ),
              NearbyStore(
                id: 'store-003',
                name: 'Mini Market Central',
                coordinates:
                    GeoCoordinates(latitude: -0.9720, longitude: -80.7130),
                distanceKm: 1.2,
              ),
              NearbyStore(
                id: 'store-004',
                name: 'Bodega San Martín',
                coordinates:
                    GeoCoordinates(latitude: -0.9620, longitude: -80.7150),
                distanceKm: 1.5,
              ),
              NearbyStore(
                id: 'store-005',
                name: 'Licorería 24 Horas Express',
                coordinates:
                    GeoCoordinates(latitude: -0.9685, longitude: -80.7030),
                distanceKm: 0.6,
              ),
            ];

  @override
  Future<bool> checkAndRequestPermission() async {
    return shouldGrantPermission;
  }

  @override
  Future<Result<GeoCoordinates, Failure>> getCurrentPosition() async {
    if (!isServiceEnabled) {
      return const FailureResult(
        LocationUnavailableFailure('El servicio de GPS está desactivado'),
      );
    }
    if (!shouldGrantPermission) {
      return const FailureResult(
        PermissionFailure('Permiso de ubicación denegado por el usuario'),
      );
    }
    return Success(simulatedPosition);
  }

  @override
  Future<Result<List<NearbyStore>, Failure>> getNearbyStores({
    required GeoCoordinates origin,
    double radiusKm = 5.0,
  }) async {
    // Calculamos dinámicamente la distancia con la fórmula Haversine desde el origen
    final storesWithCalculatedDistances = mockStores.map((store) {
      final distance = origin.distanceToInKm(store.coordinates);
      return store.copyWith(distanceKm: distance);
    }).where((store) => store.distanceKm <= radiusKm).toList();

    // Ordenar de menor a mayor distancia
    storesWithCalculatedDistances
        .sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return Success(storesWithCalculatedDistances);
  }
}
