import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/consulta_servicio.dart';
import '../repositories/consulta_servicio_repository.dart';

/// Caso de uso para consultar el historial de solicitudes de eventos.
///
/// Permite filtrar por cliente, proveedor o servicio. Debe indicarse al
/// menos un criterio para evitar consultas masivas sin contexto.
class ObtenerConsultasServicioUseCase {
  final ConsultaServicioRepository _repository;

  const ObtenerConsultasServicioUseCase(this._repository);

  Future<Result<List<ConsultaServicio>, Failure>> call({
    String? customerId,
    String? providerId,
    String? serviceId,
  }) {
    final customer = customerId?.trim() ?? '';
    final provider = providerId?.trim() ?? '';
    final service = serviceId?.trim() ?? '';

    if (customer.isEmpty && provider.isEmpty && service.isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure(
            'Indica un cliente, proveedor o servicio para consultar el historial',
          ),
        ),
      );
    }

    if (customer.isNotEmpty) {
      return _repository.getConsultasByCustomer(customer);
    }

    if (provider.isNotEmpty) {
      return _repository.getConsultasByProvider(provider);
    }

    return _repository.getConsultasByService(service);
  }
}
