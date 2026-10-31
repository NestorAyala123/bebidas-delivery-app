import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../chat/presentation/routes/chat_routes.dart';
import '../../../users/domain/entities/app_user.dart';
import '../state/auth_controller.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  static const route = '/profile';

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = sl.get<AuthController>();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final session = controller.session;
        if (session == null) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, LoginPage.route),
                child: const Text('Iniciar sesión'),
              ),
            ),
          );
        }
        final user = session.user;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi perfil'),
            actions: [
              IconButton(
                onPressed: () async {
                  await controller.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, LoginPage.route);
                  }
                },
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
          body: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      child: Text(user.name.substring(0, 1).toUpperCase()),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(user.email),
                    if (user.phoneNumber != null) Text(user.phoneNumber!),
                    const SizedBox(height: 8),
                    Chip(label: Text(_roleLabel(user.role))),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, EditProfilePage.route),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar perfil'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, ChatRoutes.conversations),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Mensajes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _roleLabel(UserRole role) => switch (role) {
  UserRole.client => 'Cliente',
  UserRole.store => 'Comercio',
  UserRole.driver => 'Repartidor',
  UserRole.eventProvider => 'Proveedor de eventos',
};
