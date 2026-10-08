import '../../../../core/errors/exceptions.dart';
import 'cart_item.dart';

/// Cart domain entity enforcing RN07 (Single Store constraint).
class Cart {
  final String? storeId; // RN07: Un solo establecimiento por pedido
  final List<CartItem> items;

  const Cart({this.storeId, this.items = const []});

  bool get isEmpty => items.isEmpty;
  int get totalItemCount => items.fold(0, (acc, item) => acc + item.quantity);
  double get subtotal => items.fold(0.0, (acc, item) => acc + item.subtotal);

  /// Adds an item. Throws DomainException if item is from a different store (RN07).
  Cart addItem({required String targetStoreId, required CartItem item}) {
    if (storeId != null && storeId != targetStoreId && items.isNotEmpty) {
      throw const DomainException(
        'RN07: No se pueden agregar productos de diferentes comercios en el mismo carrito.',
      );
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

    return Cart(storeId: targetStoreId, items: updated);
  }

  /// Removes an item by product ID. If cart becomes empty, storeId is reset.
  Cart removeItem(String productId) {
    final updated = items.where((i) => i.productId != productId).toList();
    return Cart(storeId: updated.isEmpty ? null : storeId, items: updated);
  }

  /// Updates quantity for a specific product. If quantity <= 0, item is removed.
  Cart updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      return removeItem(productId);
    }
    final updated = items.map((i) {
      if (i.productId == productId) {
        return i.copyWith(quantity: newQuantity);
      }
      return i;
    }).toList();
    return Cart(storeId: storeId, items: updated);
  }

  Cart clear() => const Cart();
}
