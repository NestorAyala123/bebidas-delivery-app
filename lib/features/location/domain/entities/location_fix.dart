import 'geo_coordinates.dart';

/// Precisión de una lectura GPS.
enum LocationPrecision {
  high,
  medium,
  low;

  String get label => switch (this) {
    LocationPrecision.high => 'Alta',
    LocationPrecision.medium => 'Media',
    LocationPrecision.low => 'Baja',
  };
}

/// Lectura de ubicación con su margen de error aproximado.
class LocationFix {
  final GeoCoordinates coordinates;
  final double accuracyMeters;
  final bool isSimulated;

  const LocationFix({
    required this.coordinates,
    this.accuracyMeters = 0,
    this.isSimulated = false,
  }) : assert(accuracyMeters >= 0, 'La precisión no puede ser negativa');

  /// Lecturas por encima de 150 m se consideran aproximadas.
  bool get isApproximate => isSimulated || accuracyMeters > 150;

  LocationPrecision get precision {
    if (isSimulated) return LocationPrecision.medium;
    if (accuracyMeters <= 50) return LocationPrecision.high;
    if (accuracyMeters <= 150) return LocationPrecision.medium;
    return LocationPrecision.low;
  }

  String get accuracyLabel {
    if (isSimulated) return 'Ubicación simulada (±150 m)';
    if (accuracyMeters <= 0) return 'Precisión no reportada por el GPS';
    return 'Precisión aproximada ±${accuracyMeters.round()} m';
  }

  String get formattedPrecision =>
      '${precision.label}${isApproximate ? ' · aproximada' : ''}';

  LocationFix copyWith({
    GeoCoordinates? coordinates,
    double? accuracyMeters,
    bool? isSimulated,
  }) {
    return LocationFix(
      coordinates: coordinates ?? this.coordinates,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }
}
