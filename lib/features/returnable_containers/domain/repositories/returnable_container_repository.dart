import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/returnable_container.dart';

abstract class ReturnableContainerRepository {
  Future<Result<ReturnableContainer?, Failure>>
  getByProduct(String storeId, String productId);

  Future<Result<ReturnableContainer, Failure>> save(
    String storeId,
    ReturnableContainer container,
  );
}
