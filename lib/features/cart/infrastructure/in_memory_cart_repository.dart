import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../domain/entities/cart.dart';
import '../domain/repositories/cart_repository.dart';

/// In-memory implementation of [CartRepository].
/// Maintains active cart state in memory for testing, prototypes, and app execution.
class InMemoryCartRepository implements CartRepository {
  Cart _cart;

  InMemoryCartRepository([Cart? initialCart]) : _cart = initialCart ?? const Cart();

  @override
  Future<Result<Cart, Failure>> getCart() async {
    return Success(_cart);
  }

  @override
  Future<Result<Cart, Failure>> saveCart(Cart cart) async {
    _cart = cart;
    return Success(_cart);
  }

  @override
  Future<Result<void, Failure>> clearCart() async {
    _cart = const Cart();
    return const Success(null);
  }
}

