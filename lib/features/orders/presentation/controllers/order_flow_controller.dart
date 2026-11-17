import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../application/use_cases/actualizar_estado_pedido_use_case.dart';
import '../../application/use_cases/confirmar_checkout_use_case.dart';
import '../../application/use_cases/registrar_metodo_pago_use_case.dart';
import '../../application/use_cases/resolver_ausencia_repartidores_use_case.dart';
import '../../application/use_cases/seleccionar_modalidad_entrega_use_case.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/services/order_flow_service.dart';
import '../../../delivery/domain/entities/delivery_mode.dart';

/// Controlador del checkout y del ciclo de vida del pedido.
class OrderFlowController extends ChangeNotifier {
  final OrderRepository orderRepository;
  final SeleccionarModalidadEntregaUseCase seleccionarModalidadUseCase;
  final RegistrarMetodoPagoUseCase registrarMetodoPagoUseCase;
  final ActualizarEstadoPedidoUseCase actualizarEstadoUseCase;
  final ResolverAusenciaRepartidoresUseCase resolverAusenciaUseCase;
  final ConfirmarCheckoutUseCase confirmarCheckoutUseCase;

  final bool storeHasOwnDelivery;
  final bool storeAllowsExternalDelivery;
  final bool storeAllowsPickup;

  List<Order> _orders = [];
  Order? _activeOrder;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  OrderFlowController({
    required this.orderRepository,
    this.storeHasOwnDelivery = true,
    this.storeAllowsExternalDelivery = true,
    this.storeAllowsPickup = true,
  }) : seleccionarModalidadUseCase = const SeleccionarModalidadEntregaUseCase(),
       registrarMetodoPagoUseCase = const RegistrarMetodoPagoUseCase(),
       actualizarEstadoUseCase = ActualizarEstadoPedidoUseCase(orderRepository),
       resolverAusenciaUseCase = ResolverAusenciaRepartidoresUseCase(
         orderRepository,
       ),
       confirmarCheckoutUseCase = ConfirmarCheckoutUseCase(orderRepository);

  List<Order> get orders => List.unmodifiable(_orders);
  Order? get activeOrder => _activeOrder;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  bool get supportsOwnDelivery => storeHasOwnDelivery;
  bool get supportsExternalDriver => storeAllowsExternalDelivery;
  bool get supportsPickup => storeAllowsPickup;

  List<OrderNoDriversAction> get noDriverActions => [
    OrderNoDriversAction.wait,
    OrderNoDriversAction.increaseOffer,
    if (storeAllowsPickup) OrderNoDriversAction.pickupAtStore,
    if (storeHasOwnDelivery) OrderNoDriversAction.useStoreOwnDelivery,
    OrderNoDriversAction.cancelOrder,
  ];

  Future<void> loadOrders(String customerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await orderRepository.getOrdersByCustomer(customerId);
    switch (result) {
      case Success(:final data):
        _orders = data;
      case FailureResult(:final failure):
        _errorMessage = failure.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await orderRepository.getOrderById(orderId);
    switch (result) {
      case Success(:final data):
        _activeOrder = data;
      case FailureResult(:final failure):
        _errorMessage = failure.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  bool selectDeliveryMode(DeliveryMode mode, {double? deliveryFee}) {
    final order = _activeOrder;
    if (order == null) return false;

    final result = seleccionarModalidadUseCase(
      order: order,
      mode: mode,
      storeHasOwnDelivery: storeHasOwnDelivery,
      storeAllowsExternalDelivery: storeAllowsExternalDelivery,
      storeAllowsPickup: storeAllowsPickup,
      deliveryFee: deliveryFee,
    );

    return _applyResult(result, success: 'Modalidad de entrega actualizada');
  }

  bool registerPayment(PaymentMethod method) {
    final order = _activeOrder;
    if (order == null) return false;

    final result = registrarMetodoPagoUseCase(order: order, method: method);
    return _applyResult(result, success: 'Método de pago registrado');
  }

  Future<bool> confirmCheckout() async {
    final order = _activeOrder;
    if (order == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await confirmarCheckoutUseCase(order);
    _isSaving = false;

    switch (result) {
      case Success(:final data):
        _activeOrder = data;
        _successMessage = 'Checkout confirmado. Ya puedes buscar repartidor.';
        notifyListeners();
        return true;
      case FailureResult(:final failure):
        _errorMessage = failure.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> advanceTo(OrderStatus next) async {
    final order = _activeOrder;
    if (order == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await actualizarEstadoUseCase(order: order, next: next);
    _isSaving = false;

    switch (result) {
      case Success(:final data):
        _activeOrder = data;
        _replaceInList(data);
        _successMessage = 'Estado actualizado a ${next.name}';
        notifyListeners();
        return true;
      case FailureResult(:final failure):
        _errorMessage = failure.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> resolveNoDrivers(
    OrderNoDriversAction action, {
    double? increasedFee,
  }) async {
    final order = _activeOrder;
    if (order == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await resolverAusenciaUseCase(
      order: order,
      action: action,
      storeHasOwnDelivery: storeHasOwnDelivery,
      storeAllowsPickup: storeAllowsPickup,
      increasedFee: increasedFee,
    );

    _isSaving = false;
    switch (result) {
      case Success(:final data):
        _activeOrder = data.order;
        _replaceInList(data.order);
        _successMessage = data.message;
        notifyListeners();
        return true;
      case FailureResult(:final failure):
        _errorMessage = failure.message;
        notifyListeners();
        return false;
    }
  }

  bool _applyResult(Result<Order, dynamic> result, {required String success}) {
    switch (result) {
      case Success(:final data):
        _activeOrder = data;
        _successMessage = success;
        _errorMessage = null;
        notifyListeners();
        return true;
      case FailureResult(:final failure):
        _errorMessage = failure.message;
        notifyListeners();
        return false;
    }
  }

  void _replaceInList(Order order) {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      _orders[index] = order;
    } else {
      _orders.add(order);
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
