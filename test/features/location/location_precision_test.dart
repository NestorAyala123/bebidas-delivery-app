import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/geo_coordinates.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/location_fix.dart';
import 'package:bebidas_delivery_app/features/location/domain/usecases/calcular_distancia_entrega_use_case.dart';
import 'package:bebidas_delivery_app/features/location/domain/usecases/obtener_ubicacion_precisa_use_case.dart';
import 'package:bebidas_delivery_app/features/location/infrastructure/repositories/mock_location_repository.dart';

void main() {
  const origin = GeoCoordinates(latitude: -0.9676534, longitude: -80.7088841);

  group('LocationFix', () {
    test('clasifica precisión alta, media y baja según el margen', () {
      const high = LocationFix(coordinates: origin, accuracyMeters: 20);
      const medium = LocationFix(coordinates: origin, accuracyMeters: 120);
      const low = LocationFix(coordinates: origin, accuracyMeters: 400);

      expect(high.precision, LocationPrecision.high);
      expect(medium.precision, LocationPrecision.medium);
      expect(low.precision, LocationPrecision.low);
      expect(high.isApproximate, isFalse);
      expect(low.isApproximate, isTrue);
      expect(low.formattedPrecision, contains('aproximada'));
    });

    test('etiqueta lecturas simuladas sin margen reportado', () {
      const simulated = LocationFix(
        coordinates: origin,
        isSimulated: true,
      );
      const unknown = LocationFix(coordinates: origin);

      expect(simulated.accuracyLabel, contains('simulada'));
      expect(simulated.precision, LocationPrecision.medium);
      expect(unknown.accuracyLabel, contains('no reportada'));
    });
  });

  group('DeliveryEstimate con precisión', () {
    test('propaga el margen GPS y marca estimaciones aproximadas', () {
      final result = const CalcularDistanciaEntregaUseCase().fromDistance(
        2.4,
        accuracyMeters: 220,
      );

      final estimate = result.dataOrNull;
      expect(estimate, isNotNull);
      expect(estimate!.accuracyMeters, 220);
      expect(estimate.isApproximate, isTrue);
      expect(estimate.accuracyLabel, contains('220'));
      expect(estimate.suggestedFee, closeTo(2.70, 0.001));
    });

    test('rechaza márgenes de precisión inválidos', () {
      final result = const CalcularDistanciaEntregaUseCase().fromDistance(
        1,
        accuracyMeters: -5,
      );

      expect(result.dataOrNull, isNull);
    });
  });

  group('ObtenerUbicacionPrecisaUseCase', () {
    test('devuelve coordenadas y margen del repositorio', () async {
      final repository = MockLocationRepository(accuracyMeters: 18);
      final result = await ObtenerUbicacionPrecisaUseCase(repository)();

      expect(result.dataOrNull, isNotNull);
      expect(result.dataOrNull!.accuracyMeters, 18);
      expect(result.dataOrNull!.coordinates, repository.simulatedPosition);
    });

    test('propaga el fallo cuando el GPS está desactivado', () async {
      final repository = MockLocationRepository(isServiceEnabled: false);
      final result = await ObtenerUbicacionPrecisaUseCase(repository)();

      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull?.message, contains('desactivado'));
    });
  });
}
