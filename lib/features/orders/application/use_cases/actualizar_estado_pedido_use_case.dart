import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/services/order_flow_service.dart';

/// Valida la transición y la persiste en el repositorio de pedidos.
class ActualizarEstadoPedidoUseCase {
  final OrderRepository _repository;
  final OrderFlowService flowService;

  const ActualizarEstadoPedidoUseCase(
    this._repository, {
    this.flowService = const OrderFlowService(),
  });

  Future<Result<Order, Failure>> call({
    required Order order,
    required OrderStatus next,
  }) async {
    final transition = flowService.transition(order, next);
    if (transition.isFailure) {
      return FailureResult(transition.failureOrNull!);
    }

    final updated = transition.dataOrNull!;
    final persisted = await _repository.updateOrderStatus(updated.id, next);
    if (persisted.isFailure) {
      return FailureResult(persisted.failureOrNull!);
    }
    return Success(updated);
  }
}
