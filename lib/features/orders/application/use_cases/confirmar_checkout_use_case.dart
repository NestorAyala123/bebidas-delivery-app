import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/services/order_flow_service.dart';

/// Confirma el checkout: exige pago registrado y persiste las decisiones.
class ConfirmarCheckoutUseCase {
  final OrderRepository _repository;
  final OrderFlowService flowService;

  const ConfirmarCheckoutUseCase(
    this._repository, {
    this.flowService = const OrderFlowService(),
  });

  Future<Result<Order, Failure>> call(Order order) async {
    final ready = flowService.validatePaymentReady(order);
    if (ready.isFailure) {
      return FailureResult(ready.failureOrNull!);
    }

    final persisted = await _repository.createOrder(order);
    return persisted;
  }
}
