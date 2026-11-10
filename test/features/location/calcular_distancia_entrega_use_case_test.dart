import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/geo_coordinates.dart';
import 'package:bebidas_delivery_app/features/location/domain/usecases/calcular_distancia_entrega_use_case.dart';

void main() {
  const useCase = CalcularDistanciaEntregaUseCase();

  group('CalcularDistanciaEntregaUseCase Tests', () {
    test('calcula distancia, tiempo y tarifa referencial', () {
      const origin = GeoCoordinates(latitude: -0.9600, longitude: -80.7000);
      const destination = GeoCoordinates(
        latitude: -0.9700,
        longitude: -80.7100,
      );

      final result = useCase(origin: origin, destination: destination);

      expect(result.isSuccess, isTrue);
      final estimate = result.dataOrNull!;
      expect(estimate.distanceKm, greaterThan(0));
      expect(estimate.estimatedMinutes, greaterThan(10));
      expect(estimate.suggestedFee, greaterThan(1.50));
    });

    test('mismo punto produce distancia cero y tarifa base', () {
      const point = GeoCoordinates(latitude: -0.9600, longitude: -80.7000);

      final result = useCase(origin: point, destination: point);

      expect(result.isSuccess, isTrue);
      final estimate = result.dataOrNull!;
      expect(estimate.distanceKm, equals(0.0));
      expect(estimate.estimatedMinutes, equals(10));
      expect(estimate.suggestedFee, equals(1.50));
    });

    test('falla si el origen es la coordenada inválida (0,0)', () {
      const origin = GeoCoordinates(latitude: 0.0, longitude: 0.0);
      const destination = GeoCoordinates(
        latitude: -0.9700,
        longitude: -80.7100,
      );

      final result = useCase(origin: origin, destination: destination);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, contains('origen'));
    });

    test('falla si el destino es la coordenada inválida (0,0)', () {
      const origin = GeoCoordinates(latitude: -0.9600, longitude: -80.7000);
      const destination = GeoCoordinates(latitude: 0.0, longitude: 0.0);

      final result = useCase(origin: origin, destination: destination);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, contains('destino'));
    });

    test('formattedDistance muestra metros cuando es menor a 1 km', () {
      const estimate = DeliveryEstimate(
        distanceKm: 0.35,
        estimatedMinutes: 12,
        suggestedFee: 1.68,
      );

      expect(estimate.formattedDistance, equals('350 m'));
    });

    test('formattedDistance muestra kilómetros con dos decimales', () {
      const estimate = DeliveryEstimate(
        distanceKm: 2.5,
        estimatedMinutes: 18,
        suggestedFee: 2.75,
      );

      expect(estimate.formattedDistance, equals('2.50 km'));
    });
  });
}
