import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/obtener_servicios_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/publicar_ficha_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/infrastructure/repositories/in_memory_ficha_servicio_repository.dart';
import 'package:bebidas_delivery_app/features/event_services/presentation/controllers/event_services_controller.dart';
import 'package:bebidas_delivery_app/features/event_services/presentation/pages/publicar_ficha_page.dart';

void main() {
  testWidgets('PublicarFichaPage valida campos obligatorios antes de enviar', (tester) async {
    final repo = InMemoryFichaServicioRepository(initialFichas: []);
    final controller = EventServicesController(
      obtenerServiciosUseCase: ObtenerServiciosUseCase(repo),
      publicarFichaUseCase: PublicarFichaUseCase(repo),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PublicarFichaPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Publicar Ficha de Eventos'), findsOneWidget);

    // Hacer scroll hasta el botón de enviar
    final submitButton = find.widgetWithText(ElevatedButton, 'Publicar Ficha Básica');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();

    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verificamos que se muestran los mensajes de validación
    expect(find.text('Ingresa un título de al menos 3 caracteres'), findsOneWidget);
    expect(find.text('Ingresa un precio referencial'), findsOneWidget);
    expect(find.text('El teléfono de contacto es obligatorio'), findsOneWidget);
    expect(find.text('Indica la ciudad o zona de cobertura'), findsOneWidget);
    expect(find.text('La descripción debe tener al menos 10 caracteres'), findsOneWidget);
  });

  testWidgets('PublicarFichaPage publica con éxito cuando los campos son válidos', (tester) async {
    final repo = InMemoryFichaServicioRepository(initialFichas: []);
    final controller = EventServicesController(
      obtenerServiciosUseCase: ObtenerServiciosUseCase(repo),
      publicarFichaUseCase: PublicarFichaUseCase(repo),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PublicarFichaPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    // Llenar formulario
    await tester.enterText(find.byType(TextFormField).at(0), 'Barra de Cocteles Premium');
    await tester.enterText(find.byType(TextFormField).at(1), '250.00');
    await tester.enterText(find.byType(TextFormField).at(2), '+593 99 888 7777');
    await tester.enterText(find.byType(TextFormField).at(3), 'Manta, Manabí');
    await tester.enterText(find.byType(TextFormField).at(4), 'Servicio completo con licores premium y bármanes certificados.');

    final submitButton = find.widgetWithText(ElevatedButton, 'Publicar Ficha Básica');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();

    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verificamos que la ficha se insertó en el repositorio
    final fichas = await repo.getAllFichas();
    expect(fichas.dataOrNull!.any((f) => f.title == 'Barra de Cocteles Premium'), isTrue);
  });
}
