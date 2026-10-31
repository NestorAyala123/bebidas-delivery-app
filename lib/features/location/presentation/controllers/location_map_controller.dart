import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/geo_coordinates.dart';
import '../../domain/entities/nearby_store.dart';
import '../../domain/usecases/obtener_comercios_cercanos_use_case.dart';
import '../../domain/usecases/obtener_ubicacion_actual_use_case.dart';

enum LocationStatus {
  initial,
  loading,
  success,
  permissionDenied,
  serviceDisabled,
  error,
}

class LocationMapController extends ChangeNotifier {
  final ObtenerUbicacionActualUseCase obtenerUbicacionActualUseCase;
  final ObtenerComerciosCercanosUseCase obtenerComerciosCercanosUseCase;

  LocationStatus _status = LocationStatus.initial;
  GeoCoordinates? _userPosition;
  List<NearbyStore> _nearbyStores = [];
  NearbyStore? _selectedStore;
  String? _errorMessage;
  bool _isSimulatedMode = false;
  double _searchRadiusKm = 5.0;
  String _searchQuery = '';

  LocationMapController({
    required this.obtenerUbicacionActualUseCase,
    required this.obtenerComerciosCercanosUseCase,
  });

  LocationStatus get status => _status;
  GeoCoordinates? get userPosition => _userPosition;
  List<NearbyStore> get nearbyStores => _nearbyStores;
  NearbyStore? get selectedStore => _selectedStore;
  String? get errorMessage => _errorMessage;
  bool get isSimulatedMode => _isSimulatedMode;
  double get searchRadiusKm => _searchRadiusKm;
  String get searchQuery => _searchQuery;

  /// Retorna los comercios filtrados por texto de búsqueda.
  List<NearbyStore> get filteredStores {
    if (_searchQuery.trim().isEmpty) {
      return _nearbyStores;
    }
    final q = _searchQuery.toLowerCase().trim();
    return _nearbyStores.where((store) {
      return store.name.toLowerCase().contains(q) ||
          store.address.toLowerCase().contains(q) ||
          store.description.toLowerCase().contains(q);
    }).toList();
  }

  bool get isLoading => _status == LocationStatus.loading;
  bool get isPermissionDenied => _status == LocationStatus.permissionDenied;
  bool get isSuccess => _status == LocationStatus.success;

  /// Carga la ubicación actual solicitando los permisos GPS
  Future<void> loadCurrentLocation() async {
    _status = LocationStatus.loading;
    _errorMessage = null;
    _isSimulatedMode = false;
    notifyListeners();

    final result = await obtenerUbicacionActualUseCase();

    switch (result) {
      case Success(:final data):
        _userPosition = data;
        await _fetchNearbyStores(data);
        _status = LocationStatus.success;
      case FailureResult(:final failure):
        if (failure is PermissionFailure) {
          _status = LocationStatus.permissionDenied;
          _errorMessage = failure.message;
        } else if (failure is LocationUnavailableFailure) {
          _status = LocationStatus.serviceDisabled;
          _errorMessage = failure.message;
        } else {
          _status = LocationStatus.error;
          _errorMessage = failure.message;
        }
    }

    notifyListeners();
  }

  /// Carga comercios cercanos usando las coordenadas proporcionadas y el radio actual
  Future<void> _fetchNearbyStores(GeoCoordinates origin) async {
    final storesResult = await obtenerComerciosCercanosUseCase(
      origin: origin,
      radiusKm: _searchRadiusKm,
    );
    final data = storesResult.dataOrNull;
    if (data != null) {
      _nearbyStores = data;
    }
  }

  /// Cambia el radio de búsqueda de comercios y recalcula la lista
  Future<void> updateSearchRadius(double radiusKm) async {
    _searchRadiusKm = radiusKm;
    if (_userPosition != null) {
      await _fetchNearbyStores(_userPosition!);
      notifyListeners();
    }
  }

  /// Aplica filtro por texto (nombre, dirección o descripción)
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Reintenta la solicitud de permisos y obtención de posición
  Future<void> retryPermission() async {
    await loadCurrentLocation();
  }

  /// Abre la configuración de la app en el dispositivo
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {
      // Ignorar si no está disponible en la plataforma
    }
  }

  /// Activa el modo de prueba con datos simulados (para pruebas o si no hay GPS disponible)
  Future<void> useSimulatedLocation() async {
    _status = LocationStatus.loading;
    notifyListeners();

    // Coordenadas simuladas en Manta, Manabí
    const mockCoord = GeoCoordinates(
      latitude: -0.9676534,
      longitude: -80.7088841,
    );

    _userPosition = mockCoord;
    _isSimulatedMode = true;
    _errorMessage = null;

    await _fetchNearbyStores(mockCoord);
    _status = LocationStatus.success;
    notifyListeners();
  }

  /// Simula la denegación de permisos para fines de demostración del PR / docente
  void simulatePermissionDenied() {
    _status = LocationStatus.permissionDenied;
    _errorMessage =
        'Permiso de ubicación denegado por el usuario. La app no puede consultar el GPS.';
    _userPosition = null;
    _nearbyStores = [];
    _selectedStore = null;
    notifyListeners();
  }

  /// Selecciona o deselecciona una tienda
  void selectStore(NearbyStore? store) {
    _selectedStore = store;
    notifyListeners();
  }
}
