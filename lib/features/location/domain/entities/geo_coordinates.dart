import 'dart:math' as math;

/// Domain value object for geographic coordinates.
/// Free of external packages (independent of geolocator or flutter_map).
class GeoCoordinates {
  final double latitude;
  final double longitude;

  const GeoCoordinates({required this.latitude, required this.longitude})
    : assert(latitude >= -90.0 && latitude <= 90.0, 'Latitud inválida'),
      assert(longitude >= -180.0 && longitude <= 180.0, 'Longitud inválida');

  /// Calculates distance to another coordinate in Kilometers using Haversine formula
  double distanceToInKm(GeoCoordinates other) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degToRad(other.latitude - latitude);
    final double dLon = _degToRad(other.longitude - longitude);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(latitude)) *
            math.cos(_degToRad(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}
