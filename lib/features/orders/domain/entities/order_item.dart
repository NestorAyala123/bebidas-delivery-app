/// Order item containing frozen price at the moment of order creation (RN08)
class OrderItem {
  final String productId;
  final String productName;
  final double frozenUnitPrice; // RN08: histórico inalterable
  final int quantity;
  final bool isReturnable;
  final double containerDepositPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.frozenUnitPrice,
    required this.quantity,
    this.isReturnable = false,
    this.containerDepositPrice = 0.0,
  }) : assert(quantity > 0, 'La cantidad debe ser mayor a 0'),
       assert(frozenUnitPrice >= 0, 'El precio no puede ser negativo');

  double get subtotal => frozenUnitPrice * quantity;
}
