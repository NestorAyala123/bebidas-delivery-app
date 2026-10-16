import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_calculation.dart';

class CalculateCartTotalsInput {
  final Cart cart;
  final int returnedContainers;
  final double deliveryFee;
  final double discount;

  const CalculateCartTotalsInput({
    required this.cart,
    this.returnedContainers = 0,
    this.deliveryFee = 0.0,
    this.discount = 0.0,
  });
}

/// Use case that calculates the complete breakdown structure of a cart.
class CalculateCartTotalsUseCase {
  const CalculateCartTotalsUseCase();

  Future<Result<CartCalculation, Failure>> call(
    CalculateCartTotalsInput input,
  ) async {
    if (input.returnedContainers < 0) {
      return const FailureResult(
        ValidationFailure(
          'La cantidad de envases devueltos no puede ser negativa.',
        ),
      );
    }
    if (input.deliveryFee < 0) {
      return const FailureResult(
        ValidationFailure('La tarifa de entrega no puede ser negativa.'),
      );
    }
    if (input.discount < 0) {
      return const FailureResult(
        ValidationFailure('El descuento no puede ser negativo.'),
      );
    }

    final calculation = input.cart.calculateTotals(
      returnedContainers: input.returnedContainers,
      deliveryFee: input.deliveryFee,
      discount: input.discount,
    );

    return Success(calculation);
  }
}

