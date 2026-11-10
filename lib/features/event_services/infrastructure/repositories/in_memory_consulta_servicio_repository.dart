import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/consulta_servicio.dart';
import '../../domain/repositories/consulta_servicio_repository.dart';

/// Implementación en memoria del repositorio de consultas de eventos.
///
/// Mantiene las solicitudes durante el ciclo de vida de la aplicación y
/// permite compartir el estado entre el formulario de solicitud y la vista
/// "Mis Consultas de Eventos".
class InMemoryConsultaServicioRepository implements ConsultaServicioRepository {
  final List<ConsultaServicio> _consultas;

  InMemoryConsultaServicioRepository({List<ConsultaServicio>? initialConsultas})
    : _consultas = List<ConsultaServicio>.from(initialConsultas ?? const []);

  List<ConsultaServicio> get consultas => List.unmodifiable(_consultas);

  @override
  Future<Result<ConsultaServicio, Failure>> createConsulta(
    ConsultaServicio consulta,
  ) async {
    final id = consulta.id.trim().isEmpty
        ? 'consulta-${DateTime.now().microsecondsSinceEpoch}'
        : consulta.id.trim();
    final createdAt = consulta.createdAt.trim().isEmpty
        ? DateTime.now().toIso8601String()
        : consulta.createdAt.trim();

    final saved = consulta.copyWith(id: id, createdAt: createdAt);

    final existingIndex = _consultas.indexWhere((item) => item.id == id);
    if (existingIndex >= 0) {
      _consultas[existingIndex] = saved;
    } else {
      _consultas.insert(0, saved);
    }

    return Success(saved);
  }

  @override
  Future<Result<List<ConsultaServicio>, Failure>> getConsultasByCustomer(
    String customerId,
  ) async {
    return Success(_filtered((consulta) => consulta.customerId == customerId));
  }

  @override
  Future<Result<List<ConsultaServicio>, Failure>> getConsultasByProvider(
    String providerId,
  ) async {
    return Success(_filtered((consulta) => consulta.providerId == providerId));
  }

  @override
  Future<Result<List<ConsultaServicio>, Failure>> getConsultasByService(
    String serviceId,
  ) async {
    return Success(_filtered((consulta) => consulta.serviceId == serviceId));
  }

  List<ConsultaServicio> _filtered(bool Function(ConsultaServicio) predicate) {
    final list = _consultas.where(predicate).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
