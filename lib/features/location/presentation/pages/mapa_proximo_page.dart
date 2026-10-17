import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/geo_coordinates.dart';
import '../../domain/entities/nearby_store.dart';
import '../../domain/usecases/obtener_comercios_cercanos_use_case.dart';
import '../../domain/usecases/obtener_ubicacion_actual_use_case.dart';
import '../controllers/location_map_controller.dart';

/// Pantalla principal del módulo de Ubicación y Mapas (Semana 2).
///
/// Implementa:
/// - Verificación y solicitud de permiso de GPS.
/// - Mensaje de advertencia amigable si se deniega el permiso, con opción de reintento.
/// - Mapa interactivo (OpenStreetMap) con marcador de la ubicación actual del usuario.
/// - Marcadores con datos de prueba de comercios cercanos y distancias calculadas (Haversine).
/// - Herramientas de prueba/demostración para alternar entre GPS real, denegación y simulación.
class MapaProximoPage extends StatefulWidget {
  final LocationMapController? controller;

  const MapaProximoPage({super.key, this.controller});

  @override
  State<MapaProximoPage> createState() => _MapaProximoPageState();
}

class _MapaProximoPageState extends State<MapaProximoPage> {
  late final LocationMapController _controller;
  late final MapController _mapController;
  bool _isControllerInternal = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _isControllerInternal = true;
      // Resolver dependencias desde el contenedor o instanciar con repositorio
      final obtenerUbicacion = ServiceLocator.instance.isRegistered<ObtenerUbicacionActualUseCase>()
          ? ServiceLocator.instance.get<ObtenerUbicacionActualUseCase>()
          : null;
      final obtenerComercios = ServiceLocator.instance.isRegistered<ObtenerComerciosCercanosUseCase>()
          ? ServiceLocator.instance.get<ObtenerComerciosCercanosUseCase>()
          : null;

      if (obtenerUbicacion != null && obtenerComercios != null) {
        _controller = LocationMapController(
          obtenerUbicacionActualUseCase: obtenerUbicacion,
          obtenerComerciosCercanosUseCase: obtenerComercios,
        );
      } else {
        // Fallback seguro si se abre la pantalla antes de inicializar el inyector
        _controller = LocationMapController(
          obtenerUbicacionActualUseCase: ObtenerUbicacionActualUseCase(
            ServiceLocator.instance.get(),
          ),
          obtenerComerciosCercanosUseCase: ObtenerComerciosCercanosUseCase(
            ServiceLocator.instance.get(),
          ),
        );
      }
    }

    _controller.addListener(_onControllerUpdate);

    // Iniciar la obtención de ubicación al montar la vista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadCurrentLocation();
    });
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});

    // Centrar el mapa cuando se obtiene una nueva posición válida una vez montado
    final pos = _controller.userPosition;
    if (pos != null && _controller.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
        } catch (_) {
          // Si el widget FlutterMap aún no ha sido renderizado por primera vez
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (_isControllerInternal) {
      _controller.dispose();
    }
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comercios Cercanos (GPS)'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opciones de Prueba / Demostración',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'gps_real') {
                _controller.loadCurrentLocation();
              } else if (value == 'simulate_denied') {
                _controller.simulatePermissionDenied();
              } else if (value == 'simulate_success') {
                _controller.useSimulatedLocation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'gps_real',
                child: Row(
                  children: [
                    Icon(Icons.gps_fixed, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Solicitar GPS Real'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'simulate_denied',
                child: Row(
                  children: [
                    Icon(Icons.location_off, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Simular Permiso Denegado'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'simulate_success',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Usar Ubicación de Prueba'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(context),
      floatingActionButton: _controller.userPosition != null
          ? FloatingActionButton.extended(
              onPressed: () {
                final pos = _controller.userPosition!;
                _mapController.move(LatLng(pos.latitude, pos.longitude), 15.5);
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Mi ubicación'),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_controller.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Obteniendo ubicación GPS...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Calculando tiendas y licorerías cercanas',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // ── ESTADO: PERMISO DENEGADO ──────────────────────────────────────────
    if (_controller.isPermissionDenied) {
      return _buildPermissionDeniedView(context);
    }

    // ── ESTADO: SERVICIO DESACTIVADO O ERROR ──────────────────────────────
    if (_controller.status == LocationStatus.serviceDisabled ||
        _controller.status == LocationStatus.error) {
      return _buildServiceDisabledView(context);
    }

    // ── ESTADO: ÉXITO (MAPA + LISTA DE COMERCIOS) ─────────────────────────
    if (_controller.isSuccess && _controller.userPosition != null) {
      return _buildMapWithStoresView(context);
    }

    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _controller.loadCurrentLocation(),
        icon: const Icon(Icons.location_searching),
        label: const Text('Iniciar Detección de Ubicación'),
      ),
    );
  }

  /// Vista mostrada explícitamente cuando el usuario deniega los permisos de GPS.
  Widget _buildPermissionDeniedView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off,
                size: 72,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Permiso de Ubicación Denegado',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _controller.errorMessage ??
                  'No es posible mostrar las licorerías y comercios cercanos porque el permiso de GPS fue denegado.',
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade700.withAlpha(80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Puedes conceder el permiso en cualquier momento o explorar con una ubicación de prueba.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _controller.retryPermission(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar y Conceder Permiso'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _controller.openAppSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Abrir Ajustes del Dispositivo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _controller.useSimulatedLocation(),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Ver con Ubicación Simulada (Modo Pruebas)'),
            ),
          ],
        ),
      ),
    );
  }

  /// Vista mostrada si el sensor GPS está apagado en el dispositivo.
  Widget _buildServiceDisabledView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gps_off, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'GPS Desactivado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage ?? 'Por favor activa el GPS en tu teléfono.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _controller.retryPermission(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _controller.useSimulatedLocation(),
              icon: const Icon(Icons.science),
              label: const Text('Usar ubicación simulada'),
            ),
          ],
        ),
      ),
    );
  }

  /// Vista con mapa interactivo y lista de comercios
  Widget _buildMapWithStoresView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userPos = _controller.userPosition!;
    final userLatLng = LatLng(userPos.latitude, userPos.longitude);

    return Column(
      children: [
        // Banner indicador si está en modo simulado
        if (_controller.isSimulatedMode)
          Container(
            color: Colors.amber.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.info, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Modo Demostración: Coordenadas simuladas activas.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => _controller.loadCurrentLocation(),
                  child: const Text('Usar GPS Real', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

        // ── MAPA INTERACTIVO ────────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userLatLng,
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.bebidas_delivery_app',
                  ),
                  MarkerLayer(
                    markers: [
                      // Marcador de la ubicación del usuario
                      Marker(
                        point: userLatLng,
                        width: 70,
                        height: 70,
                        child: const _UserLocationMarker(),
                      ),
                      // Marcadores con datos de prueba de comercios cercanos
                      ..._controller.nearbyStores.map((store) {
                        final storeLatLng = LatLng(
                          store.coordinates.latitude,
                          store.coordinates.longitude,
                        );
                        final isSelected = _controller.selectedStore?.id == store.id;

                        return Marker(
                          point: storeLatLng,
                          width: 80,
                          height: 60,
                          child: GestureDetector(
                            onTap: () {
                              _controller.selectStore(store);
                              _mapController.move(storeLatLng, 16.0);
                              _showStoreModal(context, store);
                            },
                            child: _StoreMarker(
                              store: store,
                              isSelected: isSelected,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),

              // Chip con las coordenadas actuales
              Positioned(
                top: 12,
                left: 12,
                child: _CoordinatesChip(coordinates: userPos),
              ),

              // Contador de comercios detectados
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront, size: 16, color: Colors.deepOrange),
                      const SizedBox(width: 4),
                      Text(
                        '${_controller.nearbyStores.length} tiendas',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── LISTA DE COMERCIOS CERCANOS ──────────────────────────────────────
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comercios en tu zona',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Calculado por Haversine',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: _controller.nearbyStores.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final store = _controller.nearbyStores[index];
                    final isSelected = _controller.selectedStore?.id == store.id;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: colorScheme.primaryContainer.withAlpha(50),
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.storefront,
                          color: colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        store.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'A ${store.distanceKm.toStringAsFixed(2)} km de ti',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.pin_drop, color: Colors.deepOrange),
                        onPressed: () {
                          _controller.selectStore(store);
                          _mapController.move(
                            LatLng(
                              store.coordinates.latitude,
                              store.coordinates.longitude,
                            ),
                            16.0,
                          );
                        },
                      ),
                      onTap: () {
                        _controller.selectStore(store);
                        _showStoreModal(context, store);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStoreModal(BuildContext context, NearbyStore store) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.storefront),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Distancia: ${store.distanceKm.toStringAsFixed(2)} km',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Coordenadas: Lat ${store.coordinates.latitude.toStringAsFixed(4)}, Lng ${store.coordinates.longitude.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Comercio seleccionado: ${store.name}'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Ver Catálogo de Bebidas'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── WIDGETS DE MARCADORES ────────────────────────────────────────────────────

/// Marcador para la posición del usuario con halo pulsante
class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(60),
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Tú',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Marcador para tiendas con nombre y distancia
class _StoreMarker extends StatelessWidget {
  final NearbyStore store;
  final bool isSelected;

  const _StoreMarker({
    required this.store,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.red : Colors.deepOrange;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isSelected ? 2.5 : 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(80),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(Icons.storefront, color: color, size: 18),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(240),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            '${store.name.split(' ').first} · ${store.distanceKm.toStringAsFixed(1)}km',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gps_fixed, color: Colors.lightGreenAccent, size: 12),
          const SizedBox(width: 6),
          Text(
            'Lat: ${coordinates.latitude.toStringAsFixed(4)}, Lng: ${coordinates.longitude.toStringAsFixed(4)}',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
