import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/obtener_servicios_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/publicar_ficha_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/infrastructure/repositories/in_memory_ficha_servicio_repository.dart';
import 'package:bebidas_delivery_app/features/event_services/presentation/controllers/event_services_controller.dart';
import 'package:bebidas_delivery_app/features/event_services/presentation/pages/listado_servicios_page.dart';

void main() {
  testWidgets('ListadoServiciosPage muestra fichas precargadas y filtros de categoría', (tester) async {
    final repo = InMemoryFichaServicioRepository();
    final controller = EventServicesController(
      obtenerServiciosUseCase: ObtenerServiciosUseCase(repo),
      publicarFichaUseCase: PublicarFichaUseCase(repo),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ListadoServiciosPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Servicios para Eventos'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Bartender'), findsWidgets);
    expect(find.text('Hielo & Enfriadores'), findsOneWidget);
    expect(find.text('Publicar servicio'), findsOneWidget);
  });

  testWidgets('Filtrado por categoría actualiza el listado en pantalla', (tester) async {
    final repo = InMemoryFichaServicioRepository();
    final controller = EventServicesController(
      obtenerServiciosUseCase: ObtenerServiciosUseCase(repo),
      publicarFichaUseCase: PublicarFichaUseCase(repo),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ListadoServiciosPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    // Tocar el chip de Hielo & Enfriadores
    await tester.tap(find.text('Hielo & Enfriadores'));
    await tester.pumpAndSettle();

    expect(find.text('Hielo en Bloque y Enfriadores Express'), findsOneWidget);
  });
}

