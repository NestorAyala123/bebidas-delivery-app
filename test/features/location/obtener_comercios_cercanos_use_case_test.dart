import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/result/result.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/geo_coordinates.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/nearby_store.dart';
import 'package:bebidas_delivery_app/features/location/domain/usecases/obtener_comercios_cercanos_use_case.dart';
import 'package:bebidas_delivery_app/features/location/infrastructure/repositories/mock_location_repository.dart';

void main() {
  late MockLocationRepository repository;
  late ObtenerComerciosCercanosUseCase useCase;

  setUp(() {
    repository = MockLocationRepository();
    useCase = ObtenerComerciosCercanosUseCase(repository);
  });

  group('ObtenerComerciosCercanosUseCase Tests', () {
    test('Calcula distancias y devuelve comercios ordenados por proximidad', () async {
      const userOrigin = GeoCoordinates(
        latitude: -0.9676534,
        longitude: -80.7088841,
      );

      final result = await useCase(origin: userOrigin, radiusKm: 10.0);

      expect(result, isA<Success<List<NearbyStore>, dynamic>>());
      final stores = (result as Success<List<NearbyStore>, dynamic>).data;
      expect(stores, isNotEmpty);

      // Verificar que están ordenados de menor a mayor distancia
      for (int i = 0; i < stores.length - 1; i++) {
        expect(stores[i].distanceKm, lessThanOrEqualTo(stores[i + 1].distanceKm));
      }
    });
  });
}
