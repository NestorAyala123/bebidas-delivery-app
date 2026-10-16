import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';

class AddToCartInput {
  final String targetStoreId;
  final CartItem item;
  final bool forceReplaceStore;

  const AddToCartInput({
    required this.targetStoreId,
    required this.item,
    this.forceReplaceStore = false,
  });
}

/// Use case to add an item to the active cart enforcing RN07 (Single Store).
class AddToCartUseCase {
  final CartRepository repository;

  AddToCartUseCase(this.repository);

  Future<Result<Cart, Failure>> call(AddToCartInput input) async {
    final cleanStoreId = input.targetStoreId.trim();
    if (cleanStoreId.isEmpty) {
      return const FailureResult(
        ValidationFailure('El identificador del comercio es obligatorio.'),
      );
    }

    final cartResult = await repository.getCart();
    final currentCart = switch (cartResult) {
      Success(:final data) => data,
      FailureResult() => const Cart(),
    };

    // Check RN07: Single Store constraint
    if (!currentCart.canAddItemFromStore(cleanStoreId)) {
      if (!input.forceReplaceStore) {
        return const FailureResult(
          BusinessRuleFailure(
            'RN07: No se pueden agregar productos de diferentes comercios en el mismo carrito.',
            'RN07',
          ),
        );
      }

      // User confirmed replacing store and clearing previous items
      final replacedCart = currentCart.replaceStoreAndSetItem(
        targetStoreId: cleanStoreId,
        item: input.item,
      );
      return repository.saveCart(replacedCart);
    }

    try {
      final updatedCart = currentCart.addItem(
        targetStoreId: cleanStoreId,
        item: input.item,
      );
      return await repository.saveCart(updatedCart);
    } catch (e) {
      return FailureResult(ValidationFailure(e.toString()));
    }
  }
}

