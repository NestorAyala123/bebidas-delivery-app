import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/di/service_locator.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/delivery_destination.dart';
import 'package:bebidas_delivery_app/features/location/domain/entities/geo_coordinates.dart';
import 'package:bebidas_delivery_app/features/location/domain/usecases/obtener_ubicacion_actual_use_case.dart';
import 'package:bebidas_delivery_app/features/location/infrastructure/repositories/mock_location_repository.dart';
import 'package:bebidas_delivery_app/features/location/presentation/pages/seleccionar_destino_entrega_page.dart';

void main() {
  const originStore = GeoCoordinates(latitude: -0.9690, longitude: -80.7100);

  const initialDestination = DeliveryDestination(
    address: 'Av. Flavio Reyes 123',
    reference: 'Casa esquinera blanca',
    coordinates: GeoCoordinates(latitude: -0.9676534, longitude: -80.7088841),
    receiverName: 'María López',
    receiverPhone: '0991234567',
  );

  setUp(() {
    ServiceLocator.instance.reset();
  });

  tearDown(() {
    ServiceLocator.instance.reset();
  });

  void registerLocationUseCase(MockLocationRepository repository) {
    ServiceLocator.instance.registerFactory<ObtenerUbicacionActualUseCase>(
      () => ObtenerUbicacionActualUseCase(repository),
    );
  }

  testWidgets('muestra dirección, referencias y estimación de distancia', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SeleccionarDestinoEntregaPage(
          originStoreCoordinates: originStore,
          storeName: 'Licorera El Barril',
          initialDestination: initialDestination,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dirección y Punto de Entrega'), findsOneWidget);
    expect(find.text('Av. Flavio Reyes 123'), findsOneWidget);
    expect(find.text('Casa esquinera blanca'), findsOneWidget);
    expect(find.textContaining('Distancia:'), findsOneWidget);
    expect(find.text('Confirmar Dirección y Destino'), findsOneWidget);
  });

  testWidgets(
    'muestra acción de ajustes ante permiso denegado permanentemente',
    (tester) async {
      final repository = MockLocationRepository(isPermanentlyDenied: true);
      registerLocationUseCase(repository);

      await tester.pumpWidget(
        const MaterialApp(
          home: SeleccionarDestinoEntregaPage(
            originStoreCoordinates: originStore,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      expect(find.text('Permiso denegado permanentemente'), findsOneWidget);
      expect(find.text('Abrir ajustes de la app'), findsOneWidget);
    },
  );

  testWidgets('ofrece fallback manual y coordenadas de prueba ante timeout', (
    tester,
  ) async {
    final repository = MockLocationRepository(isTimeout: true);
    registerLocationUseCase(repository);

    await tester.pumpWidget(
      const MaterialApp(
        home: SeleccionarDestinoEntregaPage(
          originStoreCoordinates: originStore,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pumpAndSettle();

    expect(find.text('Sin señal GPS'), findsOneWidget);
    expect(find.text('Dirección manual'), findsOneWidget);
    expect(find.text('Coordenadas de prueba'), findsOneWidget);

    await tester.tap(find.text('Coordenadas de prueba'));
    await tester.pumpAndSettle();

    expect(find.text('Sin señal GPS'), findsNothing);
  });

  testWidgets('confirma y devuelve el destino seleccionado', (tester) async {
    DeliveryDestination? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.push<DeliveryDestination>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SeleccionarDestinoEntregaPage(
                        initialDestination: initialDestination,
                      ),
                    ),
                  );
                },
                child: const Text('Abrir selector'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir selector'));
    await tester.pumpAndSettle();

    final confirmButton = find.text('Confirmar Dirección y Destino');
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.address, equals('Av. Flavio Reyes 123'));
    expect(result!.reference, equals('Casa esquinera blanca'));
    expect(result!.receiverPhone, equals('0991234567'));
    expect(result!.coordinates, equals(initialDestination.coordinates));
  });
}
