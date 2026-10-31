import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart_item.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/create_order_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/get_customer_orders_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_status.dart';
import 'package:bebidas_delivery_app/features/orders/infrastructure/in_memory_order_repository.dart';
import 'package:bebidas_delivery_app/features/pricing/domain/entities/quantity_pricing_tier.dart';
import 'package:bebidas_delivery_app/features/products/domain/entities/product.dart';

void main() {
  group('David - Semana 3: Creación de Pedido, Reglas y Resumen/Historial', () {
    late InMemoryOrderRepository orderRepository;
    late CreateOrderUseCase createOrderUseCase;
    late GetCustomerOrdersUseCase getCustomerOrdersUseCase;

    setUp(() {
      orderRepository = InMemoryOrderRepository();
      createOrderUseCase = CreateOrderUseCase(
        repository: orderRepository,
        generateOrderId: () => 'ORD-1001',
      );
      getCustomerOrdersUseCase = GetCustomerOrdersUseCase(orderRepository);
    });

    test('1. PRECIO POR RANGO: Aplica escalonamiento de precios según la cantidad de artículos', () {
      // Producto con precio base $3.00, pero a partir de 6 unidades baja a $2.40, y a partir de 12 a $2.00
      const tieredProduct = Product(
        id: 'prod-pilsener',
        storeId: 'store-1',
        name: 'Pilsener 330ml',
        basePrice: 3.00,
        isReturnableContainer: true,
        containerDepositPrice: 0.50,
        quantityTiers: [
          QuantityPricingTier(minQuantity: 6, unitPrice: 2.40),
          QuantityPricingTier(minQuantity: 12, unitPrice: 2.00),
        ],
      );

      // Comprando 2 unidades: aplica precio base ($3.00)
      final item2Units = CartItem.fromProduct(tieredProduct, quantity: 2);
      expect(item2Units.unitPrice, equals(3.00));
      expect(item2Units.subtotal, equals(6.00));
      expect(item2Units.hasTierDiscount, isFalse);

      // Actualizando a 6 unidades: aplica automáticamente tier 1 ($2.40)
      final item6Units = item2Units.copyWith(quantity: 6);
      expect(item6Units.unitPrice, equals(2.40));
      expect(item6Units.subtotal, closeTo(14.40, 0.001));
      expect(item6Units.hasTierDiscount, isTrue);

      // En el carrito: acumulando unidades mediante addItem
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: 'store-1', item: item2Units);
      expect(cart.subtotal, equals(6.00));

      // Se agregan 4 más del mismo producto (total 6 unidades en carrito)
      cart = cart.addItem(
        targetStoreId: 'store-1',
        item: CartItem.fromProduct(tieredProduct, quantity: 4),
      );
      expect(cart.items.length, equals(1));
      expect(cart.totalItemCount, equals(6));
      expect(cart.items.first.unitPrice, equals(2.40));
      expect(cart.subtotal, closeTo(14.40, 0.001));

      // Actualizando a 12 unidades en el carrito
      cart = cart.updateQuantity('prod-pilsener', 12);
      expect(cart.items.first.unitPrice, equals(2.00));
      expect(cart.subtotal, equals(24.00));
    });

    test('2. CARGO POR ENVASES FALTANTES (RN05): Cobra solo la diferencia en envases no entregados', () {
      // 10 cervezas retornables con depósito de $0.50 cada una (depósito total requerido: $5.00)
      const beer = CartItem(
        productId: 'prod-beer',
        productName: 'Club 330ml Retornable',
        unitPrice: 2.50,
        quantity: 10,
        isReturnable: true,
        containerDeposit: 0.50,
      );

      var cart = const Cart().addItem(targetStoreId: 'store-1', item: beer);
      expect(cart.totalReturnableContainers, equals(10));

      // Caso A: El cliente entrega todos los envases (10 de 10) -> Cargo por faltantes es $0.00
      final calcAllReturned = cart.calculateTotals(returnedContainers: 10);
      expect(calcAllReturned.missingContainers, equals(0));
      expect(calcAllReturned.missingContainersFee, equals(0.0));
      expect(calcAllReturned.total, equals(25.00));

      // Caso B: El cliente entrega 6 envases (faltan 4) -> Cargo por faltantes: 4 * 0.50 = $2.00
      final calcPartialReturned = cart.calculateTotals(returnedContainers: 6);
      expect(calcPartialReturned.missingContainers, equals(4));
      expect(calcPartialReturned.missingContainersFee, equals(2.00));
      expect(calcPartialReturned.total, equals(27.00));

      // Caso C: El cliente no entrega ningún envase (0 de 10) -> Cargo: 10 * 0.50 = $5.00
      final calcNoneReturned = cart.calculateTotals(returnedContainers: 0);
      expect(calcNoneReturned.missingContainers, equals(10));
      expect(calcNoneReturned.missingContainersFee, equals(5.00));
      expect(calcNoneReturned.total, equals(30.00));
    });

    test('3. CREAR PEDIDO EN ESTADO PENDIENTE: Registra pedido con OrderStatus.created', () async {
      const item = CartItem(
        productId: 'p-1',
        productName: 'Agua con Gas',
        unitPrice: 1.50,
        quantity: 4,
      );
      final cart = const Cart().addItem(targetStoreId: 'store-central', item: item);

      final result = await createOrderUseCase(
        CreateOrderInput.fromCart(
          customerId: 'cust-david-01',
          deliveryAddress: 'Av. Flavio Reyes 456, Manta',
          cart: cart,
          returnedContainers: 0,
        ),
      );

      expect(result.isSuccess, isTrue);
      final order = result.dataOrNull!;
      expect(order.id, equals('ORD-1001'));
      expect(order.status, equals(OrderStatus.created));
      expect(order.status.isPending, isTrue);
      expect(order.status.displayName, equals('Pendiente'));
      expect(order.canRequestDriver, isFalse); // RN01: comercio debe confirmar antes
    });

    test('4. PRECIO HISTÓRICO CONGELADO (RN08): Si cambia el catálogo, el pedido mantiene su importe', () async {
      // 1. Producto en catálogo a $10.00 con tier a $8.00 por 6 unidades
      var catalogProduct = const Product(
        id: 'whisky-12',
        storeId: 'store-licores',
        name: 'Whisky 12 Años',
        basePrice: 10.00,
        quantityTiers: [QuantityPricingTier(minQuantity: 6, unitPrice: 8.00)],
      );

      // 2. Se agrega al carrito y se crea el pedido congelando precio
      final cartItem = CartItem.fromProduct(catalogProduct, quantity: 6);
      final cart = const Cart().addItem(targetStoreId: 'store-licores', item: cartItem);

      final createResult = await createOrderUseCase(
        CreateOrderInput(
          customerId: 'cust-david-01',
          deliveryAddress: 'Calle 13 y Av. 2',
          cart: cart,
          missingContainersFee: 0.0,
        ),
      );

      final createdOrder = createResult.dataOrNull!;
      expect(createdOrder.items.first.frozenUnitPrice, equals(8.00));
      expect(createdOrder.itemsSubtotal, equals(48.00));
      expect(createdOrder.total, equals(48.00));

      // 3. El comercio sube los precios en catálogo drásticamente
      catalogProduct = const Product(
        id: 'whisky-12',
        storeId: 'store-licores',
        name: 'Whisky 12 Años',
        basePrice: 50.00, // Subió a $50
        quantityTiers: [QuantityPricingTier(minQuantity: 6, unitPrice: 40.00)],
      );

      // 4. El pedido guardado en el repositorio mantiene su importe original intacto
      final retrievedOrderResult = await orderRepository.getOrderById(createdOrder.id);
      final persistedOrder = retrievedOrderResult.dataOrNull!;
      expect(persistedOrder.items.first.frozenUnitPrice, equals(8.00));
      expect(persistedOrder.itemsSubtotal, equals(48.00));
      expect(persistedOrder.total, equals(48.00));
    });

    test('5. RESUMEN E HISTORIAL INICIAL: Consulta pedidos del cliente ordenados por fecha', () async {
      // Creamos dos pedidos para el cliente
      final cart1 = const Cart().addItem(
        targetStoreId: 'store-1',
        item: const CartItem(productId: 'prod-1', productName: 'Jugo', unitPrice: 2.0, quantity: 1),
      );
      final cart2 = const Cart().addItem(
        targetStoreId: 'store-1',
        item: const CartItem(productId: 'prod-2', productName: 'Agua', unitPrice: 1.0, quantity: 2),
      );

      int counter = 0;
      final useCaseWithCounter = CreateOrderUseCase(
        repository: orderRepository,
        generateOrderId: () => 'ORD-${++counter}',
      );

      await useCaseWithCounter(CreateOrderInput.fromCart(
        customerId: 'cust-david-01',
        deliveryAddress: 'Dir 1',
        cart: cart1,
      ));
      await useCaseWithCounter(CreateOrderInput.fromCart(
        customerId: 'cust-david-01',
        deliveryAddress: 'Dir 2',
        cart: cart2,
      ));

      final historyResult = await getCustomerOrdersUseCase('cust-david-01');
      expect(historyResult.isSuccess, isTrue);
      final orders = historyResult.dataOrNull!;
      expect(orders.length, equals(2));
      expect(orders.first.status, equals(OrderStatus.created));
      expect(orders.every((o) => o.status.isPending), isTrue);
    });
  });
}
