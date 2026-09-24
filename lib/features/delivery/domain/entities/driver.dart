import 'delivery_request.dart';
import 'delivery_status.dart';
import 'driver_status.dart';

/// Driver domain entity representing a delivery person.
/// 100% pure Dart, independent of Flutter and Firebase.
class Driver {
  final String id;
  final String name;
  final String? phoneNumber;
  final DriverStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Driver({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.status = DriverStatus.offline,
    required this.createdAt,
    this.updatedAt,
  }) : assert(
         id.trim().isNotEmpty,
         'El id del repartidor no puede estar vacío',
       ),
       assert(
         name.trim().isNotEmpty,
         'El nombre del repartidor no puede estar vacío',
       );

  /// RN02: Indicates if the driver is currently able to receive and accept new delivery requests.
  bool get canAcceptDeliveries => status.isAvailable;

  /// RN02: Evaluates if the driver can take a specific delivery request.
  /// Driver must be available and the request must be in pendingOffer status.
  bool canTakeDeliveryRequest(DeliveryRequest request) {
    return canAcceptDeliveries && request.status == DeliveryStatus.pendingOffer;
  }

  /// Returns a copy of the driver with an updated operational status.
  Driver copyWithStatus(DriverStatus newStatus) {
    return Driver(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      status: newStatus,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Driver copyWith({
    String? name,
    String? phoneNumber,
    DriverStatus? status,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
