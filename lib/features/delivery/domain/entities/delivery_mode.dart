/// Delivery modalities according to Business Rule RN02
enum DeliveryMode {
  ownDelivery, // Delivery propio del establecimiento
  externalDriver, // Repartidor externo mediante negociación en la app
  pickupAtStore; // Retiro en el local por el cliente

  bool get requiresExternalDriver => this == DeliveryMode.externalDriver;
  bool get isPickup => this == DeliveryMode.pickupAtStore;
  bool get isOwnDelivery => this == DeliveryMode.ownDelivery;
}
