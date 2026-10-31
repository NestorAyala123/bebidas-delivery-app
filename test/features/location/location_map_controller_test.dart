import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/location/domain/usecases/obtener_comercios_cercanos_use_case.dart';
import 'package:bebidas_delivery_app/features/location/domain/usecases/obtener_ubicacion_actual_use_case.dart';
import 'package:bebidas_delivery_app/features/location/infrastructure/repositories/mock_location_repository.dart';
import 'package:bebidas_delivery_app/features/location/presentation/controllers/location_map_controller.dart';

void main() {
  late MockLocationRepository repository;
  late ObtenerUbicacionActualUseCase ubicacionUseCase;
  late ObtenerComerciosCercanosUseCase comerciosUseCase;
  late LocationMapController controller;

  setUp(() {
    repository = MockLocationRepository();
    ubicacionUseCase = ObtenerUbicacionActualUseCase(repository);
    comerciosUseCase = ObtenerComerciosCercanosUseCase(repository);
    controller = LocationMapController(
      obtenerUbicacionActualUseCase: ubicacionUseCase,
      obtenerComerciosCercanosUseCase: comerciosUseCase,
    );
  });

  group('LocationMapController Tests', () {
    test('loadCurrentLocation asigna estado de éxito y comercios cuando se concede permiso', () async {
      repository.shouldGrantPermission = true;
      repository.isServiceEnabled = true;

      await controller.loadCurrentLocation();

      expect(controller.status, equals(LocationStatus.success));
      expect(controller.userPosition, isNotNull);
      expect(controller.nearbyStores, isNotEmpty);
      expect(controller.errorMessage, isNull);
    });

    test('loadCurrentLocation asigna estado permissionDenied y mensaje cuando el permiso es denegado', () async {
      repository.shouldGrantPermission = false;

      await controller.loadCurrentLocation();

      expect(controller.status, equals(LocationStatus.permissionDenied));
      expect(controller.isPermissionDenied, isTrue);
      expect(controller.errorMessage, contains('denegado'));
    });

    test('useSimulatedLocation activa modo simulado con coordenadas válidas', () async {
      await controller.useSimulatedLocation();

      expect(controller.status, equals(LocationStatus.success));
      expect(controller.isSimulatedMode, isTrue);
      expect(controller.userPosition, isNotNull);
      expect(controller.nearbyStores, isNotEmpty);
    });

    test('simulatePermissionDenied fuerza el estado permissionDenied para demostración', () {
      controller.simulatePermissionDenied();

      expect(controller.status, equals(LocationStatus.permissionDenied));
      expect(controller.errorMessage, isNotNull);
      expect(controller.nearbyStores, isEmpty);
    });

    test('loadCurrentLocation detecta permiso denegado permanentemente', () async {
      repository.isPermanentlyDenied = true;

      await controller.loadCurrentLocation();

      expect(controller.status, equals(LocationStatus.permissionPermanentlyDenied));
      expect(controller.isPermissionPermanentlyDenied, isTrue);
      expect(controller.errorMessage, contains('permanentemente'));
    });

    test('loadCurrentLocation detecta timeout o falta de señal GPS', () async {
      repository.isTimeout = true;

      await controller.loadCurrentLocation();

      expect(controller.status, equals(LocationStatus.timeout));
      expect(controller.isTimeout, isTrue);
      expect(controller.errorMessage, contains('GPS'));
    });

    test('useManualLocation activa fallback con dirección y comercios', () async {
      await controller.useManualLocation('Av. Flavio Reyes, Manta');

      expect(controller.status, equals(LocationStatus.success));
      expect(controller.manualAddress, equals('Av. Flavio Reyes, Manta'));
      expect(controller.nearbyStores, isNotEmpty);
    });
  });
}
