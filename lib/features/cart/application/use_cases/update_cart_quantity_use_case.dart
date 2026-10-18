import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';

enum QuantityUpdateMode { set, increment, decrement }

class UpdateCartQuantityInput {
  final String productId;
  final int value;
  final QuantityUpdateMode mode;

  const UpdateCartQuantityInput({
    required this.productId,
    required this.value,
    this.mode = QuantityUpdateMode.set,
  });

  const UpdateCartQuantityInput.set(String productId, int newQuantity)
      : this(productId: productId, value: newQuantity, mode: QuantityUpdateMode.set);

  const UpdateCartQuantityInput.increment(String productId, [int amount = 1])
      : this(
          productId: productId,
          value: amount,
          mode: QuantityUpdateMode.increment,
        );

  const UpdateCartQuantityInput.decrement(String productId, [int amount = 1])
      : this(
          productId: productId,
          value: amount,
          mode: QuantityUpdateMode.decrement,
        );
}

/// Use case to update, increment, or decrement item quantity in the cart.
class UpdateCartQuantityUseCase {
  final CartRepository repository;

  UpdateCartQuantityUseCase(this.repository);

  Future<Result<Cart, Failure>> call(UpdateCartQuantityInput input) async {
    final cleanProductId = input.productId.trim();
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

    if (!currentCart.hasProduct(cleanProductId)) {
      return const FailureResult(
        NotFoundFailure('El producto no se encuentra en el carrito.'),
      );
    }

    try {
      final updatedCart = switch (input.mode) {
        QuantityUpdateMode.set =>
          currentCart.updateQuantity(cleanProductId, input.value),
        QuantityUpdateMode.increment =>
          currentCart.incrementQuantity(cleanProductId, input.value),
        QuantityUpdateMode.decrement =>
          currentCart.decrementQuantity(cleanProductId, input.value),
      };

      return await repository.saveCart(updatedCart);
    } catch (e) {
      return FailureResult(ValidationFailure(e.toString()));
    }
  }
}

