import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/app/dependency_injection/injection_container.dart';
import 'package:bebidas_delivery_app/core/di/service_locator.dart';
import 'package:bebidas_delivery_app/features/auth/application/dtos/auth_dtos.dart';
import 'package:bebidas_delivery_app/features/auth/di/auth_di.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/state/auth_controller.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/widgets/role_access_gate.dart';
import 'package:bebidas_delivery_app/features/users/di/users_di.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/role.dart';

void main() {
  setUp(() async {
    sl.reset();
    await InjectionContainer.init([UsersDi(), AuthDi()]);
  });

  testWidgets('denies a signed-in user whose role is not allowed', (
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
      const MaterialApp(
        home: RoleAccessGate(
          title: 'Administración del comercio',
          allowedRoles: {Role.store},
          child: Text('Contenido protegido'),
        ),
      ),
    );

    expect(
      find.text('No tienes permiso para acceder a esta pantalla.'),
      findsOneWidget,
    );
    expect(find.text('Contenido protegido'), findsNothing);
  });

  testWidgets('requires an active session', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RoleAccessGate(
          title: 'Administración del comercio',
          allowedRoles: {Role.store},
          child: Text('Contenido protegido'),
        ),
      ),
    );

    expect(find.textContaining('Tu sesión no está activa'), findsOneWidget);
    expect(find.text('Contenido protegido'), findsNothing);
  });
}
