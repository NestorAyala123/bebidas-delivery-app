import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

class GetStoreOrdersUseCase {
  final OrderRepository repository;

  const GetStoreOrdersUseCase(this.repository);

  Future<Result<List<Order>, Failure>> call(String storeId) {
    final id = storeId.trim();
    if (id.isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('El identificador del comercio es obligatorio.'),
        ),
      );
    }
    return repository.getOrdersByStore(id);
  }
}
