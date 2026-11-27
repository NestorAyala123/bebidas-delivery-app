import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/features/auth/domain/entities/user_session.dart';
import 'package:bebidas_delivery_app/features/auth/infrastructure/mock_auth_repository.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/pages/home_page.dart';

void main() {
  Future<UserSession> sessionFor(String email, String password) async {
    final result = await MockAuthRepository().login(
      email: email,
      password: password,
    );
    return result.dataOrNull!;
  }

  Future<void> pumpRoleHome(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    final session = await sessionFor(email, password);
    await tester.pumpWidget(MaterialApp(home: HomePage(session: session)));
    await tester.pumpAndSettle();
  }

  testWidgets('client sees customer flows, not provider operations', (
    tester,
  ) async {
    await pumpRoleHome(tester, 'cliente@demo.com', 'cliente123');

    expect(find.text('Crear Pedido / Resumen'), findsOneWidget);
    expect(find.text('Historial de Pedidos'), findsOneWidget);
    expect(find.text('Mapa de Comercios Cercanos'), findsOneWidget);
    expect(find.text('Servicios para Eventos'), findsOneWidget);
    expect(find.text('Módulo de Delivery'), findsOneWidget);
    expect(find.text('Mensajes'), findsOneWidget);
    expect(find.text('Administrar comercio y catálogo'), findsNothing);
    expect(find.text('Gestionar pedidos del comercio'), findsNothing);
  });

  testWidgets('store sees only store operations, chat and delivery', (
    tester,
  ) async {
    await pumpRoleHome(tester, 'comercio@demo.com', 'comercio123');

    expect(find.text('Administrar comercio y catálogo'), findsOneWidget);
    expect(find.text('Gestionar pedidos del comercio'), findsOneWidget);
    expect(find.text('Módulo de Delivery'), findsOneWidget);
    expect(find.text('Mensajes'), findsOneWidget);
    expect(find.text('Crear Pedido / Resumen'), findsNothing);
    expect(find.text('Historial de Pedidos'), findsNothing);
    expect(find.text('Mapa de Comercios Cercanos'), findsNothing);
    expect(find.text('Servicios para Eventos'), findsNothing);
  });

  testWidgets('driver sees delivery and chat only', (tester) async {
    await pumpRoleHome(tester, 'repartidor@demo.com', 'repartidor123');

    expect(find.text('Módulo de Delivery'), findsOneWidget);
    expect(find.text('Mensajes'), findsOneWidget);
    expect(find.text('Crear Pedido / Resumen'), findsNothing);
    expect(find.text('Historial de Pedidos'), findsNothing);
    expect(find.text('Administrar comercio y catálogo'), findsNothing);
    expect(find.text('Gestionar pedidos del comercio'), findsNothing);
    expect(find.text('Servicios para Eventos'), findsNothing);
  });

  testWidgets('event provider sees event services and chat only', (
    tester,
  ) async {
    await pumpRoleHome(tester, 'eventos@demo.com', 'eventos123');

    expect(find.text('Servicios para Eventos'), findsOneWidget);
    expect(find.text('Mensajes'), findsOneWidget);
    expect(find.text('Módulo de Delivery'), findsNothing);
    expect(find.text('Crear Pedido / Resumen'), findsNothing);
    expect(find.text('Historial de Pedidos'), findsNothing);
    expect(find.text('Administrar comercio y catálogo'), findsNothing);
    expect(find.text('Gestionar pedidos del comercio'), findsNothing);
  });
}
