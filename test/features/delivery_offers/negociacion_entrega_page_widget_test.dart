import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';
import 'package:bebidas_delivery_app/features/delivery_offers/infrastructure/repositories/in_memory_delivery_negotiation_repository.dart';
import 'package:bebidas_delivery_app/features/delivery_offers/presentation/controllers/delivery_negotiation_controller.dart';
import 'package:bebidas_delivery_app/features/delivery_offers/presentation/pages/negociacion_entrega_page.dart';

void main() {
  late DeliveryNegotiationController controller;

  setUp(() {
    controller = DeliveryNegotiationController(
      repository: InMemoryDeliveryNegotiationRepository(),
    );
  });

  tearDown(() => controller.dispose());

  testWidgets('simula dos ofertas, asigna una y cierra la otra', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NegociacionEntregaPage(
          negotiationId: 'req-demo-01',
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Negociación de entrega'), findsOneWidget);
    expect(find.textContaining('Buscando repartidor'), findsWidgets);
    expect(find.textContaining('Tu propuesta'), findsOneWidget);

    final simulateButton = find.text('Simular 2 repartidores');
    await tester.ensureVisible(simulateButton);
    await tester.pumpAndSettle();
    await tester.tap(simulateButton);
    await tester.pumpAndSettle();

    expect(find.text('Carlos Mendoza'), findsOneWidget);
    expect(find.text('Marcos Vera'), findsOneWidget);
    expect(find.text('Comparación de 2 ofertas'), findsOneWidget);
    expect(find.text('Mejor precio'), findsOneWidget);

    final acceptButtons = find.widgetWithText(FilledButton, 'Aceptar');
    expect(acceptButtons, findsNWidgets(2));
    await tester.ensureVisible(acceptButtons.first);
    await tester.tap(acceptButtons.first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Aceptar oferta'));
    await tester.pumpAndSettle();

    expect(find.text('Repartidor asignado'), findsWidgets);
    expect(find.text('Cerrada por otra aceptación'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Confirmar llegada al comercio'),
      findsOneWidget,
    );

    final advanceButton = find.widgetWithText(
      FilledButton,
      'Confirmar llegada al comercio',
    );
    await tester.ensureVisible(advanceButton);
    await tester.pumpAndSettle();
    await tester.tap(advanceButton);
    await tester.pumpAndSettle();

    expect(controller.negotiation!.status, DeliveryStatus.arrivedAtStore);
    expect(
      find.widgetWithText(FilledButton, 'Confirmar retiro del pedido'),
      findsOneWidget,
    );
  });
}
