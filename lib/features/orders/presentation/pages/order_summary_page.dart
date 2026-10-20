import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/user_session.dart';
import '../../../cart/application/use_cases/clear_cart_use_case.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/domain/repositories/cart_repository.dart';
import '../../../pricing/domain/entities/quantity_pricing_tier.dart';
import '../../application/use_cases/create_order_use_case.dart';
import 'orders_history_page.dart';

/// Screen that presents the cart summary, volume discount tier calculation (RN04),
/// missing container fee deduction (RN05), and order creation in pending state.
class OrderSummaryPage extends StatefulWidget {
  final UserSession session;
  final CreateOrderUseCase? createOrderUseCase;
  final CartRepository? cartRepository;

  const OrderSummaryPage({
    super.key,
    required this.session,
    this.createOrderUseCase,
    this.cartRepository,
  });

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  final _addressController = TextEditingController(
    text: 'Av. 4 de Noviembre y Calle 115, Manta',
  );
  int _returnedContainers = 0;
  bool _isLoading = false;
  Cart _cart = const Cart();

  CartRepository get _cartRepo =>
      widget.cartRepository ??
      (sl.isRegistered<CartRepository>()
          ? sl.get<CartRepository>()
          : throw Exception('CartRepository no registrado'));

  CreateOrderUseCase get _createOrderUseCase =>
      widget.createOrderUseCase ??
      (sl.isRegistered<CreateOrderUseCase>()
          ? sl.get<CreateOrderUseCase>()
          : throw Exception('CreateOrderUseCase no registrado'));

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    final res = await _cartRepo.getCart();
    final cart = res.dataOrNull;
    if (cart != null && mounted) {
      setState(() {
        _cart = cart;
        if (_returnedContainers > _cart.totalReturnableContainers) {
          _returnedContainers = _cart.totalReturnableContainers;
        }
      });
    }
  }

  Future<void> _updateItemQuantity(String productId, int newQuantity) async {
    final updatedCart = _cart.updateQuantity(productId, newQuantity);
    await _cartRepo.saveCart(updatedCart);
    await _loadCart();
  }

  Future<void> _loadDemoProducts() async {
    // Demo product with volume pricing tier:
    // Base price $3.00, but if quantity >= 6, price drops to $2.40.
    // Returnable container deposit is $0.50 per unit.
    const beerItem = CartItem(
      productId: 'prod-cerveza-especial',
      productName: 'Cerveza Club Premium 330ml (Retornable)',
      unitPrice: 3.00,
      basePrice: 3.00,
      quantity: 6,
      isReturnable: true,
      containerDeposit: 0.50,
      quantityTiers: [
        QuantityPricingTier(minQuantity: 6, unitPrice: 2.40),
        QuantityPricingTier(minQuantity: 12, unitPrice: 2.10),
      ],
    );

    const waterItem = CartItem(
      productId: 'prod-agua-mineral',
      productName: 'Agua con Gas Manantial 500ml',
      unitPrice: 1.00,
      basePrice: 1.00,
      quantity: 2,
      isReturnable: false,
      containerDeposit: 0.0,
    );

    var newCart = const Cart();
    newCart = newCart.addItem(targetStoreId: 'store-licorera-central', item: beerItem);
    newCart = newCart.addItem(targetStoreId: 'store-licorera-central', item: waterItem);

    await _cartRepo.saveCart(newCart);
    await _loadCart();
  }

  Future<void> _submitOrder() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una dirección de entrega válida.')),
      );
      return;
    }

    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final input = CreateOrderInput.fromCart(
      customerId: widget.session.userId,
      deliveryAddress: address,
      cart: _cart,
      returnedContainers: _returnedContainers,
    );

    final result = await _createOrderUseCase(input);

    setState(() => _isLoading = false);

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        if (sl.isRegistered<ClearCartUseCase>()) {
          await sl.get<ClearCartUseCase>()();
        } else {
          await _cartRepo.clearCart();
        }
        await _loadCart();

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 52),
              title: const Text('¡Pedido Creado!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID del Pedido: ${data.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Estado: '),
                      Chip(
                        label: Text(
                          data.status.displayName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.orange.shade800,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Importe total congelado: \$${data.total.toStringAsFixed(2)}'),
                  const SizedBox(height: 10),
                  const Text(
                    'Tu pedido está en estado PENDIENTE, esperando confirmación del comercio.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrdersHistoryPage(session: widget.session),
                      ),
                    );
                  },
                  child: const Text('Ver en Historial'),
                ),
              ],
            ),
          );
        }
      case FailureResult(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(failure.message),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calculation = _cart.calculateTotals(
      returnedContainers: _returnedContainers,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen y Creación de Pedido'),
        actions: [
          IconButton(
            tooltip: 'Historial de Pedidos',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrdersHistoryPage(session: widget.session),
                ),
              );
            },
          ),
        ],
      ),
      body: _cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Tu carrito está vacío',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Agrega productos con precios por rango y envases retornables para comprobar el flujo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loadDemoProducts,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Cargar Artículos de Demostración'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Store header
                  Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.storefront, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Comercio: ${_cart.storeId}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text('${_cart.totalItemCount} ítems'),
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Items List Header
                  Text(
                    'Artículos en tu Pedido (Precios por Rango)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Cart Items
                  ..._cart.items.map((item) => _buildCartItemCard(item)),

                  const SizedBox(height: 16),

                  // Returnable Containers Section (RN05)
                  if (_cart.totalReturnableContainers > 0)
                    _buildReturnableContainersCard(calculation),

                  const SizedBox(height: 16),

                  // Delivery Address Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.deepOrange),
                              SizedBox(width: 8),
                              Text(
                                'Dirección de Entrega',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              hintText: 'Ingresa calle y número',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Price Breakdown Card
                  _buildTotalsCard(calculation),

                  const SizedBox(height: 24),

                  // Create Order Button
                  FilledButton(
                    onPressed: _isLoading ? null : _submitOrder,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Confirmar Pedido (Crear como Pendiente)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (item.hasTierDiscount) ...[
                            Text(
                              '\$${item.basePrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '\$${item.unitPrice.toStringAsFixed(2)} c/u',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: item.hasTierDiscount ? Colors.green.shade700 : Colors.black87,
                            ),
                          ),
                          if (item.hasTierDiscount) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Precio por Rango',
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.isReturnable) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Envase retornable (Depósito: \$${item.containerDeposit.toStringAsFixed(2)} c/u)',
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '\$${item.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _updateItemQuantity(item.productId, item.quantity - 1),
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _updateItemQuantity(item.productId, item.quantity + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnableContainersCard(dynamic calculation) {
    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recycling, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Text(
                  'Envases Retornables (RN05)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total de envases requeridos por tu pedido: ${_cart.totalReturnableContainers}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Envases vacíos que entregas al recibir:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _returnedContainers > 0
                          ? () => setState(() => _returnedContainers--)
                          : null,
                    ),
                    Text(
                      '$_returnedContainers',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _returnedContainers < _cart.totalReturnableContainers
                          ? () => setState(() => _returnedContainers++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Envases faltantes a cobrar:',
                  style: TextStyle(color: Colors.amber.shade900),
                ),
                Text(
                  '${calculation.missingContainers} envase(s)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cargo por envases faltantes:',
                  style: TextStyle(color: Colors.amber.shade900),
                ),
                Text(
                  '\$${calculation.missingContainersFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(dynamic calculation) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal productos:'),
                Text(
                  '\$${calculation.itemsSubtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (calculation.missingContainersFee > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Garantía envases faltantes:'),
                  Text(
                    '+\$${calculation.missingContainersFee.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total (Precio Congelado):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '\$${calculation.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
