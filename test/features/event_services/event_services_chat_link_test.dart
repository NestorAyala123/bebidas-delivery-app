import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/chat/presentation/pages/chat_page.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/event_service.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/ficha_servicio.dart';
import 'package:bebidas_delivery_app/features/event_services/presentation/pages/detalle_ficha_page.dart';

void main() {
  const ficha = FichaServicio(
    id: 'svc-001',
    providerId: 'prov-001',
    title: 'Bartender Profesional para Fiestas',
    description: 'Servicio de bartender con insumos para eventos privados.',
    serviceType: EventServiceType.bartender,
    estimatedPrice: 180,
    locationLabel: 'Manta, Manabí',
    contactPhone: '+593 99 123 4567',
    createdAt: '2026-11-01',
  );

  testWidgets('la ficha abre un chat real con el proveedor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DetalleFichaPage(ficha: ficha)),
    );

    final chatButton = find.widgetWithText(ElevatedButton, 'Contactar Chat');
    await tester.ensureVisible(chatButton);
    await tester.pumpAndSettle();
    await tester.tap(chatButton);
    await tester.pumpAndSettle();

    expect(find.byType(ChatPage), findsOneWidget);
    expect(find.text('Proveedor de eventos'), findsOneWidget);
    expect(find.text('Bartender Profesional para Fiestas'), findsWidgets);
  });
}
