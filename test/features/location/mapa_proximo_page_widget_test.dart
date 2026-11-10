import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/location/domain/usecases/obtener_comercios_cercanos_use_case.dart';
import 'package:bebidas_delivery_app/features/location/domain/usecases/obtener_ubicacion_actual_use_case.dart';
import 'package:bebidas_delivery_app/features/location/infrastructure/repositories/mock_location_repository.dart';
import 'package:bebidas_delivery_app/features/location/presentation/controllers/location_map_controller.dart';
import 'package:bebidas_delivery_app/features/location/presentation/pages/mapa_proximo_page.dart';

void main() {
  testWidgets('Muestra mensaje explícito de permiso denegado cuando no se autoriza GPS', (tester) async {
    final mockRepo = MockLocationRepository(shouldGrantPermission: false);
    final controller = LocationMapController(
      obtenerUbicacionActualUseCase: ObtenerUbicacionActualUseCase(mockRepo),
      obtenerComerciosCercanosUseCase: ObtenerComerciosCercanosUseCase(mockRepo),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MapaProximoPage(controller: controller),
      ),
    );

    // Permitir que se complete la carga inicial
    await tester.pumpAndSettle();

    // Verificamos que se muestra el mensaje de permiso denegado requerido para la Semana 2
    expect(find.text('Permiso de Ubicación Denegado'), findsOneWidget);
    expect(find.text('Reintentar y Conceder Permiso'), findsOneWidget);
    expect(find.text('Abrir Ajustes del Dispositivo'), findsOneWidget);
    expect(find.text('Ver con Ubicación Simulada (Modo Pruebas)'), findsOneWidget);
  });

  testWidgets('Al conceder o simular ubicación se muestra la vista con comercios y mapa', (tester) async {
    final mockRepo = MockLocationRepository(shouldGrantPermission: true);
    final controller = LocationMapController(
      obtenerUbicacionActualUseCase: ObtenerUbicacionActualUseCase(mockRepo),
      obtenerComerciosCercanosUseCase: ObtenerComerciosCercanosUseCase(mockRepo),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MapaProximoPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    // Verificamos que aparecen los comercios cercanos y la sección de comercios
    expect(find.text('Comercios en tu zona'), findsOneWidget);
    expect(find.text('Licorera El Barril'), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsWidgets);
  });

  testWidgets('Muestra vista específica de permiso denegado permanentemente', (tester) async {
    final mockRepo = MockLocationRepository(isPermanentlyDenied: true);
    final controller = LocationMapController(
      obtenerUbicacionActualUseCase: ObtenerUbicacionActualUseCase(mockRepo),
      obtenerComerciosCercanosUseCase: ObtenerComerciosCercanosUseCase(mockRepo),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MapaProximoPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Permiso Denegado Permanentemente'), findsOneWidget);
    expect(find.text('Abrir Ajustes de la Aplicación'), findsOneWidget);
    expect(find.text('Ver con Ubicación Simulada (Modo Pruebas)'), findsOneWidget);
  });

  testWidgets('Muestra fallback amigable ante timeout o falta de señal GPS', (tester) async {
    final mockRepo = MockLocationRepository(isTimeout: true);
    final controller = LocationMapController(
      obtenerUbicacionActualUseCase: ObtenerUbicacionActualUseCase(mockRepo),
      obtenerComerciosCercanosUseCase: ObtenerComerciosCercanosUseCase(mockRepo),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MapaProximoPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sin Señal GPS'), findsOneWidget);
    expect(find.text('Reintentar GPS'), findsOneWidget);
    expect(find.text('Ingresar Dirección Manual'), findsOneWidget);
    expect(find.text('Usar Coordenadas de Prueba'), findsOneWidget);
  });

  testWidgets('Ofrece ampliar el radio cuando no hay comercios cercanos', (tester) async {
    final mockRepo = MockLocationRepository(
      shouldGrantPermission: true,
      initialStores: [],
    );
    final controller = LocationMapController(
      obtenerUbicacionActualUseCase: ObtenerUbicacionActualUseCase(mockRepo),
      obtenerComerciosCercanosUseCase: ObtenerComerciosCercanosUseCase(mockRepo),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MapaProximoPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('No hay comercios en un radio de 5 km'),
      findsOneWidget,
    );
    expect(find.text('Ampliar radio a 10 km'), findsOneWidget);
  });
}
