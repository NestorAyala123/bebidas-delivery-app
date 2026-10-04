import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

class ConfirmOrderInput {
  final String orderId;
  final String storeId;

  const ConfirmOrderInput({required this.orderId, required this.storeId});
}

class ConfirmOrderUseCase {
  final OrderRepository _repository;

  const ConfirmOrderUseCase(this._repository);

  Future<Result<Order, Failure>> call(ConfirmOrderInput input) {
    if (input.orderId.trim().isEmpty || input.storeId.trim().isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('El pedido y el comercio son obligatorios.'),
        ),
      );
    }

    return _repository.confirmOrder(
      orderId: input.orderId.trim(),
      storeId: input.storeId.trim(),
    );
  }
}
