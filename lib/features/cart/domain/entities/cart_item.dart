class CartItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final bool isReturnable;
  final double containerDeposit;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.isReturnable = false,
    this.containerDeposit = 0.0,
  }) : assert(quantity > 0, 'La cantidad debe ser mayor a 0');

  double get subtotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      isReturnable: isReturnable,
      containerDeposit: containerDeposit,
    );
  }
}
