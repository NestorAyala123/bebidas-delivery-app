import 'package:flutter/material.dart';

import '../../domain/entities/event_service.dart';
import '../../domain/entities/ficha_servicio.dart';

/// Prototype screen: browsable list of event-service cards (fichas).
///
/// Week-1 scope: static layout / visual prototype using dummy data.
/// Real Firestore integration happens in Week 3.
class ListadoServiciosPage extends StatefulWidget {
  const ListadoServiciosPage({super.key});

  @override
  State<ListadoServiciosPage> createState() => _ListadoServiciosPageState();
}

class _ListadoServiciosPageState extends State<ListadoServiciosPage> {
  // ---------------------------------------------------------------------------
  // Dummy data — replaced by ObtenerServiciosUseCase in Week 3
  // ---------------------------------------------------------------------------
  static final List<FichaServicio> _dummyFichas = [
    FichaServicio(
      id: 'svc-001',
      providerId: 'prov-A',
      title: 'Bartender Profesional',
      description:
          'Coctelería artesanal para bodas, quinceañeros y eventos corporativos.',
      serviceType: EventServiceType.bartender,
      estimatedPrice: 150.00,
      locationLabel: 'Manta, Manabí',
      contactPhone: '+593 99 111 2233',
      createdAt: '2026-10-01',
    ),
    FichaServicio(
      id: 'svc-002',
      providerId: 'prov-B',
      title: 'Hielo y Enfriadores Premium',
      description:
          'Provisión de hielo en bloque, cubo y frappé + enfriadores en alquiler.',
      serviceType: EventServiceType.iceAndCoolers,
      estimatedPrice: 80.00,
      locationLabel: 'Portoviejo, Manabí',
      contactPhone: '+593 98 444 5566',
      createdAt: '2026-10-02',
    ),
    FichaServicio(
      id: 'svc-003',
      providerId: 'prov-C',
      title: 'DJ + Equipo de Sonido',
      description: 'Sets de música en vivo, equipos JBL y luces LED.',
      serviceType: EventServiceType.soundAndDj,
      estimatedPrice: 300.00,
      locationLabel: 'Manta, Manabí',
      contactPhone: '+593 96 777 8899',
      createdAt: '2026-10-03',
    ),
    FichaServicio(
      id: 'svc-004',
      providerId: 'prov-D',
      title: 'Barra de Cocteles Personalizados',
      description: 'Diseñamos la bebida signature de tu evento.',
      serviceType: EventServiceType.customCocktailBar,
      estimatedPrice: 220.00,
      locationLabel: 'Bahía de Caráquez',
      contactPhone: '+593 99 333 0011',
      createdAt: '2026-10-04',
    ),
  ];

  EventServiceType? _selectedType;

  List<FichaServicio> get _filtered => _selectedType == null
      ? _dummyFichas
      : _dummyFichas
          .where((f) => f.serviceType == _selectedType)
          .toList();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Servicios para Eventos'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Active filter chip ───────────────────────────────────────────
          if (_selectedType != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Text(
                    'Filtrando: ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Chip(
                    label: Text(_typeLabel(_selectedType!)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _selectedType = null),
                    backgroundColor: colorScheme.primaryContainer,
                  ),
                ],
              ),
            ),
          // ── Card list ────────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('No hay fichas para este tipo de servicio'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) =>
                        _FichaCard(ficha: _filtered[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publicación de ficha disponible en Semana 3'),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Publicar servicio'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Filtrar por tipo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...EventServiceType.values.map(
            (type) => RadioListTile<EventServiceType>(
              title: Text(_typeLabel(type)),
              value: type,
              groupValue: _selectedType,
              onChanged: (v) {
                setState(() => _selectedType = v);
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _typeLabel(EventServiceType type) => switch (type) {
        EventServiceType.bartender => 'Bartender',
        EventServiceType.iceAndCoolers => 'Hielo y Enfriadores',
        EventServiceType.soundAndDj => 'Sonido y DJ',
        EventServiceType.customCocktailBar => 'Barra de Cocteles',
        EventServiceType.other => 'Otro',
      };
}

// ── FichaCard widget ─────────────────────────────────────────────────────────

class _FichaCard extends StatelessWidget {
  final FichaServicio ficha;

  const _FichaCard({required this.ficha});

  static const Map<EventServiceType, IconData> _icons = {
    EventServiceType.bartender: Icons.sports_bar,
    EventServiceType.iceAndCoolers: Icons.ac_unit,
    EventServiceType.soundAndDj: Icons.music_note,
    EventServiceType.customCocktailBar: Icons.local_bar,
    EventServiceType.other: Icons.miscellaneous_services,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _icons[ficha.serviceType] ?? Icons.miscellaneous_services;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ficha.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ficha.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _InfoChip(
                        icon: Icons.location_on,
                        label: ficha.locationLabel,
                      ),
                      _InfoChip(
                        icon: Icons.attach_money,
                        label: '\$${ficha.estimatedPrice.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Chat con proveedor ${ficha.providerId} — Semana 5',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Contactar proveedor'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
