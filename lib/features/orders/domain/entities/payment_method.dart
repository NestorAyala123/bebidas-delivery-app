/// Métodos de pago registrados por el cliente al confirmar el pedido.
enum PaymentMethod {
  cash,
  transfer;

  static const PaymentMethod bankTransfer = PaymentMethod.transfer;

  String get label => switch (this) {
    PaymentMethod.cash => 'Efectivo',
    PaymentMethod.transfer => 'Transferencia bancaria',
  };

  String get displayName => switch (this) {
    PaymentMethod.cash => 'Efectivo',
    PaymentMethod.transfer => 'Transferencia',
  };

  String get description => switch (this) {
    PaymentMethod.cash => 'Paga al recibir el pedido',
    PaymentMethod.transfer => 'Transfiere antes de la entrega',
  };

  bool get isCash => this == PaymentMethod.cash;
  bool get isTransfer => this == PaymentMethod.transfer;
}

extension NullablePaymentMethodExt on PaymentMethod? {
  String get displayName => this?.displayName ?? 'Efectivo';
  String get label => this?.label ?? 'No especificado';
}
