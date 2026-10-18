import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/result/result.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/geo_coordinates.dart';
import 'package:bebidas_delivery_app/features/location/domain/usecases/obtener_ubicacion_actual_use_case.dart';
import 'package:bebidas_delivery_app/features/location/infrastructure/repositories/mock_location_repository.dart';

void main() {
  late MockLocationRepository repository;
  late ObtenerUbicacionActualUseCase useCase;

  setUp(() {
    repository = MockLocationRepository();
    useCase = ObtenerUbicacionActualUseCase(repository);
  });

  group('ObtenerUbicacionActualUseCase Tests', () {
    test('Devuelve coordenadas exitosas cuando se concede el permiso GPS', () async {
      repository.shouldGrantPermission = true;
      repository.isServiceEnabled = true;

      final result = await useCase();

      expect(result, isA<Success<GeoCoordinates, dynamic>>());
      final data = (result as Success<GeoCoordinates, dynamic>).data;
      expect(data.latitude, equals(-0.9676534));
      expect(data.longitude, equals(-80.7088841));
    });

    test('Devuelve PermissionFailure cuando el usuario deniega el permiso GPS', () async {
      repository.shouldGrantPermission = false;

      final result = await useCase();

      expect(result, isA<FailureResult<dynamic, dynamic>>());
      final failure = (result as FailureResult).failure;
      expect(failure, isA<PermissionFailure>());
      expect(failure.message, contains('denegado'));
    });

    test('Devuelve LocationUnavailableFailure cuando el GPS está desactivado', () async {
      repository.isServiceEnabled = false;

      final result = await useCase();

      expect(result, isA<FailureResult<dynamic, dynamic>>());
      final failure = (result as FailureResult).failure;
      expect(failure, isA<LocationUnavailableFailure>());
      expect(failure.message, contains('desactivado'));
    });
  });
}
