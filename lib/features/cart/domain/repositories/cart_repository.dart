import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/cart.dart';

/// Contract for managing shopping cart state in the domain layer.
abstract class CartRepository {
  /// Retrieves the current active cart.
  Future<Result<Cart, Failure>> getCart();

  /// Saves the updated cart state.
  Future<Result<Cart, Failure>> saveCart(Cart cart);

  /// Clears the active cart.
  Future<Result<void, Failure>> clearCart();
}

