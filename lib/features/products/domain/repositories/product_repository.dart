import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<Result<Product, Failure>> getProductById(String id);
  Future<Result<List<Product>, Failure>> getProductsByStore(String storeId);
  Future<Result<void, Failure>> updateStockStatus(String productId, bool isAvailable);
}
