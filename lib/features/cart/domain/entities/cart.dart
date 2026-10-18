import '../../../../core/errors/exceptions.dart';
import '../exceptions/cart_exceptions.dart';
import 'cart_calculation.dart';
import 'cart_item.dart';

/// Cart domain entity enforcing RN07 (Single Store constraint),
/// quantity operations, and calculation structure.
class Cart {
  final String? storeId; // RN07: Un solo establecimiento por pedido
  final List<CartItem> items;

  const Cart({this.storeId, this.items = const []});

  /// True if the cart contains no items.
  bool get isEmpty => items.isEmpty;

  /// True if the cart contains at least one item.
  bool get isNotEmpty => items.isNotEmpty;

  /// Count of distinct product types in the cart.
  int get uniqueProductCount => items.length;

  /// Total sum of all individual item quantities.
  int get totalItemCount => items.fold(0, (acc, item) => acc + item.quantity);

  /// Total number of returnable containers required by the items in the cart (RN05).
  int get totalReturnableContainers => items
      .where((item) => item.isReturnable)
      .fold(0, (acc, item) => acc + item.quantity);

  /// Gross items subtotal before missing container fees, delivery, or discounts.
  double get subtotal => items.fold(0.0, (acc, item) => acc + item.subtotal);

  /// Checks whether an item from [targetStoreId] is allowed to be added (RN07).
  bool canAddItemFromStore(String targetStoreId) {
    final cleanId = targetStoreId.trim();
    if (cleanId.isEmpty) return false;
    if (storeId == null || items.isEmpty) return true;
    return storeId == cleanId;
  }

  /// Adds an item to the cart.
  /// Throws [SingleStoreViolationException] if [targetStoreId] differs from current [storeId] (RN07).
  Cart addItem({required String targetStoreId, required CartItem item}) {
    final cleanStoreId = targetStoreId.trim();
    if (cleanStoreId.isEmpty) {
      throw const DomainException(
        'El identificador del comercio es obligatorio.',
      );
    }

    if (storeId != null && storeId != cleanStoreId && items.isNotEmpty) {
      throw const SingleStoreViolationException();
    }

    final existingIndex = items.indexWhere(
      (i) => i.productId == item.productId,
    );
    final List<CartItem> updated = List.from(items);

    if (existingIndex >= 0) {
      final current = updated[existingIndex];
      updated[existingIndex] = current.copyWith(
        quantity: current.quantity + item.quantity,
      );
    } else {
      updated.add(item);
    }

    return Cart(storeId: cleanStoreId, items: List.unmodifiable(updated));
  }

  /// Replaces the current cart content with a single new item from a different store.
  /// Useful when the user confirms they want to switch stores and discard previous items.
  Cart replaceStoreAndSetItem({
    required String targetStoreId,
    required CartItem item,
  }) {
    final cleanStoreId = targetStoreId.trim();
    if (cleanStoreId.isEmpty) {
      throw const DomainException(
        'El identificador del comercio es obligatorio.',
      );
    }
    return Cart(storeId: cleanStoreId, items: List.unmodifiable([item]));
  }

  /// Increments quantity of an existing item in the cart.
  /// Throws [CartItemNotFoundException] if item is not found.
  /// Throws [InvalidCartQuantityException] if [amount] is <= 0.
  Cart incrementQuantity(String productId, [int amount = 1]) {
    if (amount <= 0) {
      throw const InvalidCartQuantityException(
        'El incremento de cantidad debe ser mayor a 0.',
      );
    }
    final existingIndex = items.indexWhere((i) => i.productId == productId);
    if (existingIndex < 0) {
      throw const CartItemNotFoundException();
    }
    final current = items[existingIndex];
    return updateQuantity(productId, current.quantity + amount);
  }

  /// Decrements quantity of an existing item in the cart.
  /// If the resulting quantity is <= 0, the item is removed.
  /// Throws [CartItemNotFoundException] if item is not found.
  /// Throws [InvalidCartQuantityException] if [amount] is <= 0.
  Cart decrementQuantity(String productId, [int amount = 1]) {
    if (amount <= 0) {
      throw const InvalidCartQuantityException(
        'El decremento de cantidad debe ser mayor a 0.',
      );
    }
    final existingIndex = items.indexWhere((i) => i.productId == productId);
    if (existingIndex < 0) {
      throw const CartItemNotFoundException();
    }
    final current = items[existingIndex];
    return updateQuantity(productId, current.quantity - amount);
  }

  /// Updates quantity for a specific product. If [newQuantity] <= 0, the item is removed.
  /// If the cart becomes empty, [storeId] is reset to null.
  Cart updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      return removeItem(productId);
    }
    final updated = items.map((i) {
      if (i.productId == productId) {
        return i.copyWith(quantity: newQuantity);
      }
      return i;
    }).toList(growable: false);
    return Cart(storeId: storeId, items: List.unmodifiable(updated));
  }

  /// Removes an item by product ID. If cart becomes empty, [storeId] is reset to null.
  Cart removeItem(String productId) {
    final updated = items
        .where((i) => i.productId != productId)
        .toList(growable: false);
    return Cart(
      storeId: updated.isEmpty ? null : storeId,
      items: List.unmodifiable(updated),
    );
  }

  /// Empties the cart completely and resets the [storeId].
  Cart clear() => const Cart();

  /// Returns true if an item with [productId] is in the cart.
  bool hasProduct(String productId) =>
      items.any((i) => i.productId == productId);

  /// Returns the [CartItem] with [productId], or null if not found.
  CartItem? getItem(String productId) {
    try {
      return items.firstWhere((i) => i.productId == productId);
    } catch (_) {
      return null;
    }
  }

  /// Computes the complete calculation structure for this cart (RN05).
  ///
  /// - [returnedContainers]: Empty containers handed in by the customer.
  ///   Only the missing difference is charged as guarantee fee (RN05).
  /// - [deliveryFee]: Optional delivery tariff.
  /// - [discount]: Optional discount or promotional coupon amount.
  CartCalculation calculateTotals({
    int returnedContainers = 0,
    double deliveryFee = 0.0,
    double discount = 0.0,
  }) {
    final safeReturned = returnedContainers < 0 ? 0 : returnedContainers;
    final safeDelivery = deliveryFee < 0 ? 0.0 : deliveryFee;
    final safeDiscount = discount < 0 ? 0.0 : discount;

    final returnableItems = items.where((i) => i.isReturnable).toList();
    final reqContainers = returnableItems.fold(
      0,
      (acc, item) => acc + item.quantity,
    );

    final missingContainers = (reqContainers - safeReturned).clamp(
      0,
      reqContainers,
    );

    // Calculate missing container fees by waiving deposit for returned units,
    // allocating waiver to highest-deposit containers first for customer benefit.
    double missingFee = 0.0;
    if (missingContainers > 0) {
      final unitDeposits = <double>[];
      for (final item in returnableItems) {
        for (int q = 0; q < item.quantity; q++) {
          unitDeposits.add(item.containerDeposit);
        }
      }
      unitDeposits.sort((a, b) => b.compareTo(a));

      for (int i = safeReturned; i < unitDeposits.length; i++) {
        missingFee += unitDeposits[i];
      }
    }

    final itemsSub = subtotal;
    final grandTotal = (itemsSub + missingFee + safeDelivery - safeDiscount)
        .clamp(0.0, double.infinity);

    return CartCalculation(
      itemsSubtotal: itemsSub,
      totalItemCount: totalItemCount,
      totalContainersRequired: reqContainers,
      returnedContainers: safeReturned,
      missingContainers: missingContainers,
      missingContainersFee: missingFee,
      deliveryFee: safeDelivery,
      discount: safeDiscount,
      total: grandTotal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cart &&
          runtimeType == other.runtimeType &&
          storeId == other.storeId &&
          _listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(storeId, Object.hashAll(items));

  @override
  String toString() =>
      'Cart(storeId: $storeId, itemsCount: ${items.length}, totalQuantity: $totalItemCount, subtotal: \$$subtotal)';

  bool _listEquals(List<CartItem> a, List<CartItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
