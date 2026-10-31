import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/consulta_servicio.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/crear_consulta_servicio_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/obtener_consultas_servicio_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/infrastructure/repositories/in_memory_consulta_servicio_repository.dart';
import 'package:bebidas_delivery_app/features/event_services/presentation/controllers/consultas_controller.dart';
import 'package:bebidas_delivery_app/features/event_services/presentation/pages/mis_consultas_page.dart';

void main() {
  const consulta = ConsultaServicio(
    id: 'consulta-001',
    serviceId: 'svc-001',
    serviceTitle: 'DJ & Equipo de Sonido JBL',
    providerId: 'prov-003',
    customerId: 'customer-demo',
    customerName: 'David Vera',
    customerPhone: '0991234567',
    eventDate: '2026-12-15',
    guestCount: 120,
    location: 'Manta, Manabí',
    notes: 'Música hasta las 2am',
    budgetOffered: 300.0,
    createdAt: '2026-11-01T10:00:00Z',
  );

  late InMemoryConsultaServicioRepository repository;
  late ConsultasController controller;

  setUp(() {
    repository = InMemoryConsultaServicioRepository(
      initialConsultas: [consulta],
    );
    controller = ConsultasController(
      crearConsultaServicioUseCase: CrearConsultaServicioUseCase(repository),
      obtenerConsultasServicioUseCase: ObtenerConsultasServicioUseCase(
        repository,
      ),
    );
  });

  testWidgets('lista las consultas del cliente con su estado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MisConsultasPage(
          controller: controller,
          customerId: 'customer-demo',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mis Consultas de Eventos'), findsOneWidget);
    expect(find.text('DJ & Equipo de Sonido JBL'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('120 invitados'), findsOneWidget);
    expect(find.text('Chat con Nibia'), findsOneWidget);
  });

  testWidgets('abre el chat de la consulta y permite enviar un mensaje', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MisConsultasPage(
          controller: controller,
          customerId: 'customer-demo',
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat con Nibia'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Canal de coordinación del evento'),
      findsOneWidget,
    );
    expect(find.text('Chat con Nibia'), findsWidgets);

    await tester.enterText(find.byType(TextField), '¿Incluye luces robóticas?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('¿Incluye luces robóticas?'), findsOneWidget);
  });

  testWidgets('muestra estado vacío cuando no hay consultas', (tester) async {
    final emptyRepository = InMemoryConsultaServicioRepository(
      initialConsultas: [],
    );
    final emptyController = ConsultasController(
      crearConsultaServicioUseCase: CrearConsultaServicioUseCase(
        emptyRepository,
      ),
      obtenerConsultasServicioUseCase: ObtenerConsultasServicioUseCase(
        emptyRepository,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MisConsultasPage(
          controller: emptyController,
          customerId: 'customer-demo',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes consultas de eventos'), findsOneWidget);
  });
}
