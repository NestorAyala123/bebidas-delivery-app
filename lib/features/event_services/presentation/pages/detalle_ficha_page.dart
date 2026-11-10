import 'package:flutter/material.dart';

import '../../domain/entities/consulta_servicio.dart';
import '../../domain/entities/event_service.dart';
import '../../domain/entities/ficha_servicio.dart';
import 'solicitar_consulta_page.dart';

/// Pantalla para consultar la ficha completa de un proveedor de eventos.
class DetalleFichaPage extends StatelessWidget {
  final FichaServicio ficha;

  const DetalleFichaPage({super.key, required this.ficha});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha de Proveedor'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con Icono y Tipo de Servicio
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(50),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withAlpha(40)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    child: Icon(_getIconForType(ficha.serviceType), size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getLabelForType(ficha.serviceType).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ficha.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta de Precio Estimado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withAlpha(60)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tarifa / Presupuesto Estimado',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        'Precio referencial para eventos',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  Text(
                    '\$${ficha.estimatedPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ubicación y Contacto
            const Text(
              'Información del Proveedor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.location_on,
              title: 'Zona de Cobertura',
              subtitle: ficha.locationLabel,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.phone,
              title: 'Teléfono / WhatsApp',
              subtitle: ficha.contactPhone,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.verified_user,
              title: 'Estado del Servicio',
              subtitle: ficha.isAvailable ? 'Disponible para contrataciones' : 'No disponible temporalmente',
              color: ficha.isAvailable ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 20),

            // Descripción Detallada
            const Text(
              'Descripción y Alcance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                ficha.description,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),

            // Acción principal: solicitar cotización / consulta
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openConsulta(context),
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text(
                  'Solicitar Cotización / Consulta',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones de Acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Contactando a: ${ficha.contactPhone}'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Llamar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Abriendo conversación con proveedor: ${ficha.title}',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Contactar Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openConsulta(BuildContext context) async {
    final created = await Navigator.push<ConsultaServicio>(
      context,
      MaterialPageRoute(
        builder: (_) => SolicitarConsultaPage(ficha: ficha),
      ),
    );

    if (created != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Consulta enviada al proveedor de "${ficha.title}"',
          ),
        ),
      );
    }
  }

  static IconData _getIconForType(EventServiceType type) {
    switch (type) {
      case EventServiceType.bartender:
        return Icons.local_bar;
      case EventServiceType.iceAndCoolers:
        return Icons.ac_unit;
      case EventServiceType.soundAndDj:
        return Icons.speaker_group;
      case EventServiceType.customCocktailBar:
        return Icons.liquor;
      case EventServiceType.other:
        return Icons.celebration;
    }
  }

  static String _getLabelForType(EventServiceType type) {
    switch (type) {
      case EventServiceType.bartender:
        return 'Bartender';
      case EventServiceType.iceAndCoolers:
        return 'Hielo & Enfriadores';
      case EventServiceType.soundAndDj:
        return 'Sonido & DJ';
      case EventServiceType.customCocktailBar:
        return 'Barra de Cocteles';
      case EventServiceType.other:
        return 'Otro Servicio';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

