import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/returnable_container.dart';
import '../../domain/repositories/returnable_container_repository.dart';

class InMemoryReturnableContainerRepository
    implements ReturnableContainerRepository {
  final Map<String, ReturnableContainer> _containers = {};

  @override
  Future<Result<ReturnableContainer?, Failure>> getByProduct(
    String storeId,
    String productId,
  ) async {
    return Success(_containers['$storeId:$productId']);
  }

  @override
  Future<Result<ReturnableContainer, Failure>> save(
    String storeId,
    ReturnableContainer container,
  ) async {
    _containers['$storeId:${container.productId}'] = container;
    return Success(container);
  }
}
