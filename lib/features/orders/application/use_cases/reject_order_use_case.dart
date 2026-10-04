import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

class RejectOrderInput {
  final String orderId;
  final String storeId;
  final String reason;

  const RejectOrderInput({
    required this.orderId,
    required this.storeId,
    required this.reason,
  });
}

class RejectOrderUseCase {
  final OrderRepository _repository;

  const RejectOrderUseCase(this._repository);

  Future<Result<Order, Failure>> call(RejectOrderInput input) {
    if (input.orderId.trim().isEmpty || input.storeId.trim().isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('El pedido y el comercio son obligatorios.'),
        ),
      );
    }
    if (input.reason.trim().isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('Se debe indicar el motivo del rechazo.'),
        ),
      );
    }

    return _repository.rejectOrder(
      orderId: input.orderId.trim(),
      storeId: input.storeId.trim(),
      reason: input.reason.trim(),
    );
  }
}
