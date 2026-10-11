import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failures.dart';
import '../../../products/application/use_cases/save_product_use_case.dart';
import '../../../products/application/use_cases/update_product_availability_use_case.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../application/use_cases/save_store_use_case.dart';
import '../../application/use_cases/update_store_status_use_case.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';

class StoreManagementPage extends StatefulWidget {
  const StoreManagementPage({super.key});

  @override
  State<StoreManagementPage> createState() => _StoreManagementPageState();
}

class _StoreManagementPageState extends State<StoreManagementPage> {
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productImageController = TextEditingController();
  final _storeRepository = sl.get<StoreRepository>();
  final _productRepository = sl.get<ProductRepository>();
  late final SaveStoreUseCase _saveStore;
  late final UpdateStoreStatusUseCase _updateStoreStatus;
  late final SaveProductUseCase _saveProduct;
  late final UpdateProductAvailabilityUseCase _updateProductAvailability;
  List<Store> _stores = [];
  List<Product> _products = [];
  Store? _selectedStore;
  bool _isOpen = true;
  bool _hasOwnDelivery = false;
  bool _allowsExternalDelivery = true;
  bool _allowsPickup = true;

  @override
  void initState() {
    super.initState();
    _saveStore = sl.get<SaveStoreUseCase>();
    _updateStoreStatus = sl.get<UpdateStoreStatusUseCase>();
    _saveProduct = sl.get<SaveProductUseCase>();
    _updateProductAvailability = sl.get<UpdateProductAvailabilityUseCase>();
    _loadStores();
  }

  @override
  void dispose() {
    for (final controller in [
      _storeNameController,
      _storeAddressController,
      _storePhoneController,
      _storeDescriptionController,
      _productNameController,
      _productPriceController,
      _productImageController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStores() async {
    final result = await _storeRepository.getStores();
    if (!mounted) return;
    result.fold(
      onSuccess: (stores) async {
        setState(() {
          _stores = stores;
          _selectedStore ??= stores.isEmpty ? null : stores.first;
        });
        if (_selectedStore != null) _loadStoreForm(_selectedStore!);
        await _loadProducts();
      },
      onFailure: _showFailure,
    );
  }

  void _loadStoreForm(Store store) {
    _storeNameController.text = store.name;
    _storeAddressController.text = store.address;
    _storePhoneController.text = store.phone;
    _storeDescriptionController.text = store.description;
    _isOpen = store.isOpen;
    _hasOwnDelivery = store.hasOwnDelivery;
    _allowsExternalDelivery = store.allowsExternalDelivery;
    _allowsPickup = store.allowsPickup;
  }

  Future<void> _loadProducts() async {
    final store = _selectedStore;
    if (store == null) {
      setState(() => _products = []);
      return;
    }
    final result = await _productRepository.getProductsByStore(store.id);
    if (!mounted) return;
    result.fold(
      onSuccess: (products) => setState(() => _products = products),
      onFailure: _showFailure,
    );
  }

  Future<void> _saveStoreForm() async {
    final store = Store(
      id:
          _selectedStore?.id ??
          'store-${DateTime.now().microsecondsSinceEpoch}',
      ownerId: _selectedStore?.ownerId ?? 'current-user',
      name: _storeNameController.text,
      description: _storeDescriptionController.text,
      address: _storeAddressController.text,
      phone: _storePhoneController.text,
      isOpen: _isOpen,
      hasOwnDelivery: _hasOwnDelivery,
      allowsExternalDelivery: _allowsExternalDelivery,
      allowsPickup: _allowsPickup,
    );
    final result = await _saveStore(store);
    if (!mounted) return;
    result.fold(
      onSuccess: (saved) {
        _selectedStore = saved;
        _showMessage('Comercio guardado');
        _loadStores();
      },
      onFailure: _showFailure,
    );
  }

  Future<void> _saveProductForm() async {
    final store = _selectedStore;
    final price = double.tryParse(_productPriceController.text);
    if (store == null || price == null) {
      _showFailure(
        const ValidationFailure('Selecciona un comercio y un precio válido'),
      );
      return;
    }
    final result = await _saveProduct(
      Product(
        id: 'product-${DateTime.now().microsecondsSinceEpoch}',
        storeId: store.id,
        name: _productNameController.text,
        basePrice: price,
        imageUrl: _productImageController.text.trim().isEmpty
            ? null
            : _productImageController.text.trim(),
      ),
    );
    if (!mounted) return;
    result.fold(
      onSuccess: (_) {
        _productNameController.clear();
        _productPriceController.clear();
        _productImageController.clear();
        _showMessage('Producto guardado');
        _loadProducts();
      },
      onFailure: _showFailure,
    );
  }

  Future<void> _toggleStoreStatus(bool value) async {
    final store = _selectedStore;
    if (store == null) return;
    final result = await _updateStoreStatus(storeId: store.id, isOpen: value);
    if (!mounted) return;
    result.fold(
      onSuccess: (_) {
        setState(
          () => _selectedStore = Store(
            id: store.id,
            ownerId: store.ownerId,
            name: store.name,
            description: store.description,
            address: store.address,
            phone: store.phone,
            openingHours: store.openingHours,
            latitude: store.latitude,
            longitude: store.longitude,
            imageUrl: store.imageUrl,
            isOpen: value,
            hasOwnDelivery: store.hasOwnDelivery,
            allowsExternalDelivery: store.allowsExternalDelivery,
            allowsPickup: store.allowsPickup,
          ),
        );
        _showMessage(value ? 'Comercio abierto' : 'Comercio cerrado');
      },
      onFailure: _showFailure,
    );
  }

  Future<void> _toggleProduct(Product product, bool value) async {
    final result = await _updateProductAvailability(
      productId: product.id,
      isAvailable: value,
    );
    if (!mounted) return;
    result.fold(onSuccess: (_) => _loadProducts(), onFailure: _showFailure);
  }

  void _showFailure(Failure failure) => _showMessage(failure.message);

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis comercios y productos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStoreForm(),
          const SizedBox(height: 24),
          _buildProductForm(),
          const SizedBox(height: 16),
          ..._products.map(_buildProductTile),
        ],
      ),
    );
  }

  Widget _buildStoreForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Comercio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _field(_storeNameController, 'Nombre'),
            _field(_storeAddressController, 'Dirección'),
            _field(_storePhoneController, 'Teléfono'),
            _field(_storeDescriptionController, 'Descripción'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Comercio abierto'),
              value: _isOpen,
              onChanged: (value) => setState(() => _isOpen = value),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Delivery propio'),
              value: _hasOwnDelivery,
              onChanged: (value) =>
                  setState(() => _hasOwnDelivery = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Repartidor de plataforma'),
              value: _allowsExternalDelivery,
              onChanged: (value) =>
                  setState(() => _allowsExternalDelivery = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Retiro en local'),
              value: _allowsPickup,
              onChanged: (value) =>
                  setState(() => _allowsPickup = value ?? false),
            ),
            FilledButton(
              onPressed: _saveStoreForm,
              child: const Text('Guardar comercio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Producto básico',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            DropdownButton<Store>(
              isExpanded: true,
              value: _selectedStore,
              hint: const Text('Selecciona un comercio'),
              items: _stores
                  .map(
                    (store) =>
                        DropdownMenuItem(value: store, child: Text(store.name)),
                  )
                  .toList(),
              onChanged: (store) {
                if (store == null) return;
                setState(() {
                  _selectedStore = store;
                  _loadStoreForm(store);
                });
                _loadProducts();
              },
            ),
            _field(_productNameController, 'Nombre del producto'),
            _field(
              _productPriceController,
              'Precio base',
              keyboardType: TextInputType.number,
            ),
            _field(_productImageController, 'URL de imagen (opcional)'),
            FilledButton(
              onPressed: _selectedStore == null ? null : _saveProductForm,
              child: const Text('Guardar producto'),
            ),
            if (_selectedStore != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Comercio abierto/cerrado'),
                value: _selectedStore!.isOpen,
                onChanged: _toggleStoreStatus,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(Product product) {
    return ListTile(
      leading: product.imageUrl == null
          ? const Icon(Icons.local_drink)
          : Image.network(
              product.imageUrl!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
      title: Text(product.name),
      subtitle: Text('\$${product.basePrice.toStringAsFixed(2)}'),
      trailing: Switch(
        value: product.isAvailable,
        onChanged: (value) => _toggleProduct(product, value),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
