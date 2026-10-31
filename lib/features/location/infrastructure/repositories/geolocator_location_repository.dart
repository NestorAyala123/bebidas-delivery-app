import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/geo_coordinates.dart';
import '../../domain/entities/nearby_store.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/obtener_ubicacion_actual_use_case.dart';

/// Implementación real del repositorio de ubicación usando el plugin geolocator.
class GeolocatorLocationRepository implements LocationRepository {
  /// Lista de comercios de prueba base para calcular distancias en base a la posición real.
  final List<NearbyStore> _seedStores;

  GeolocatorLocationRepository({List<NearbyStore>? seedStores})
      : _seedStores = seedStores ??
            const [
              NearbyStore(
                id: 'store-001',
                name: 'Licorera El Barril',
                coordinates:
                    GeoCoordinates(latitude: -0.9690, longitude: -80.7100),
                distanceKm: 0.0,
                address: 'Av. Flavio Reyes y Calle 24',
                isOpen: true,
                phone: '+593 99 223 3445',
                description: 'Vinos, whiskies importados y cervezas bien frías.',
                hasOwnDelivery: true,
                allowsExternalDelivery: true,
                allowsPickup: true,
                openingHours: '10:00 - 02:00',
              ),
              NearbyStore(
                id: 'store-002',
                name: 'Distribuidora La Copa',
                coordinates:
                    GeoCoordinates(latitude: -0.9650, longitude: -80.7050),
                distanceKm: 0.0,
                address: 'Calle 13 y Av. 24, Barrio Córdova',
                isOpen: true,
                phone: '+593 98 765 4321',
                description: 'Venta por mayor y menor, packs de cerveza artesanal.',
                hasOwnDelivery: false,
                allowsExternalDelivery: true,
                allowsPickup: true,
                openingHours: '09:00 - 23:00',
              ),
              NearbyStore(
                id: 'store-003',
                name: 'Mini Market Central',
                coordinates:
                    GeoCoordinates(latitude: -0.9720, longitude: -80.7130),
                distanceKm: 0.0,
                address: 'Av. 4 de Noviembre y Calle 114',
                isOpen: true,
                phone: '+593 99 112 2334',
                description: 'Snacks, hielo, gaseosas y licores nacionales.',
                hasOwnDelivery: false,
                allowsExternalDelivery: true,
                allowsPickup: true,
                openingHours: '08:00 - 00:00',
              ),
              NearbyStore(
                id: 'store-004',
                name: 'Bodega San Martín',
                coordinates:
                    GeoCoordinates(latitude: -0.9620, longitude: -80.7150),
                distanceKm: 0.0,
                address: 'Av. Malecón Jaime Chávez Gutiérrez',
                isOpen: false,
                phone: '+593 97 889 9001',
                description: 'Aguardientes, rones añejos y cajas para eventos.',
                hasOwnDelivery: true,
                allowsExternalDelivery: false,
                allowsPickup: true,
                openingHours: '14:00 - 03:00',
              ),
              NearbyStore(
                id: 'store-005',
                name: 'Licorería 24 Horas Express',
                coordinates:
                    GeoCoordinates(latitude: -0.9685, longitude: -80.7030),
                distanceKm: 0.0,
                address: 'Vía Barbasquillo, frente a Plaza del Sol',
                isOpen: true,
                phone: '+593 96 333 4455',
                description: 'Atención ininterrumpida las 24 horas todos los días.',
                hasOwnDelivery: true,
                allowsExternalDelivery: true,
                allowsPickup: true,
                openingHours: '24 Horas',
              ),
            ];

  @override
  Future<bool> checkAndRequestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<Result<GeoCoordinates, Failure>> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const FailureResult(
          LocationUnavailableFailure(
            'El servicio de GPS está desactivado. Actívalo en la configuración de tu dispositivo.',
          ),
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const FailureResult(
            PermissionFailure(
              'El permiso de ubicación fue denegado. Se requiere para encontrar comercios cercanos.',
            ),
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const FailureResult(
          PermissionPermanentlyDeniedFailure(
            'El permiso de ubicación fue denegado permanentemente. Habilítalo en los ajustes de la aplicación.',
          ),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return Success(
        GeoCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } on TimeoutException {
      return const FailureResult(
        LocationTimeoutFailure(
          'El GPS no respondió a tiempo. Verifica que estés en un lugar despejado o ingresa tu dirección manualmente.',
        ),
      );
    } on LocationServiceDisabledException {
      return const FailureResult(
        LocationUnavailableFailure(
          'El servicio de GPS está desactivado. Actívalo en la configuración de tu dispositivo.',
        ),
      );
    } on PermissionDeniedException {
      return const FailureResult(
        PermissionFailure(
          'El permiso de ubicación fue denegado. Se requiere para encontrar comercios cercanos.',
        ),
      );
    } catch (e) {
      return FailureResult(
        LocationUnavailableFailure(
          'No se pudo obtener la posición actual del dispositivo: $e',
        ),
      );
    }
  }

  @override
  Future<Result<List<NearbyStore>, Failure>> getNearbyStores({
    required GeoCoordinates origin,
    double radiusKm = 5.0,
  }) async {
    try {
      // Generamos comercios cercanos relativos al origen para garantizar
      // datos de prueba válidos donde sea que se encuentre el dispositivo.
      final baseStores = _generateNearbySeedStores(origin);

      final storesWithDistances = baseStores.map((store) {
        final distance = origin.distanceToInKm(store.coordinates);
        return store.copyWith(distanceKm: distance);
      }).toList();

      storesWithDistances.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      final withinRadius = storesWithDistances
          .where((store) => store.distanceKm <= radiusKm)
          .toList();

      return Success(withinRadius);
    } catch (e) {
      return FailureResult(
        ServerFailure('Error al calcular comercios cercanos: $e'),
      );
    }
  }

  /// Genera tiendas relativas al origen para que la demostración funcione
  /// tanto en Manta como en cualquier otra ciudad o coordenada donde se pruebe la app.
  List<NearbyStore> _generateNearbySeedStores(GeoCoordinates origin) {
    if (_seedStores.isNotEmpty) {
      final firstDist = origin.distanceToInKm(_seedStores.first.coordinates);
      if (firstDist < 25.0) {
        return _seedStores;
      }
    }
    return [
      NearbyStore(
        id: 'store-001',
        name: 'Licorera El Barril (Centro)',
        coordinates: GeoCoordinates(
          latitude: origin.latitude + 0.0025,
          longitude: origin.longitude + 0.0018,
        ),
        distanceKm: 0.0,
      ),
      NearbyStore(
        id: 'store-002',
        name: 'Distribuidora La Copa & Vinos',
        coordinates: GeoCoordinates(
          latitude: origin.latitude - 0.0035,
          longitude: origin.longitude - 0.0022,
        ),
        distanceKm: 0.0,
      ),
      NearbyStore(
        id: 'store-003',
        name: 'Mini Market & Cervezas 24H',
        coordinates: GeoCoordinates(
          latitude: origin.latitude + 0.0048,
          longitude: origin.longitude - 0.0040,
        ),
        distanceKm: 0.0,
      ),
      NearbyStore(
        id: 'store-004',
        name: 'Bodega San Martín Express',
        coordinates: GeoCoordinates(
          latitude: origin.latitude - 0.0060,
          longitude: origin.longitude + 0.0055,
        ),
        distanceKm: 0.0,
      ),
      NearbyStore(
        id: 'store-005',
        name: 'Super Licorería Premium',
        coordinates: GeoCoordinates(
          latitude: origin.latitude + 0.0012,
          longitude: origin.longitude - 0.0070,
        ),
        distanceKm: 0.0,
      ),
    ];
  }
}
