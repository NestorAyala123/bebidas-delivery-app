enum OrderPaymentMethod {
  cash,
  bankTransfer;

  String get displayName => switch (this) {
    OrderPaymentMethod.cash => 'Efectivo',
    OrderPaymentMethod.bankTransfer => 'Transferencia',
  };
}
