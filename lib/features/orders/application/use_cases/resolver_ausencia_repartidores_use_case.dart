import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/services/order_flow_service.dart';

/// Aplica la alternativa elegida ante la ausencia de repartidores (RN03).
class ResolverAusenciaRepartidoresUseCase {
  final OrderRepository _repository;
  final OrderFlowService flowService;

  const ResolverAusenciaRepartidoresUseCase(
    this._repository, {
    this.flowService = const OrderFlowService(),
  });

  Future<Result<NoDriversResolution, Failure>> call({
    required Order order,
    required OrderNoDriversAction action,
    required bool storeHasOwnDelivery,
    required bool storeAllowsPickup,
    double? increasedFee,
  }) async {
    final result = flowService.resolveNoDrivers(
      order: order,
      action: action,
      storeHasOwnDelivery: storeHasOwnDelivery,
      storeAllowsPickup: storeAllowsPickup,
      increasedFee: increasedFee,
    );

    if (result.isFailure) {
      return FailureResult(result.failureOrNull!);
    }

    final resolution = result.dataOrNull!;
    final persisted = await _repository.createOrder(resolution.order);
    if (persisted.isFailure) {
      return FailureResult(persisted.failureOrNull!);
    }

    return Success(resolution);
  }
}
