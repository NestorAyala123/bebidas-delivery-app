import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/repositories/order_repository.dart';

class UpdateOrderStatusInput {
  final String orderId;
  final String storeId;
  final OrderStatus status;

  const UpdateOrderStatusInput({
    required this.orderId,
    required this.storeId,
    required this.status,
  });
}

class UpdateOrderStatusUseCase {
  final OrderRepository repository;

  const UpdateOrderStatusUseCase(this.repository);

  Future<Result<Order, Failure>> call(UpdateOrderStatusInput input) {
    if (input.orderId.trim().isEmpty || input.storeId.trim().isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('El pedido y el comercio son obligatorios.'),
        ),
      );
    }
    return repository.updateOrderStatus(
      orderId: input.orderId.trim(),
      storeId: input.storeId.trim(),
      status: input.status,
    );
  }
}
