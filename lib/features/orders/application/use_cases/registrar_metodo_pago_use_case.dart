import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/services/order_flow_service.dart';

/// Registra el método de pago elegido: efectivo o transferencia.
class RegistrarMetodoPagoUseCase {
  final OrderFlowService flowService;

  const RegistrarMetodoPagoUseCase({
    this.flowService = const OrderFlowService(),
  });

  Result<Order, Failure> call({
    required Order order,
    required PaymentMethod method,
  }) {
    return flowService.registerPaymentMethod(order: order, method: method);
  }
}
