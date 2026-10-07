import 'geo_coordinates.dart';

/// Represents a store near the user's location.
/// Domain entity — no external package dependencies.
class NearbyStore {
  final String id;
  final String name;
  final GeoCoordinates coordinates;

  /// Approximate distance from the user's current position in kilometers.
  /// Populated by the use case after computing the Haversine distance.
  final double distanceKm;

  const NearbyStore({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.distanceKm,
  });

  NearbyStore copyWith({
    String? id,
    String? name,
    GeoCoordinates? coordinates,
    double? distanceKm,
  }) {
    return NearbyStore(
      id: id ?? this.id,
      name: name ?? this.name,
      coordinates: coordinates ?? this.coordinates,
      distanceKm: distanceKm ?? this.distanceKm,
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
      'NearbyStore(id: $id, name: $name, distanceKm: ${distanceKm.toStringAsFixed(2)} km)';
}
