/// Domain entity representing a product item within a shopping cart.
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
  })  : assert(quantity > 0, 'La cantidad debe ser mayor a 0'),
        assert(unitPrice >= 0.0, 'El precio unitario no puede ser negativo'),
        assert(
          containerDeposit >= 0.0,
          'El depósito del envase no puede ser negativo',
        );

  /// Subtotal calculated as unit price multiplied by quantity.
  double get subtotal => unitPrice * quantity;

  /// Total returnable container deposit if this item uses returnable packaging.
  double get totalContainerDeposit =>
      isReturnable ? containerDeposit * quantity : 0.0;

  /// Returns a new [CartItem] with incremented quantity.
  CartItem increment([int amount = 1]) {
    assert(amount > 0, 'El incremento debe ser mayor a 0');
    return copyWith(quantity: quantity + amount);
  }

  /// Returns a new [CartItem] with decremented quantity.
  /// Throws [AssertionError] if new quantity would be <= 0.
  CartItem decrement([int amount = 1]) {
    assert(amount > 0, 'El decremento debe ser mayor a 0');
    final newQuantity = quantity - amount;
    assert(newQuantity > 0, 'La cantidad resultante debe ser mayor a 0');
    return copyWith(quantity: newQuantity);
  }

  CartItem copyWith({
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    bool? isReturnable,
    double? containerDeposit,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      isReturnable: isReturnable ?? this.isReturnable,
      containerDeposit: containerDeposit ?? this.containerDeposit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          productName == other.productName &&
          unitPrice == other.unitPrice &&
          quantity == other.quantity &&
          isReturnable == other.isReturnable &&
          containerDeposit == other.containerDeposit;

  @override
  int get hashCode => Object.hash(
        productId,
        productName,
        unitPrice,
        quantity,
        isReturnable,
        containerDeposit,
      );

  @override
  String toString() {
    return 'CartItem('
        'productId: $productId, '
        'productName: $productName, '
        'unitPrice: \$$unitPrice, '
        'quantity: $quantity, '
        'subtotal: \$$subtotal, '
        'isReturnable: $isReturnable, '
        'containerDeposit: \$$containerDeposit'
        ')';
  }
}
