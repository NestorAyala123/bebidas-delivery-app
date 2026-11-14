/// Métodos de pago registrados por el cliente al confirmar el pedido.
enum PaymentMethod {
  cash,
  transfer;

  String get label => switch (this) {
    PaymentMethod.cash => 'Efectivo',
    PaymentMethod.transfer => 'Transferencia bancaria',
  };

  String get description => switch (this) {
    PaymentMethod.cash => 'Paga al recibir el pedido',
    PaymentMethod.transfer => 'Transfiere antes de la entrega',
  };

  bool get isCash => this == PaymentMethod.cash;
  bool get isTransfer => this == PaymentMethod.transfer;
}
