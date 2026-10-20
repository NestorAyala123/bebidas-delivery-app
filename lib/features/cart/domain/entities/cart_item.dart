import '../../../pricing/domain/entities/quantity_pricing_tier.dart';
import '../../../products/domain/entities/product.dart';

/// Domain entity representing a product item within a shopping cart.
class CartItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final bool isReturnable;
  final double containerDeposit;
  final double basePrice;
  final List<QuantityPricingTier> quantityTiers;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.isReturnable = false,
    this.containerDeposit = 0.0,
    double? basePrice,
    this.quantityTiers = const [],
  })  : basePrice = basePrice ?? unitPrice,
        assert(quantity > 0, 'La cantidad debe ser mayor a 0'),
        assert(unitPrice >= 0.0, 'El precio unitario no puede ser negativo'),
        assert(
          containerDeposit >= 0.0,
          'El depósito del envase no puede ser negativo',
        );

  /// Factory constructor to build a [CartItem] directly from a [Product].
  /// Automatically resolves tier pricing according to [quantity].
  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    final effectivePrice = product.getUnitPriceForQuantity(quantity);
    final tiers = <QuantityPricingTier>[
      ...product.quantityTiers,
      ...product.priceRules
          .where((rule) => rule.isActive)
          .map(
            (rule) => QuantityPricingTier(
              minQuantity: rule.minQuantity,
              unitPrice: rule.unitPrice,
            ),
          ),
    ];

    return CartItem(
      productId: product.id,
      productName: product.name,
      basePrice: product.basePrice,
      unitPrice: effectivePrice,
      quantity: quantity,
      isReturnable: product.isReturnableContainer,
      containerDeposit: product.containerDepositPrice,
      quantityTiers: tiers,
    );
  }

  /// Subtotal calculated as unit price multiplied by quantity.
  double get subtotal => unitPrice * quantity;

  /// Total returnable container deposit if this item uses returnable packaging.
  double get totalContainerDeposit =>
      isReturnable ? containerDeposit * quantity : 0.0;

  /// Indicates if this item is currently receiving a discounted tier price.
  bool get hasTierDiscount => basePrice > unitPrice;

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
    double? basePrice,
    List<QuantityPricingTier>? quantityTiers,
  }) {
    final newQuantity = quantity ?? this.quantity;
    final newBasePrice = basePrice ?? this.basePrice;
    final newTiers = quantityTiers ?? this.quantityTiers;

    final effectivePrice = unitPrice ??
        (newTiers.isNotEmpty
            ? _resolveTierPrice(newBasePrice, newQuantity, newTiers)
            : this.unitPrice);

    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: effectivePrice,
      quantity: newQuantity,
      isReturnable: isReturnable ?? this.isReturnable,
      containerDeposit: containerDeposit ?? this.containerDeposit,
      basePrice: newBasePrice,
      quantityTiers: newTiers,
    );
  }

  static double _resolveTierPrice(
    double basePrice,
    int quantity,
    List<QuantityPricingTier> tiers,
  ) {
    if (tiers.isEmpty) return basePrice;
    final sorted = List<QuantityPricingTier>.from(tiers)
      ..sort((a, b) => b.minQuantity.compareTo(a.minQuantity));
    for (final tier in sorted) {
      if (quantity >= tier.minQuantity) {
        return tier.unitPrice;
      }
    }
    return basePrice;
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
          containerDeposit == other.containerDeposit &&
          basePrice == other.basePrice;

  @override
  int get hashCode => Object.hash(
        productId,
        productName,
        unitPrice,
        quantity,
        isReturnable,
        containerDeposit,
        basePrice,
      );

  @override
  String toString() {
    return 'CartItem('
        'productId: $productId, '
        'productName: $productName, '
        'unitPrice: \$$unitPrice, '
        'basePrice: \$$basePrice, '
        'quantity: $quantity, '
        'subtotal: \$$subtotal, '
        'isReturnable: $isReturnable, '
        'containerDeposit: \$$containerDeposit'
        ')';
  }
}
