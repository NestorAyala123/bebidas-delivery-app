class Store {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String address;
  final double? latitude;
  final double? longitude;
  final Map<String, String> openingHours;
  final String phone;
  final String? imageUrl;
  final bool isOpen;
  final bool hasOwnDelivery; // RN02: delivery propio
  final bool allowsExternalDelivery; // RN02: delivery externo
  final bool allowsPickup; // RN02: retiro en local

  const Store({
    required this.id,
    required this.name,
    required this.address,
    required this.isOpen,
    this.ownerId = '',
    this.description = '',
    this.latitude,
    this.longitude,
    this.openingHours = const {},
    this.phone = '',
    this.imageUrl,
    this.hasOwnDelivery = false,
    this.allowsExternalDelivery = true,
    this.allowsPickup = true,
  });

  bool canAcceptOrders() => isOpen;
}
