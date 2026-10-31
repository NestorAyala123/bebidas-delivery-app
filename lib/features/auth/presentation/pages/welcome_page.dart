import 'package:flutter/material.dart';

import '../routes/auth_routes.dart';
import '../../../location/presentation/routes/location_routes.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bebidas Delivery')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_bar, size: 72, color: Color(0xFF7A1C2C)),
              const SizedBox(height: 16),
              const Text(
                'Bienvenido a Bebidas Delivery',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Plataforma colaborativa para Clientes, Comercios, '
                'Repartidores y Eventos.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Acceso al inicio de sesión
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AuthRoutes.login);
                },
                child: const Text('Iniciar Sesión'),
              ),

              const SizedBox(height: 12),

              // Acceso al registro
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AuthRoutes.register);
                },
                child: const Text('Crear una cuenta'),
              ),

              const SizedBox(height: 12),

              // Acceso a comercios
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/stores');
                },
                child: const Text('Administrar comercios'),
              ),

              const SizedBox(height: 12),

              // Acceso al mapa (ruta resuelta desde LocationRoutes)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, LocationRoutes.mapa);
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ver mapa de comercios cercanos'),
              ),

              const SizedBox(height: 12),

              // Acceso a servicios para eventos (ruta literal de Adriano)
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pushNamed(context, '/eventos');
                },
                icon: const Icon(Icons.celebration_outlined),
                label: const Text('Servicios para Eventos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
