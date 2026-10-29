import 'geo_coordinates.dart';

/// Representa un comercio real cercano a la ubicación del usuario.
/// Entidad de dominio pura — sin dependencias externas de frameworks.
class NearbyStore {
  final String id;
  final String name;
  final GeoCoordinates coordinates;

  /// Distancia aproximada desde la posición del usuario en kilómetros.
  /// Calculada mediante la fórmula Haversine.
  final double distanceKm;

  /// Dirección física real del comercio.
  final String address;

  /// Indica si el comercio se encuentra abierto y recibiendo pedidos.
  final bool isOpen;

  /// Número de teléfono o contacto del comercio.
  final String phone;

  /// Descripción o especialidad del comercio (ej. "Licorería 24h, licores importados").
  final String description;

  /// RN02: Modalidades de entrega soportadas por el comercio.
  final bool hasOwnDelivery;
  final bool allowsExternalDelivery;
  final bool allowsPickup;

  /// Horario de atención referencial.
  final String openingHours;

  const NearbyStore({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.distanceKm,
    this.address = 'Dirección disponible en local',
    this.isOpen = true,
    this.phone = '',
    this.description = '',
    this.hasOwnDelivery = false,
    this.allowsExternalDelivery = true,
    this.allowsPickup = true,
    this.openingHours = '10:00 - 02:00',
  });

  /// Formato legible de la distancia aproximada (metros si < 1 km, kilómetros si >= 1 km).
  String get formattedDistance {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }
    return '${distanceKm.toStringAsFixed(2)} km';
  }

  NearbyStore copyWith({
    String? id,
    String? name,
    GeoCoordinates? coordinates,
    double? distanceKm,
    String? address,
    bool? isOpen,
    String? phone,
    String? description,
    bool? hasOwnDelivery,
    bool? allowsExternalDelivery,
    bool? allowsPickup,
    String? openingHours,
  }) {
    return NearbyStore(
      id: id ?? this.id,
      name: name ?? this.name,
      coordinates: coordinates ?? this.coordinates,
      distanceKm: distanceKm ?? this.distanceKm,
      address: address ?? this.address,
      isOpen: isOpen ?? this.isOpen,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      hasOwnDelivery: hasOwnDelivery ?? this.hasOwnDelivery,
      allowsExternalDelivery:
          allowsExternalDelivery ?? this.allowsExternalDelivery,
      allowsPickup: allowsPickup ?? this.allowsPickup,
      openingHours: openingHours ?? this.openingHours,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbyStore &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NearbyStore(id: $id, name: $name, distance: $formattedDistance, open: $isOpen)';
}
