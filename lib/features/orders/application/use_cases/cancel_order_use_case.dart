import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

class CancelOrderUseCase {
  final OrderRepository repository;

  const CancelOrderUseCase(this.repository);

  Future<Result<Order, Failure>> call({
    required String orderId,
    required String customerId,
  }) {
    if (orderId.trim().isEmpty || customerId.trim().isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('El pedido y el cliente son obligatorios.'),
        ),
      );
    }
    return repository.cancelOrder(
      orderId: orderId.trim(),
      customerId: customerId.trim(),
    );
  }
}
