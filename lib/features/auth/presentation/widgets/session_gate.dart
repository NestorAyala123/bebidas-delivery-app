import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../routes/auth_routes.dart';
import '../state/auth_controller.dart';

/// Shows [builder] only while there is a signed-in user.
///
/// It listens to [AuthController], so a logout (or a login with another
/// account) is reflected at once: the protected content is rebuilt for the
/// new identity, or replaced by a sign-in prompt.
class SessionGate extends StatelessWidget {
  final String title;
  final Widget Function(BuildContext context, IdentityContract identity)
  builder;
  final AuthController? controller;

  const SessionGate({
    super.key,
    required this.title,
    required this.builder,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final auth = controller ?? sl.get<AuthController>();
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final identity = auth.identity;
        if (identity == null) return SignedOutView(title: title);
        return KeyedSubtree(
          key: ValueKey(identity.id),
          child: builder(context, identity),
        );
      },
    );
  }
}

class SignedOutView extends StatelessWidget {
  final String title;

  const SignedOutView({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Tu sesión no está activa. Inicia sesión para continuar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, AuthRoutes.login),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
    ),
  );
}
