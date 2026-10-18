import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/repositories/cart_repository.dart';

/// Use case to completely clear the active cart and reset single-store context.
class ClearCartUseCase {
  final CartRepository repository;

  ClearCartUseCase(this.repository);

  Future<Result<void, Failure>> call() => repository.clearCart();
}

