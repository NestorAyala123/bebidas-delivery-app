import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

/// Use case to retrieve orders for a specific customer, sorted by creation date descending.
class GetCustomerOrdersUseCase {
  final OrderRepository repository;

  const GetCustomerOrdersUseCase(this.repository);

  Future<Result<List<Order>, Failure>> call(String customerId) async {
    final cleanId = customerId.trim();
    if (cleanId.isEmpty) {
      return const FailureResult(
        ValidationFailure('El identificador del cliente es obligatorio.'),
      );
    }
    return repository.getOrdersByCustomer(cleanId);
  }
}
