import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../pricing/domain/services/quantity_pricing_service.dart';
import '../../../stores/domain/entities/store.dart';
import '../entities/product.dart';
import '../entities/purchase_availability.dart';

/// Producto y cantidad solicitados al confirmar la compra.
class PurchaseRequestItem {
  final Product product;
  final int quantity;

  const PurchaseRequestItem({required this.product, required this.quantity});
}

/// Valida que el comercio siga abierto y que cada producto esté disponible
/// justo antes de crear el pedido (casos detectados en integración).
class ValidarDisponibilidadCompraUseCase {
  final QuantityPricingService pricingService;

  const ValidarDisponibilidadCompraUseCase({
    this.pricingService = const QuantityPricingService(),
  });

  Result<PurchaseAvailability, Failure> call({
    required StorePurchaseSnapshot snapshot,
    required List<PurchaseRequestItem> items,
  }) {
    final Store store = snapshot.store;

    if (!snapshot.isOpenNow || !store.isOpen) {
      return const FailureResult(
        BusinessRuleFailure(
          'El comercio cerró o no está recibiendo pedidos en este momento',
        ),
      );
    }

    if (items.isEmpty) {
      return const FailureResult(
        ValidationFailure('Agrega al menos un producto para comprar'),
      );
    }

    final lines = <PurchaseLine>[];
    var totalUnits = 0;
    var subtotal = 0.0;

    for (final item in items) {
      if (item.product.storeId != store.id) {
        return const FailureResult(
          BusinessRuleFailure(
            'RN07: todos los productos deben pertenecer al mismo comercio',
          ),
        );
      }

      if (!item.product.isAvailable) {
        return FailureResult(
          BusinessRuleFailure(
            'El producto "${item.product.name}" ya no está disponible',
          ),
        );
      }

      if (item.quantity <= 0 || item.quantity > 999) {
        return FailureResult(
          ValidationFailure(
            'La cantidad de "${item.product.name}" debe estar entre 1 y 999',
          ),
        );
      }

      final tiersResult = pricingService.validateTiers(item.product);
      if (tiersResult.isFailure) {
        return FailureResult(tiersResult.failureOrNull!);
      }

      final unitPrice = item.product.getUnitPriceForQuantity(item.quantity);
      subtotal += unitPrice * item.quantity;
      totalUnits += item.quantity;

      lines.add(
        PurchaseLine(
          productId: item.product.id,
          productName: item.product.name,
          quantity: item.quantity,
          isAvailable: true,
        ),
      );
    }

    return Success(
      PurchaseAvailability(
        storeId: store.id,
        storeName: store.name,
        lines: lines,
        totalUnits: totalUnits,
        estimatedSubtotal: double.parse(subtotal.toStringAsFixed(2)),
        storeIsOpen: true,
      ),
    );
  }
}
