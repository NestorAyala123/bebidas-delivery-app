import 'package:flutter/material.dart';

import '../../../users/domain/entities/role.dart';
import '../state/current_identity.dart';
import 'session_gate.dart';

class RoleAccessGate extends StatelessWidget {
  final String title;
  final Set<Role> allowedRoles;
  final Widget child;

  const RoleAccessGate({
    super.key,
    required this.title,
    required this.allowedRoles,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final identity = currentIdentity();
    if (identity == null) return SignedOutView(title: title);
    if (!allowedRoles.contains(identity.rbacRole)) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No tienes permiso para acceder a esta pantalla.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return child;
  }
}
