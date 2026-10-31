import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/delivery_destination.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/geo_coordinates.dart';

void main() {
  group('DeliveryDestination Entity Tests', () {
    const coordinates = GeoCoordinates(
      latitude: -0.9676534,
      longitude: -80.7088841,
    );

    const destination = DeliveryDestination(
      address: 'Av. Flavio Reyes 123',
      reference: 'Casa esquinera blanca',
      coordinates: coordinates,
      receiverName: 'María López',
      receiverPhone: '0991234567',
    );

    test('formattedAddress incluye la referencia domiciliaria', () {
      expect(
        destination.formattedAddress,
        equals('Av. Flavio Reyes 123 (Casa esquinera blanca)'),
      );
    });

    test('formattedAddress omite paréntesis cuando no hay referencia', () {
      const withoutReference = DeliveryDestination(
        address: 'Av. 4 de Noviembre',
        coordinates: coordinates,
      );

      expect(withoutReference.formattedAddress, equals('Av. 4 de Noviembre'));
    });

    test('distanceTo calcula kilómetros usando Haversine', () {
      const store = GeoCoordinates(latitude: -0.9690, longitude: -80.7100);

      final distance = destination.distanceTo(store);

      expect(distance, greaterThan(0));
      expect(distance, lessThan(1));
    });

    test('copyWith actualiza solo los campos indicados', () {
      final updated = destination.copyWith(
        reference: 'Portón negro, frente al parque',
        receiverPhone: '0987654321',
      );

      expect(updated.address, equals(destination.address));
      expect(updated.reference, equals('Portón negro, frente al parque'));
      expect(updated.receiverPhone, equals('0987654321'));
      expect(updated.coordinates, equals(coordinates));
    });

    test('igualdad y hashCode se basan en dirección y coordenadas', () {
      const same = DeliveryDestination(
        address: 'Av. Flavio Reyes 123',
        reference: 'Otra referencia',
        coordinates: coordinates,
      );

      expect(destination, equals(same));
      expect(destination.hashCode, equals(same.hashCode));
    });

    test('toString muestra la dirección formateada y coordenadas', () {
      expect(destination.toString(), contains('Casa esquinera blanca'));
      expect(destination.toString(), contains('GeoCoordinates'));
    });
  });
}
