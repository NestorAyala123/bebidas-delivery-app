import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bebidas Delivery')),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
            ),
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
                  'Plataforma colaborativa para Clientes, Comercios, Repartidores y Eventos.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Módulo Auth listo para desarrollo'),
                      ),
                    );
                  },
                  child: const Text('Iniciar Sesión'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/mapa');
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Ver Mapa y GPS'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/eventos');
                  },
                  icon: const Icon(Icons.celebration_outlined),
                  label: const Text('Servicios para Eventos'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chat');
                  },
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Chat y avisos'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/pedidos');
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Mis pedidos'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/entregas/negociacion',
                      arguments: 'req-demo-01',
                    );
                  },
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text('Negociar entrega'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/entregas/historial');
                  },
                  icon: const Icon(Icons.history_outlined),
                  label: const Text('Historial de entregas'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
