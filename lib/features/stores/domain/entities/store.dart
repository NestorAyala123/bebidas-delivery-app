class Store {
  final String id;
  final String name;
  final String address;
  final bool isOpen;
  final bool hasOwnDelivery; // RN02: delivery propio
  final bool allowsExternalDelivery; // RN02: delivery externo
  final bool allowsPickup; // RN02: retiro en local

  const Store({
    required this.id,
    required this.name,
    required this.address,
    required this.isOpen,
    this.hasOwnDelivery = false,
    this.allowsExternalDelivery = true,
    this.allowsPickup = true,
  });

  bool canAcceptOrders() => isOpen;
}
