import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/geo_coordinates.dart';

void main() {
  group('GeoCoordinates Haversine Distance Tests', () {
    test('Calculates approximate distance between two coordinates', () {
      // Coordenadas aproximadas en Lima, Perú
      // Miraflores (-12.1219, -77.0297) -> San Isidro (-12.0970, -77.0365)
      const miraflores = GeoCoordinates(latitude: -12.1219, longitude: -77.0297);
      const sanIsidro = GeoCoordinates(latitude: -12.0970, longitude: -77.0365);

      final distanceKm = miraflores.distanceToInKm(sanIsidro);

      // Distancia aproximada en línea recta entre estos puntos es ~2.8 km
      expect(distanceKm, greaterThan(2.0));
      expect(distanceKm, lessThan(4.0));
    });

    test('Distance between same point is zero', () {
      const point = GeoCoordinates(latitude: -12.0, longitude: -77.0);
      expect(point.distanceToInKm(point), equals(0.0));
    });
  });
}
