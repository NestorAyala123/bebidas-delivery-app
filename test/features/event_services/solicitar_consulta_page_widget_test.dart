import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/event_service.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/ficha_servicio.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/crear_consulta_servicio_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/obtener_consultas_servicio_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/infrastructure/repositories/in_memory_consulta_servicio_repository.dart';
import 'package:bebidas_delivery_app/features/event_services/presentation/controllers/consultas_controller.dart';
import 'package:bebidas_delivery_app/features/event_services/presentation/pages/solicitar_consulta_page.dart';

void main() {
  const ficha = FichaServicio(
    id: 'svc-001',
    providerId: 'prov-001',
    title: 'Bartender Profesional para Fiestas',
    description:
        'Coctelería artesanal y de autor para bodas y recepciones privadas.',
    serviceType: EventServiceType.bartender,
    estimatedPrice: 150.0,
    locationLabel: 'Manta, Manabí',
    contactPhone: '+593 99 111 2233',
    createdAt: '2026-10-20T10:00:00Z',
  );

  String futureDate() {
    final date = DateTime.now().add(const Duration(days: 45));
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  late InMemoryConsultaServicioRepository repository;
  late ConsultasController controller;

  setUp(() {
    repository = InMemoryConsultaServicioRepository(initialConsultas: []);
    controller = ConsultasController(
      crearConsultaServicioUseCase: CrearConsultaServicioUseCase(repository),
      obtenerConsultasServicioUseCase: ObtenerConsultasServicioUseCase(
        repository,
      ),
    );
  });

  testWidgets('envía una consulta completa y la persiste', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SolicitarConsultaPage(
          ficha: ficha,
          controller: controller,
          customerId: 'customer-demo',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Solicitar Cotización'), findsOneWidget);
    expect(find.text('Bartender Profesional para Fiestas'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('consulta_event_date_field')),
      futureDate(),
    );
    await tester.enterText(
      find.byKey(const Key('consulta_guest_count_field')),
      '80',
    );
    await tester.enterText(
      find.byKey(const Key('consulta_budget_field')),
      '250',
    );
    await tester.enterText(
      find.byKey(const Key('consulta_location_field')),
      'Av. Flavio Reyes, Manta',
    );
    await tester.enterText(
      find.byKey(const Key('consulta_name_field')),
      'David Vera',
    );
    await tester.enterText(
      find.byKey(const Key('consulta_phone_field')),
      '0991234567',
    );
    await tester.enterText(
      find.byKey(const Key('consulta_notes_field')),
      'Barra frente a la piscina',
    );

    final submitButton = find.byKey(const Key('consulta_submit_button'));
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('¡Consulta enviada!'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    expect(repository.consultas, hasLength(1));
    final saved = repository.consultas.first;
    expect(saved.serviceId, equals('svc-001'));
    expect(saved.customerId, equals('customer-demo'));
    expect(saved.guestCount, equals(80));
    expect(saved.notes, equals('Barra frente a la piscina'));
  });

  testWidgets('muestra errores de validación si el formulario está vacío', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SolicitarConsultaPage(ficha: ficha, controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('consulta_submit_button'));
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Selecciona la fecha tentativa del evento'),
      findsOneWidget,
    );
    expect(find.text('Ingresa un número válido'), findsOneWidget);
    expect(find.text('Indica la ubicación del evento'), findsOneWidget);
    expect(find.text('Ingresa tu nombre completo'), findsOneWidget);
    expect(find.text('Ingresa un teléfono válido'), findsOneWidget);
    expect(repository.consultas, isEmpty);
  });
}
