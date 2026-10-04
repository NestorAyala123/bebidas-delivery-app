import 'event_service.dart';

/// FichaServicio extends [EventService] with extra fields needed for
/// the event-services module: contact info, location label and the IDs
/// required by the Chat module contract.
///
/// Rule: no Flutter or Firebase imports — pure domain.
class FichaServicio extends EventService {
  /// Human-readable address or location description (e.g. "Manta, Manabí").
  final String locationLabel;

  /// WhatsApp or phone number shown in the card.
  final String contactPhone;

  /// ISO-8601 date string of the service listing creation.
  final String createdAt;

  const FichaServicio({
    required super.id,
    required super.providerId,
    required super.title,
    required super.description,
    required super.serviceType,
    required super.estimatedPrice,
    super.isAvailable,
    required this.locationLabel,
    required this.contactPhone,
    required this.createdAt,
  });

  FichaServicio copyWith({
    String? id,
    String? providerId,
    String? title,
    String? description,
    EventServiceType? serviceType,
    double? estimatedPrice,
    bool? isAvailable,
    String? locationLabel,
    String? contactPhone,
    String? createdAt,
  }) {
    return FichaServicio(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      description: description ?? this.description,
      serviceType: serviceType ?? this.serviceType,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      isAvailable: isAvailable ?? this.isAvailable,
      locationLabel: locationLabel ?? this.locationLabel,
      contactPhone: contactPhone ?? this.contactPhone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FichaServicio &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FichaServicio(id: $id, title: $title, type: $serviceType)';
}
