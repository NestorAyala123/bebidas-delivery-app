import 'geo_coordinates.dart';

/// Representa el destino y dirección de entrega seleccionado por el cliente.
/// Entidad de dominio 100% pura en Dart.
class DeliveryDestination {
  final String address;
  final String reference;
  final GeoCoordinates coordinates;
  final String receiverName;
  final String receiverPhone;

  const DeliveryDestination({
    required this.address,
    this.reference = '',
    required this.coordinates,
    this.receiverName = '',
    this.receiverPhone = '',
  });

  /// Dirección completa formateada con referencias para el repartidor o comercio.
  String get formattedAddress {
    if (reference.trim().isNotEmpty) {
      return '$address ($reference)';
    }
    return address;
  }

  /// Calcula la distancia aproximada en kilómetros hasta el comercio origen.
  double distanceTo(GeoCoordinates origin) {
    return coordinates.distanceToInKm(origin);
  }

  DeliveryDestination copyWith({
    String? address,
    String? reference,
    GeoCoordinates? coordinates,
    String? receiverName,
    String? receiverPhone,
  }) {
    return DeliveryDestination(
      address: address ?? this.address,
      reference: reference ?? this.reference,
      coordinates: coordinates ?? this.coordinates,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryDestination &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          coordinates == other.coordinates;

  @override
  int get hashCode => address.hashCode ^ coordinates.hashCode;

  @override
  String toString() =>
      'DeliveryDestination(address: $formattedAddress, coords: $coordinates)';
}
