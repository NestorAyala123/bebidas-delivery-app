import 'package:flutter/material.dart';

import '../../../event_services/presentation/pages/listado_servicios_page.dart';
import '../../../location/presentation/pages/mapa_proximo_page.dart';
import '../../../users/domain/entities/app_user.dart';
import '../../domain/entities/user_session.dart';
import '../routes/auth_routes.dart';

class HomePage extends StatelessWidget {
  final UserSession session;

  const HomePage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final roleLabel = _roleLabel(session.role);
    final roleColor = _roleColor(session.role);
    final roleIcon = _roleIcon(session.role);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Bebidas Delivery - Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AuthRoutes.welcome,
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: roleColor.withAlpha(40),
                      child: Icon(roleIcon, size: 40, color: roleColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      session.email,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Chip(
                      avatar: Icon(roleIcon, size: 16, color: Colors.white),
                      label: Text(
                        roleLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: roleColor,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ID de Sesión: ${session.userId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Role specific banner
            Text(
              'Accesos Rápidos ($roleLabel)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Modules
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.map, color: Colors.green),
              ),
              title: const Text('Mapa de Comercios Cercanos'),
              subtitle: const Text('Prototipo de geolocalización y comercios'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapaProximoPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEDE7F6),
                child: Icon(Icons.event_seat, color: Colors.deepPurple),
              ),
              title: const Text('Servicios para Eventos'),
              subtitle: const Text('Bartenders, hielo, DJs y barras'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ListadoServiciosPage(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.local_shipping, color: Colors.orange),
              ),
              title: const Text('Módulo de Delivery'),
              subtitle: Text('Estado de repartos y entregas colaborativas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Módulo de entregas activado para tu rol.'),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AuthRoutes.welcome,
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) => switch (role) {
    UserRole.client => 'Cliente',
    UserRole.store => 'Comercio',
    UserRole.driver => 'Repartidor',
    UserRole.eventProvider => 'Proveedor de Eventos',
  };

  Color _roleColor(UserRole role) => switch (role) {
    UserRole.client => Colors.blue.shade700,
    UserRole.store => Colors.teal.shade700,
    UserRole.driver => Colors.deepOrange.shade700,
    UserRole.eventProvider => Colors.purple.shade700,
  };

  IconData _roleIcon(UserRole role) => switch (role) {
    UserRole.client => Icons.person,
    UserRole.store => Icons.storefront,
    UserRole.driver => Icons.two_wheeler,
    UserRole.eventProvider => Icons.celebration,
  };
}
