import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/app/app.dart';
import 'package:bebidas_delivery_app/app/dependency_injection/injection_container.dart';
import 'package:bebidas_delivery_app/app/router/app_router.dart';
import 'package:bebidas_delivery_app/core/di/service_locator.dart';
import 'package:bebidas_delivery_app/features/auth/application/use_cases/login_use_case.dart';
import 'package:bebidas_delivery_app/features/auth/di/auth_di.dart';
import 'package:bebidas_delivery_app/features/auth/infrastructure/mock_auth_repository.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/routes/auth_routes.dart';

void main() {
  setUp(() async {
    sl.reset();
    AppRouter.registerModules([AuthRoutes()]);
    await InjectionContainer.init([AuthDi()]);
  });

  group('Auth Login Flow Tests', () {
    test('LoginUseCase succeeds with valid credentials', () async {
      final repository = MockAuthRepository();
      final useCase = LoginUseCase(repository);

      final result = await useCase(
        email: 'cliente@delivery.com',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.email, 'cliente@delivery.com');
      expect(result.dataOrNull?.role.name, 'client');
    });

    test('LoginUseCase fails when email is invalid', () async {
      final repository = MockAuthRepository();
      final useCase = LoginUseCase(repository);

      final result = await useCase(
        email: 'invalid-email',
        password: 'password123',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, 'Formato de correo inválido');
    });

    test('LoginUseCase fails when password is too short', () async {
      final repository = MockAuthRepository();
      final useCase = LoginUseCase(repository);

      final result = await useCase(
        email: 'test@delivery.com',
        password: '123',
      );

      expect(result.isFailure, isTrue);
      expect(
        result.failureOrNull?.message,
        'La contraseña debe tener al menos 6 caracteres',
      );
    });

    testWidgets('Tapping Iniciar Sesión navigates to LoginPage', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const BebidasDeliveryApp());
      await tester.pumpAndSettle();

      expect(find.text('Iniciar Sesión'), findsOneWidget);

      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();

      // Verified on LoginPage
      expect(find.text('Ingresa a tu cuenta'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Ingresar'), findsOneWidget);
    });
  });
}
