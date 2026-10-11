import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class InMemoryProductRepository implements ProductRepository {
  final Map<String, Product> _products = {};

  @override
  Future<Result<Product, Failure>> getProductById(String id) async {
    final product = _products[id];
    return product == null
        ? const FailureResult<Product, Failure>(
            NotFoundFailure('Producto no encontrado'),
          )
        : Success(product);
  }

  @override
  Future<Result<List<Product>, Failure>> getProductsByStore(
    String storeId,
  ) async {
    return Success(
      _products.values.where((product) => product.storeId == storeId).toList(),
    );
  }

  @override
  Future<Result<List<Product>, Failure>> getAvailableProducts(
    String storeId,
  ) async {
    return Success(
      _products.values
          .where((product) => product.storeId == storeId && product.isAvailable)
          .toList(),
    );
  }

  @override
  Future<Result<Product, Failure>> createProduct(Product product) async {
    if (_products.containsKey(product.id)) {
      return const FailureResult<Product, Failure>(
        ValidationFailure('Ya existe un producto con ese identificador'),
      );
    }
    _products[product.id] = product;
    return Success(product);
  }

  @override
  Future<Result<Product, Failure>> updateProduct(Product product) async {
    if (!_products.containsKey(product.id)) {
      return const FailureResult<Product, Failure>(
        NotFoundFailure('Producto no encontrado'),
      );
    }
    _products[product.id] = product;
    return Success(product);
  }

  @override
  Future<Result<void, Failure>> updateStockStatus(
    String productId,
    bool isAvailable,
  ) async {
    final product = _products[productId];
    if (product == null) {
      return const FailureResult<void, Failure>(
        NotFoundFailure('Producto no encontrado'),
      );
    }
    _products[productId] = Product(
      id: product.id,
      storeId: product.storeId,
      name: product.name,
      description: product.description,
      basePrice: product.basePrice,
      isAvailable: isAvailable,
      imageUrl: product.imageUrl,
      isReturnableContainer: product.isReturnableContainer,
      containerDepositPrice: product.containerDepositPrice,
      quantityTiers: product.quantityTiers,
      priceRules: product.priceRules,
      returnableContainer: product.returnableContainer,
    );
    return const Success<void, Failure>(null);
  }
}
