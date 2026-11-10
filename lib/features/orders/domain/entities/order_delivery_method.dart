enum OrderDeliveryMethod {
  pickup,
  storeDelivery,
  externalDelivery;

  bool get isExternal => this == externalDelivery;
}
