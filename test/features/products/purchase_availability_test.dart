import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/products/domain/entities/product.dart';
import 'package:bebidas_delivery_app/features/products/domain/entities/purchase_availability.dart';
import 'package:bebidas_delivery_app/features/products/domain/usecases/validar_disponibilidad_compra_use_case.dart';
import 'package:bebidas_delivery_app/features/stores/domain/entities/store.dart';

void main() {
  const useCase = ValidarDisponibilidadCompraUseCase();

  const store = Store(
    id: 'store-1',
    name: 'Licorera El Barril',
    address: 'Av. Flavio Reyes',
    isOpen: true,
  );

  const beer = Product(
    id: 'prod-1',
    storeId: 'store-1',
    name: 'Cerveza Pilsen',
    basePrice: 2.5,
  );

  const wine = Product(
    id: 'prod-2',
    storeId: 'store-1',
    name: 'Vino tinto',
    basePrice: 18.0,
  );

  test('valida compra cuando el comercio está abierto y hay stock', () {
    final result = useCase(
      snapshot: const StorePurchaseSnapshot(store: store, isOpenNow: true),
      items: const [
        PurchaseRequestItem(product: beer, quantity: 6),
        PurchaseRequestItem(product: wine, quantity: 1),
      ],
    );

    final availability = result.dataOrNull!;
    expect(availability.canCheckout, isTrue);
    expect(availability.totalUnits, 7);
    expect(availability.estimatedSubtotal, 33.0);
    expect(availability.lines, hasLength(2));
  });

  test('rechaza la compra si el comercio cerró en el momento de pagar', () {
    final result = useCase(
      snapshot: const StorePurchaseSnapshot(store: store, isOpenNow: false),
      items: const [PurchaseRequestItem(product: beer, quantity: 1)],
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull!.message, contains('cerró'));
  });

  test('rechaza productos de otro comercio (RN07)', () {
    const foreign = Product(
      id: 'prod-9',
      storeId: 'store-2',
      name: 'Whisky',
      basePrice: 40,
    );

    final result = useCase(
      snapshot: const StorePurchaseSnapshot(store: store, isOpenNow: true),
      items: const [PurchaseRequestItem(product: foreign, quantity: 1)],
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull!.message, contains('RN07'));
  });

  test('rechaza producto no disponible al momento de comprar', () {
    const soldOut = Product(
      id: 'prod-3',
      storeId: 'store-1',
      name: 'Cerveza IPA',
      basePrice: 4,
      isAvailable: false,
    );

    final result = useCase(
      snapshot: const StorePurchaseSnapshot(store: store, isOpenNow: true),
      items: const [PurchaseRequestItem(product: soldOut, quantity: 2)],
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull!.message, contains('no está disponible'));
  });

  test('rechaza carrito vacío y cantidades inválidas', () {
    expect(
      useCase(
        snapshot: const StorePurchaseSnapshot(store: store, isOpenNow: true),
        items: const [],
      ).isFailure,
      isTrue,
    );

    expect(
      useCase(
        snapshot: const StorePurchaseSnapshot(store: store, isOpenNow: true),
        items: const [
          PurchaseRequestItem(product: beer, quantity: 0),
        ],
      ).isFailure,
      isTrue,
    );
  });
}
