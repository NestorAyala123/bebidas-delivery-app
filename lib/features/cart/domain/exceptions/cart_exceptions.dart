import '../../../../core/errors/exceptions.dart';

/// Exception thrown when violating Business Rule RN07:
/// "Un pedido/carrito solo puede contener productos de un único comercio."
class SingleStoreViolationException extends DomainException {
  const SingleStoreViolationException([
    super.message =
        'RN07: No se pueden agregar productos de diferentes comercios en el mismo carrito.',
    super.code = 'RN07',
  ]);
}

/// Exception thrown when an item is not found in the cart.
class CartItemNotFoundException extends DomainException {
  const CartItemNotFoundException([
    super.message = 'El producto no fue encontrado en el carrito.',
    super.code = 'CART_ITEM_NOT_FOUND',
  ]);
}

/// Exception thrown when an invalid quantity is provided for a cart operation.
class InvalidCartQuantityException extends DomainException {
  const InvalidCartQuantityException([
    super.message = 'La cantidad debe ser mayor a cero.',
    super.code = 'INVALID_CART_QUANTITY',
  ]);
}

