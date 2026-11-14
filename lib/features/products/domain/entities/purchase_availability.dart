import '../../../stores/domain/entities/store.dart';

/// Línea solicitada por el cliente en el momento de comprar.
class PurchaseLine {
  final String productId;
  final String productName;
  final int quantity;
  final bool isAvailable;

  const PurchaseLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.isAvailable,
  });
}

/// Resultado de validar la compra contra el estado real del comercio.
class PurchaseAvailability {
  final String storeId;
  final String storeName;
  final List<PurchaseLine> lines;
  final int totalUnits;
  final double estimatedSubtotal;
  final bool storeIsOpen;

  const PurchaseAvailability({
    required this.storeId,
    required this.storeName,
    required this.lines,
    required this.totalUnits,
    required this.estimatedSubtotal,
    required this.storeIsOpen,
  });

  bool get canCheckout => storeIsOpen && lines.isNotEmpty;
}

/// Snapshot mínimo del comercio en el instante de comprar.
class StorePurchaseSnapshot {
  final Store store;
  final bool isOpenNow;

  const StorePurchaseSnapshot({
    required this.store,
    required this.isOpenNow,
  });
}
