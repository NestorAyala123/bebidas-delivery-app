import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/delivery_destination.dart';
import '../../domain/entities/geo_coordinates.dart';
import '../../domain/usecases/calcular_distancia_entrega_use_case.dart';
import '../../domain/usecases/obtener_ubicacion_actual_use_case.dart';

/// Pantalla para que el cliente seleccione o ajuste su dirección y punto de entrega.
///
/// Implementa:
/// - Fijación de coordenadas en el mapa tocando o usando el GPS del dispositivo.
/// - Entrada de dirección física y referencias domiciliarias obligatorias para el repartidor.
/// - Cálculo dinámico de la distancia aproximada hacia el comercio origen.
/// - Estimación de tiempo de traslado y tarifa referencial de delivery.
class SeleccionarDestinoEntregaPage extends StatefulWidget {
  final GeoCoordinates? originStoreCoordinates;
  final String? storeName;
  final DeliveryDestination? initialDestination;

  const SeleccionarDestinoEntregaPage({
    super.key,
    this.originStoreCoordinates,
    this.storeName,
    this.initialDestination,
  });

  @override
  State<SeleccionarDestinoEntregaPage> createState() =>
      _SeleccionarDestinoEntregaPageState();
}

class _SeleccionarDestinoEntregaPageState
    extends State<SeleccionarDestinoEntregaPage> {
  static const LatLng _defaultLatLng = LatLng(-0.9676534, -80.7088841);

  /// Direcciones frecuentes usadas para el autocompletado local.
  static const List<String> _addressSuggestions = [
    'Av. Flavio Reyes, Sector El Murciélago',
    'Av. 4 de Noviembre, Manta',
    'Av. Malecón Jaime Chávez Gutiérrez',
    'Vía Barbasquillo, Manta',
    'Calle 13 y Av. 24, Barrio Córdova',
    'Av. Universitaria, Manta',
    'Barrio Santa Martha, Manta',
  ];

  late final MapController _mapController;
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _referenceController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _addressFocusNode = FocusNode();

  // Coordenadas iniciales por defecto (Manta, Manabí)
  LatLng _selectedLatLng = _defaultLatLng;
  DeliveryEstimate? _deliveryEstimate;
  bool _isLoadingGps = false;
  Failure? _gpsFailure;

  final CalcularDistanciaEntregaUseCase _calcularDistanciaUseCase =
      const CalcularDistanciaEntregaUseCase();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.initialDestination != null) {
      final dest = widget.initialDestination!;
      _selectedLatLng = LatLng(
        dest.coordinates.latitude,
        dest.coordinates.longitude,
      );
      _addressController.text = dest.address;
      _referenceController.text = dest.reference;
      _receiverNameController.text = dest.receiverName;
      _receiverPhoneController.text = dest.receiverPhone;
    } else {
      _addressController.text = 'Av. Flavio Reyes, Sector El Murciélago';
      _referenceController.text = 'Casa de 2 pisos color blanco, portón negro';
    }

    _recalculateEstimate();
  }

  void _recalculateEstimate() {
    if (widget.originStoreCoordinates != null) {
      final origin = widget.originStoreCoordinates!;
      final dest = GeoCoordinates(
        latitude: _selectedLatLng.latitude,
        longitude: _selectedLatLng.longitude,
      );
      final res = _calcularDistanciaUseCase(origin: origin, destination: dest);
      setState(() {
        _deliveryEstimate = res.dataOrNull;
      });
    }
  }

  Future<void> _useCurrentGpsLocation() async {
    setState(() {
      _isLoadingGps = true;
      _gpsFailure = null;
    });

    try {
      final useCase =
          ServiceLocator.instance.isRegistered<ObtenerUbicacionActualUseCase>()
          ? ServiceLocator.instance.get<ObtenerUbicacionActualUseCase>()
          : null;

      if (useCase == null) {
        setState(() {
          _gpsFailure = const ValidationFailure(
            'El servicio de ubicación no está disponible. Puedes ingresar la dirección manualmente.',
          );
        });
        return;
      }

      final result = await useCase();

      switch (result) {
        case Success(:final data):
          final newLatLng = LatLng(data.latitude, data.longitude);
          setState(() {
            _selectedLatLng = newLatLng;
            _gpsFailure = null;
          });
          try {
            _mapController.move(newLatLng, 16.0);
          } catch (_) {
            // El mapa aún no está montado; las coordenadas ya quedaron fijadas.
          }
          _recalculateEstimate();
        case FailureResult(:final failure):
          setState(() => _gpsFailure = failure);
      }
    } catch (e) {
      setState(() {
        _gpsFailure = LocationUnavailableFailure(
          'No se pudo obtener la ubicación actual: $e',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingGps = false);
      }
    }
  }

  /// Usa coordenadas de prueba para no bloquear el flujo de entrega.
  void _useTestCoordinates() {
    setState(() {
      _selectedLatLng = _defaultLatLng;
      _gpsFailure = null;
    });
    try {
      _mapController.move(_defaultLatLng, 15.5);
    } catch (_) {
      // Ignorar si el mapa aún no está listo.
    }
    _recalculateEstimate();
  }

  Future<void> _openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {
      // Plataforma sin soporte para ajustes.
    }
  }

  Future<void> _openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {
      // Plataforma sin soporte para ajustes.
    }
  }

  void _focusManualAddress() {
    _addressFocusNode.requestFocus();
    setState(() => _gpsFailure = null);
  }

  /// Mueve el pin de destino y recalcula la tarifa referencial.
  void _setSelectedPoint(LatLng point) {
    setState(() {
      _selectedLatLng = point;
      _gpsFailure = null;
    });
    _recalculateEstimate();
  }

  /// Banner accionable según el tipo de error de GPS/permiso.
  Widget _buildGpsErrorBanner(BuildContext context) {
    final failure = _gpsFailure!;
    final isPermanent = failure is PermissionPermanentlyDeniedFailure;
    final isTimeout = failure is LocationTimeoutFailure;
    final isServiceDisabled =
        failure is LocationUnavailableFailure && !isTimeout;
    final isPermissionDenied = failure is PermissionFailure && !isPermanent;

    final IconData icon;
    final String title;
    final Color color;

    if (isPermanent) {
      icon = Icons.block;
      title = 'Permiso denegado permanentemente';
      color = Colors.deepOrange;
    } else if (isTimeout) {
      icon = Icons.gps_fixed;
      title = 'Sin señal GPS';
      color = Colors.orange;
    } else if (isServiceDisabled) {
      icon = Icons.gps_off;
      title = 'GPS desactivado';
      color = Colors.orange;
    } else if (isPermissionDenied) {
      icon = Icons.location_off;
      title = 'Permiso de ubicación denegado';
      color = Colors.red;
    } else {
      icon = Icons.error_outline;
      title = 'No se pudo obtener tu ubicación';
      color = Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            failure.message,
            style: const TextStyle(fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (isPermanent)
                OutlinedButton.icon(
                  onPressed: _openAppSettings,
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Abrir ajustes de la app'),
                )
              else if (isServiceDisabled)
                OutlinedButton.icon(
                  onPressed: _openLocationSettings,
                  icon: const Icon(Icons.settings_suggest, size: 16),
                  label: const Text('Activar GPS'),
                )
              else
                OutlinedButton.icon(
                  onPressed: _useCurrentGpsLocation,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reintentar'),
                ),
              if (!isPermanent)
                TextButton.icon(
                  onPressed: _useTestCoordinates,
                  icon: const Icon(Icons.science_outlined, size: 16),
                  label: const Text('Coordenadas de prueba'),
                ),
              if (isTimeout)
                TextButton.icon(
                  onPressed: _focusManualAddress,
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                  label: const Text('Dirección manual'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDestination() {
    if (!_formKey.currentState!.validate()) return;

    final destination = DeliveryDestination(
      address: _addressController.text.trim(),
      reference: _referenceController.text.trim(),
      coordinates: GeoCoordinates(
        latitude: _selectedLatLng.latitude,
        longitude: _selectedLatLng.longitude,
      ),
      receiverName: _receiverNameController.text.trim(),
      receiverPhone: _receiverPhoneController.text.trim(),
    );

    Navigator.pop(context, destination);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _referenceController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _addressFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dirección y Punto de Entrega'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Mi ubicación actual',
            onPressed: _isLoadingGps ? null : _useCurrentGpsLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Mapa interactivo para fijar el destino ─────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLatLng,
                    initialZoom: 15.5,
                    onTap: (tapPosition, point) {
                      _setSelectedPoint(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bebidas_delivery_app',
                    ),
                    MarkerLayer(
                      markers: [
                        // Marcador de tienda si existe origen
                        if (widget.originStoreCoordinates != null)
                          Marker(
                            point: LatLng(
                              widget.originStoreCoordinates!.latitude,
                              widget.originStoreCoordinates!.longitude,
                            ),
                            width: 60,
                            height: 60,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.storefront,
                                  color: Colors.deepOrange,
                                  size: 28,
                                ),
                                Text(
                                  'Tienda',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Marcador del destino seleccionado (arrastrable)
                        Marker(
                          point: _selectedLatLng,
                          width: 90,
                          height: 90,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) {
                              try {
                                final camera = _mapController.camera;
                                final currentScreen = camera
                                    .latLngToScreenOffset(_selectedLatLng);
                                final nextPoint = camera.screenOffsetToLatLng(
                                  currentScreen + details.delta,
                                );
                                _setSelectedPoint(nextPoint);
                              } catch (_) {
                                // Ignorar si el mapa aún no está listo.
                              }
                            },
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 36,
                                ),
                                Text(
                                  'Arrastra o toca',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    backgroundColor: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Indicador para tocar y mover el pin
                Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(200),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, color: Colors.amber, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Toca en el mapa para ajustar el punto exacto',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tarjeta de estimación si hay tienda seleccionada
                if (_deliveryEstimate != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.two_wheeler,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Distancia: ${_deliveryEstimate!.formattedDistance}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Tiempo aprox: ~${_deliveryEstimate!.estimatedMinutes} mins',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              'Tarifa ref: \$${_deliveryEstimate!.suggestedFee.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Formulario de datos de entrega ─────────────────────────────────
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_gpsFailure != null) ...[
                      _buildGpsErrorBanner(context),
                      const SizedBox(height: 12),
                    ],
                    Autocomplete<String>(
                      textEditingController: _addressController,
                      focusNode: _addressFocusNode,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text
                            .trim()
                            .toLowerCase();
                        if (query.length < 3) {
                          return const Iterable<String>.empty();
                        }
                        return _addressSuggestions.where(
                          (address) => address.toLowerCase().contains(query),
                        );
                      },
                      onSelected: (value) {
                        _addressController.text = value;
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => onFieldSubmitted(),
                              decoration: InputDecoration(
                                labelText: 'Dirección de Entrega *',
                                hintText: 'Calle principal y número de casa',
                                helperText: 'Escribe al menos 3 letras para ver sugerencias',
                                prefixIcon: const Icon(Icons.home_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().length < 5) {
                                  return 'Ingresa una dirección válida de al menos 5 caracteres';
                                }
                                return null;
                              },
                            );
                          },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _referenceController,
                      decoration: InputDecoration(
                        labelText: 'Referencia domiciliaria *',
                        hintText:
                            'Ej. Frente al parque, casa blanca de 2 pisos',
                        prefixIcon: const Icon(Icons.info_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Ingresa una referencia para facilitar la llegada del repartidor';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _receiverNameController,
                            decoration: InputDecoration(
                              labelText: 'Quién recibe (Opcional)',
                              hintText: 'Nombre de contacto',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _receiverPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Teléfono contacto',
                              hintText: '0991234567',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (val) {
                              final phone = (val ?? '').trim();
                              if (phone.isEmpty) return null;
                              final digits = phone.replaceAll(
                                RegExp(r'\D'),
                                '',
                              );
                              if (digits.length < 7) {
                                return 'Teléfono inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _confirmDestination,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'Confirmar Dirección y Destino',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
