import 'package:flutter/material.dart';

import '../../domain/entities/geo_coordinates.dart';
import '../../domain/entities/nearby_store.dart';

/// Prototype screen: map view with the user's current position and
/// nearby store markers.
///
/// Week-1 scope: static layout / visual prototype using dummy data.
/// Real GPS integration happens in Week 2.
class MapaProximoPage extends StatelessWidget {
  const MapaProximoPage({super.key});

  // ---------------------------------------------------------------------------
  // Dummy data — replaced with real calls in Week 2
  // ---------------------------------------------------------------------------
  static const GeoCoordinates _userPosition = GeoCoordinates(
    latitude: -0.9676534,
    longitude: -80.7088841, // Manta, Manabí
  );

  static const List<NearbyStore> _stores = [
    NearbyStore(
      id: 'store-001',
      name: 'Licorera El Barril',
      coordinates: GeoCoordinates(latitude: -0.9690, longitude: -80.7100),
      distanceKm: 0.3,
    ),
    NearbyStore(
      id: 'store-002',
      name: 'Distribuidora La Copa',
      coordinates: GeoCoordinates(latitude: -0.9650, longitude: -80.7050),
      distanceKm: 0.8,
    ),
    NearbyStore(
      id: 'store-003',
      name: 'Mini Market Central',
      coordinates: GeoCoordinates(latitude: -0.9720, longitude: -80.7130),
      distanceKm: 1.2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Mapa de Comercios Cercanos'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Map placeholder ─────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                    ),
                  ),
                  child: CustomPaint(painter: _MapGridPainter()),
                ),
                // User marker
                const Align(
                  alignment: Alignment.center,
                  child: _MapMarker(
                    label: 'Tú',
                    icon: Icons.my_location,
                    color: Colors.blue,
                    size: 48,
                  ),
                ),
                // Store markers (prototype positions)
                Align(
                  alignment: const Alignment(-0.6, 0.2),
                  child: _MapMarker(
                    label: _stores[0].name,
                    icon: Icons.storefront,
                    color: Colors.deepOrange,
                    size: 36,
                    distanceKm: _stores[0].distanceKm,
                  ),
                ),
                Align(
                  alignment: const Alignment(0.4, -0.4),
                  child: _MapMarker(
                    label: _stores[1].name,
                    icon: Icons.storefront,
                    color: Colors.deepOrange,
                    size: 36,
                    distanceKm: _stores[1].distanceKm,
                  ),
                ),
                Align(
                  alignment: const Alignment(-0.2, 0.7),
                  child: _MapMarker(
                    label: _stores[2].name,
                    icon: Icons.storefront,
                    color: Colors.deepOrange,
                    size: 36,
                    distanceKm: _stores[2].distanceKm,
                  ),
                ),
                // GPS coordinates chip
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: _CoordinatesChip(coordinates: _userPosition),
                ),
              ],
            ),
          ),
          // ── Store list ───────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Comercios cercanos',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _stores.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final store = _stores[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.storefront,
                            color: colorScheme.primary,
                          ),
                        ),
                        title: Text(store.name),
                        subtitle: Text(
                          '${store.distanceKm.toStringAsFixed(1)} km',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${store.name} — integración real en Semana 3',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS real disponible en Semana 2'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.my_location),
        label: const Text('Mi ubicación'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }
}

// ── Internal widgets ─────────────────────────────────────────────────────────

class _MapMarker extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double size;
  final double? distanceKm;

  const _MapMarker({
    required this.label,
    required this.icon,
    required this.color,
    this.size = 36,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: size),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            distanceKm != null
                ? '${label.split(' ').first} · ${distanceKm!.toStringAsFixed(1)} km'
                : label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _CoordinatesChip extends StatelessWidget {
  final GeoCoordinates coordinates;

  const _CoordinatesChip({required this.coordinates});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Lat ${coordinates.latitude.toStringAsFixed(4)}, '
        'Lng ${coordinates.longitude.toStringAsFixed(4)}',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..strokeWidth = 1;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
