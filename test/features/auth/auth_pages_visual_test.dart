import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/app/dependency_injection/injection_container.dart';
import 'package:bebidas_delivery_app/core/di/service_locator.dart';
import 'package:bebidas_delivery_app/features/auth/application/dtos/auth_dtos.dart';
import 'package:bebidas_delivery_app/features/auth/di/auth_di.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/pages/edit_profile_page.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/pages/login_page.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/pages/profile_page.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/pages/register_page.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/state/auth_controller.dart';
import 'package:bebidas_delivery_app/features/users/di/users_di.dart';

void main() {
  setUp(() async {
    sl.reset();
    await InjectionContainer.init([UsersDi(), AuthDi()]);
  });

  testWidgets('login validates empty and malformed fields inline', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un correo válido'), findsOneWidget);
    expect(
      find.text('La contraseña debe tener al menos 6 caracteres'),
      findsOneWidget,
    );
  });

  testWidgets('password visibility can be toggled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    final password = find.byKey(const Key('login-password'));
    final textField = find.descendant(
      of: password,
      matching: find.byType(TextField),
    );

    expect(tester.widget<TextField>(textField).obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(tester.widget<TextField>(textField).obscureText, isFalse);
  });

  testWidgets('register role cards create an account with selected role', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const RegisterPage(),
        routes: {ProfilePage.route: (_) => const ProfilePage()},
      ),
    );

    await tester.enterText(
      find.byKey(const Key('register-name')),
      'Tienda Nueva',
    );
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'tienda@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'password123',
    );
    await tester.ensureVisible(find.text('Comercio'));
    await tester.tap(find.text('Comercio'));
    await tester.ensureVisible(find.text('Crear mi cuenta'));
    await tester.tap(find.text('Crear mi cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Comercio'), findsOneWidget);
    expect(sl.get<AuthController>().session?.role.name, 'store');
  });

  testWidgets('edit profile updates the profile and confirms success', (
    tester,
  ) async {
    final auth = sl.get<AuthController>();
    expect(
      await auth.login(
        const LoginRequest(email: 'cliente@demo.com', password: 'cliente123'),
      ),
      isTrue,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: const ProfilePage(),
        routes: {
          EditProfilePage.route: (_) => const EditProfilePage(),
          LoginPage.route: (_) => const LoginPage(),
        },
      ),
    );
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('edit-profile-name')),
      'Ana Actualizada',
    );
    await tester.enterText(
      find.byKey(const Key('edit-profile-phone')),
      '+593991112233',
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil actualizado correctamente'), findsOneWidget);
    expect(find.text('Ana Actualizada'), findsOneWidget);
    expect(find.text('+593991112233'), findsOneWidget);
  });
}
