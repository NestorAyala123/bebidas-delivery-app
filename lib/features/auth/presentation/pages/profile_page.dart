import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../chat/presentation/routes/chat_routes.dart';
import '../../../chat/presentation/widgets/chat_inbox_button.dart';
import '../../../users/domain/entities/app_user.dart';
import '../state/auth_controller.dart';
import 'edit_profile_page.dart';
import 'home_page.dart';
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
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, LoginPage.route),
                icon: const Icon(Icons.login),
                label: const Text('Iniciar sesión'),
              ),
            ),
          );
        }

        final user = session.user;
        final colors = Theme.of(context).colorScheme;
        final name = user.name.trim();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi perfil'),
            actions: [
              const ChatInboxButton(),
              IconButton(
                onPressed: () => _logout(context, controller),
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primary,
                            Color.lerp(colors.primary, colors.tertiary, 0.55)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: colors.onPrimary.withValues(
                              alpha: 0.16,
                            ),
                            foregroundColor: colors.onPrimary,
                            child: Text(
                              name.isEmpty ? '?' : name[0].toUpperCase(),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name.isEmpty ? 'Mi cuenta' : name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onPrimary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: colors.onPrimary.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Chip(
                            avatar: Icon(
                              _roleIcon(user.role),
                              size: 18,
                              color: colors.onSecondaryContainer,
                            ),
                            label: Text(_roleLabel(user.role)),
                            backgroundColor: colors.secondaryContainer,
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colors.secondaryContainer,
                              foregroundColor: colors.onSecondaryContainer,
                              child: const Icon(Icons.email_outlined),
                            ),
                            title: const Text('Correo electrónico'),
                            subtitle: Text(user.email),
                          ),
                          const Divider(height: 1, indent: 72),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colors.secondaryContainer,
                              foregroundColor: colors.onSecondaryContainer,
                              child: const Icon(Icons.phone_outlined),
                            ),
                            title: const Text('Teléfono'),
                            subtitle: Text(
                              user.phoneNumber ?? 'No agregado todavía',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _editProfile(context),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar perfil'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        ChatRoutes.conversations,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Ver mis mensajes'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => HomePage(session: session),
                        ),
                      ),
                      icon: const Icon(Icons.dashboard_outlined),
                      label: const Text('Ir a mi panel'),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _logout(context, controller),
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
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

  Future<void> _editProfile(BuildContext context) async {
    final updated = await Navigator.pushNamed(context, EditProfilePage.route);
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
    }
  }

  Future<void> _logout(BuildContext context, AuthController controller) async {
    await controller.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginPage.route,
        (route) => false,
      );
    }
  }
}

String _roleLabel(UserRole role) => switch (role) {
  UserRole.client => 'Cliente',
  UserRole.store => 'Comercio',
  UserRole.driver => 'Repartidor',
  UserRole.eventProvider => 'Proveedor de eventos',
};

IconData _roleIcon(UserRole role) => switch (role) {
  UserRole.client => Icons.person_outline,
  UserRole.store => Icons.storefront_outlined,
  UserRole.driver => Icons.delivery_dining,
  UserRole.eventProvider => Icons.celebration_outlined,
};
