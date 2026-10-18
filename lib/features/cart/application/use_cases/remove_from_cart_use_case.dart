import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';

/// Use case to remove an item from the cart.
class RemoveFromCartUseCase {
  final CartRepository repository;

  RemoveFromCartUseCase(this.repository);

  Future<Result<Cart, Failure>> call(String productId) async {
    final cleanProductId = productId.trim();
    if (cleanProductId.isEmpty) {
      return const FailureResult(
        ValidationFailure('El identificador del producto es obligatorio.'),
      );
    }

    final cartResult = await repository.getCart();
    final currentCart = switch (cartResult) {
      Success(:final data) => data,
      FailureResult() => null,
    };

    if (currentCart == null) {
      return const FailureResult(
        NotFoundFailure('No se encontró el carrito activo.'),
      );
    }

    final updatedCart = currentCart.removeItem(cleanProductId);
    return repository.saveCart(updatedCart);
  }
}

