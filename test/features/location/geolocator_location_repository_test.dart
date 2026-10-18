import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/result/result.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/geo_coordinates.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/nearby_store.dart';
import 'package:bebidas_delivery_app/features/location/infrastructure/repositories/geolocator_location_repository.dart';

void main() {
  group('GeolocatorLocationRepository', () {
    test('filtra los comercios que superan el radio indicado', () async {
      const origin = GeoCoordinates(latitude: 0.0, longitude: 0.0);

      final repository = GeolocatorLocationRepository(
        seedStores: const [
          NearbyStore(
            id: 'near',
            name: 'Comercio cercano',
            coordinates: GeoCoordinates(latitude: 0.0005, longitude: 0.0),
            distanceKm: 0.0,
          ),
          NearbyStore(
            id: 'far',
            name: 'Comercio lejano',
            coordinates: GeoCoordinates(latitude: 0.02, longitude: 0.0),
            distanceKm: 0.0,
          ),
        ],
      );

      final result = await repository.getNearbyStores(
        origin: origin,
        radiusKm: 0.5,
      );

      expect(result, isA<Success<List<NearbyStore>, dynamic>>());

      final stores = (result as Success<List<NearbyStore>, dynamic>).data;

      expect(stores, hasLength(1));
      expect(stores.single.id, 'near');
      expect(stores.single.distanceKm, lessThanOrEqualTo(0.5));
    });

    test('devuelve los comercios ordenados por distancia', () async {
      const origin = GeoCoordinates(latitude: 0.0, longitude: 0.0);

      final repository = GeolocatorLocationRepository(
        seedStores: const [
          NearbyStore(
            id: 'farther',
            name: 'Comercio más lejano',
            coordinates: GeoCoordinates(latitude: 0.002, longitude: 0.0),
            distanceKm: 0.0,
          ),
          NearbyStore(
            id: 'closer',
            name: 'Comercio más cercano',
            coordinates: GeoCoordinates(latitude: 0.0005, longitude: 0.0),
            distanceKm: 0.0,
          ),
        ],
      );

      final result = await repository.getNearbyStores(
        origin: origin,
        radiusKm: 1.0,
      );

      expect(result, isA<Success<List<NearbyStore>, dynamic>>());

      final stores = (result as Success<List<NearbyStore>, dynamic>).data;

      expect(stores, hasLength(2));
      expect(stores.first.id, 'closer');
      expect(stores.last.id, 'farther');
      expect(
        stores.first.distanceKm,
        lessThanOrEqualTo(stores.last.distanceKm),
      );
    });
  });
}
