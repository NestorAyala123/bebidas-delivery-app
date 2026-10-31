import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/auth/domain/entities/user_session.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart_item.dart';
import 'package:bebidas_delivery_app/features/cart/infrastructure/in_memory_cart_repository.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/create_order_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/get_customer_orders_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_item.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_status.dart';
import 'package:bebidas_delivery_app/features/orders/infrastructure/in_memory_order_repository.dart';
import 'package:bebidas_delivery_app/features/orders/presentation/pages/order_summary_page.dart';
import 'package:bebidas_delivery_app/features/orders/presentation/pages/orders_history_page.dart';
import 'package:bebidas_delivery_app/features/pricing/domain/entities/quantity_pricing_tier.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/app_user.dart';

void main() {
  const testSession = UserSession(
    userId: 'user-david-test',
    email: 'david@test.com',
    token: 'test-token-123',
    role: UserRole.client,
  );

  group('OrderSummaryPage Widget Tests', () {
    testWidgets('Renders empty cart state when cart is empty', (tester) async {
      final cartRepo = InMemoryCartRepository(const Cart());
      final orderRepo = InMemoryOrderRepository();
      final createOrderUseCase = CreateOrderUseCase(
        repository: orderRepo,
        generateOrderId: () => 'ORD-TEST-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OrderSummaryPage(
            session: testSession,
            cartRepository: cartRepo,
            createOrderUseCase: createOrderUseCase,
          ),
        ),
      );

      expect(find.text('Tu carrito está vacío'), findsOneWidget);
      expect(find.text('Cargar Artículos de Demostración'), findsOneWidget);
    });

    testWidgets('Renders items, tiers, returnable containers, and creates pending order', (tester) async {
      const itemWithTiers = CartItem(
        productId: 'prod-1',
        productName: 'Cerveza Club 330ml',
        unitPrice: 2.40,
        basePrice: 3.00,
        quantity: 6,
        isReturnable: true,
        containerDeposit: 0.50,
        quantityTiers: [QuantityPricingTier(minQuantity: 6, unitPrice: 2.40)],
      );

      final initialCart = const Cart().addItem(
        targetStoreId: 'store-1',
        item: itemWithTiers,
      );

      final cartRepo = InMemoryCartRepository(initialCart);
      final orderRepo = InMemoryOrderRepository();
      final createOrderUseCase = CreateOrderUseCase(
        repository: orderRepo,
        generateOrderId: () => 'ORD-TEST-99',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OrderSummaryPage(
            session: testSession,
            cartRepository: cartRepo,
            createOrderUseCase: createOrderUseCase,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check item and tier badge
      expect(find.text('Cerveza Club 330ml'), findsOneWidget);
      expect(find.text('Precio por Rango'), findsOneWidget);
      expect(find.text('Envases Retornables (RN05)'), findsOneWidget);

      // Tap confirm button
      final confirmButton = find.text('Confirmar Pedido (Crear como Pendiente)');
      expect(confirmButton, findsOneWidget);
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Dialog confirms created pending order
      expect(find.text('¡Pedido Creado!'), findsOneWidget);
      expect(find.text('ID del Pedido: ORD-TEST-99'), findsOneWidget);
      expect(find.text('Pendiente'), findsWidgets);
    });
  });

  group('OrdersHistoryPage Widget Tests', () {
    testWidgets('Renders customer order with frozen prices and pending badge', (tester) async {
      final existingOrder = Order(
        id: 'ORD-HIST-01',
        customerId: 'user-david-test',
        storeId: 'store-1',
        status: OrderStatus.created,
        deliveryAddress: 'Av. 4 de Noviembre, Manta',
        createdAt: DateTime(2026, 10, 19, 20, 0),
        items: const [
          OrderItem(
            productId: 'p-1',
            productName: 'Cerveza Club 330ml',
            frozenUnitPrice: 2.40,
            quantity: 6,
            isReturnable: true,
            containerDepositPrice: 0.50,
          ),
        ],
        missingContainersFee: 1.00,
      );

      final orderRepo = InMemoryOrderRepository([existingOrder]);
      final getOrdersUseCase = GetCustomerOrdersUseCase(orderRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: OrdersHistoryPage(
            session: testSession,
            getCustomerOrdersUseCase: getOrdersUseCase,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pedido #ORD-HIST-01'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Cerveza Club 330ml'), findsOneWidget);
      expect(find.text('Precio congelado: \$2.40 c/u (Retornable)'), findsOneWidget);
      expect(find.text('Total Inalterable:'), findsOneWidget);
      expect(find.text('\$15.40'), findsOneWidget); // 14.40 + 1.00 = 15.40
    });
  });
}
