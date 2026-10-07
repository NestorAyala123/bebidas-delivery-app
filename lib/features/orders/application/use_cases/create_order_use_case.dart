import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/repositories/order_repository.dart';

class CreateOrderInput {
  final String customerId;
  final String deliveryAddress;
  final Cart cart;
  final double missingContainersFee;

  const CreateOrderInput({
    required this.customerId,
    required this.deliveryAddress,
    required this.cart,
    this.missingContainersFee = 0,
  });
}

class CreateOrderUseCase {
  final OrderRepository repository;
  final String Function() generateOrderId;
  final DateTime Function() _now;

  CreateOrderUseCase({
    required this.repository,
    required this.generateOrderId,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Future<Result<Order, Failure>> call(CreateOrderInput input) {
    final validationError = _validate(input);
    if (validationError != null) {
      return Future.value(FailureResult(validationError));
    }

    final orderId = generateOrderId().trim();
    if (orderId.isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('No se pudo generar el identificador del pedido.'),
        ),
      );
    }

    final order = Order(
      id: orderId,
      customerId: input.customerId.trim(),
      storeId: input.cart.storeId!.trim(),
      items: input.cart.items
          .map(
            (item) => OrderItem(
              productId: item.productId,
              productName: item.productName,
              frozenUnitPrice: item.unitPrice,
              quantity: item.quantity,
              isReturnable: item.isReturnable,
              containerDepositPrice: item.containerDeposit,
            ),
          )
          .toList(growable: false),
      status: OrderStatus.created,
      deliveryAddress: input.deliveryAddress.trim(),
      missingContainersFee: input.missingContainersFee,
      createdAt: _now(),
    );

    return repository.createOrder(order);
  }

  ValidationFailure? _validate(CreateOrderInput input) {
    if (input.customerId.trim().isEmpty) {
      return const ValidationFailure(
        'El identificador del cliente es obligatorio.',
      );
    }
    if (input.deliveryAddress.trim().isEmpty) {
      return const ValidationFailure('La dirección de entrega es obligatoria.');
    }
    if (input.cart.storeId == null || input.cart.storeId!.trim().isEmpty) {
      return const ValidationFailure(
        'El carrito debe pertenecer a un comercio.',
      );
    }
    if (input.cart.isEmpty) {
      return const ValidationFailure('No se puede crear un pedido vacío.');
    }
    if (!input.missingContainersFee.isFinite ||
        input.missingContainersFee < 0) {
      return const ValidationFailure(
        'El cargo por envases faltantes no puede ser negativo.',
      );
    }

    for (final item in input.cart.items) {
      if (item.productId.trim().isEmpty || item.productName.trim().isEmpty) {
        return const ValidationFailure(
          'Cada ítem debe tener identificador y nombre de producto.',
        );
      }
      if (item.quantity <= 0) {
        return const ValidationFailure(
          'La cantidad de cada ítem debe ser mayor a cero.',
        );
      }
      if (!item.unitPrice.isFinite ||
          !item.containerDeposit.isFinite ||
          item.unitPrice < 0 ||
          item.containerDeposit < 0) {
        return const ValidationFailure(
          'El precio y el depósito del envase no pueden ser negativos.',
        );
      }
    }
    return null;
  }
}
