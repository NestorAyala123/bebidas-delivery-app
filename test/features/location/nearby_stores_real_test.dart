import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/geo_coordinates.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/nearby_store.dart';
import 'package:bebidas_delivery_app/features/location/domain/usecases/obtener_comercios_cercanos_use_case.dart';
import 'package:bebidas_delivery_app/features/location/domain/usecases/obtener_ubicacion_actual_use_case.dart';
import 'package:bebidas_delivery_app/features/location/infrastructure/repositories/mock_location_repository.dart';
import 'package:bebidas_delivery_app/features/location/presentation/controllers/location_map_controller.dart';

void main() {
  late MockLocationRepository repository;
  late LocationMapController controller;

  setUp(() {
    repository = MockLocationRepository();
    controller = LocationMapController(
      obtenerUbicacionActualUseCase: ObtenerUbicacionActualUseCase(repository),
      obtenerComerciosCercanosUseCase: ObtenerComerciosCercanosUseCase(repository),
    );
  });

  group('Nearby Real Stores and Filters Tests', () {
    test('Los comercios reales contienen dirección, horario, teléfono y modalidades de entrega', () async {
      await controller.loadCurrentLocation();

      expect(controller.nearbyStores, isNotEmpty);
      final store = controller.nearbyStores.first;
      expect(store.address, isNotEmpty);
      expect(store.openingHours, isNotEmpty);
      expect(store.phone, isNotEmpty);
      expect(store.formattedDistance, isNotEmpty);
      // RN02: Modalidades de entrega
      expect(store.allowsExternalDelivery || store.hasOwnDelivery || store.allowsPickup, isTrue);
    });

    test('updateSearchRadius actualiza el radio y recalcula los comercios', () async {
      await controller.loadCurrentLocation();

      // Cambiar a radio muy estrecho (ej. 0.5 km)
      await controller.updateSearchRadius(0.5);
      expect(controller.searchRadiusKm, equals(0.5));
      expect(controller.nearbyStores.every((s) => s.distanceKm <= 0.5), isTrue);

      // Cambiar a radio más amplio (ej. 10 km)
      await controller.updateSearchRadius(10.0);
      expect(controller.searchRadiusKm, equals(10.0));
      expect(controller.nearbyStores.length, greaterThanOrEqualTo(5));
    });

    test('setSearchQuery filtra comercios por nombre o dirección', () async {
      await controller.loadCurrentLocation();

      controller.setSearchQuery('Barril');
      expect(controller.filteredStores.length, equals(1));
      expect(controller.filteredStores.first.name, contains('Barril'));

      controller.setSearchQuery('invalido_sin_coincidencia');
      expect(controller.filteredStores, isEmpty);
    });

    test('formattedDistance muestra metros si distancia < 1 km y km si >= 1 km', () {
      const storeNear = NearbyStore(
        id: '1',
        name: 'Cerca',
        coordinates: GeoCoordinates(latitude: 0, longitude: 0),
        distanceKm: 0.35,
      );
      expect(storeNear.formattedDistance, equals('350 m'));

      const storeFar = NearbyStore(
        id: '2',
        name: 'Lejos',
        coordinates: GeoCoordinates(latitude: 0, longitude: 0),
        distanceKm: 2.456,
      );
      expect(storeFar.formattedDistance, equals('2.46 km'));
    });
  });
}

