import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/app/app.dart';
import 'package:bebidas_delivery_app/app/router/app_router.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/routes/auth_routes.dart';

void main() {
  testWidgets('App renders welcome page correctly', (
    WidgetTester tester,
  ) async {
    AppRouter.registerModules([AuthRoutes()]);

    await tester.pumpWidget(const BebidasDeliveryApp());
    await tester.pumpAndSettle();

    expect(find.text('Todo para brindar, en un solo lugar.'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Explora la plataforma'), findsOneWidget);
    expect(find.text('Administrar comercios'), findsOneWidget);
    expect(find.text('Negociar entrega'), findsOneWidget);
  });
}
