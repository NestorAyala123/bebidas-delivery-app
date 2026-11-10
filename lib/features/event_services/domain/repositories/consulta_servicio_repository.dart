import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/consulta_servicio.dart';

/// Contrato de persistencia para las consultas / cotizaciones de eventos.
///
/// Dominio puro: sin Firebase, Flutter ni HTTP.
abstract class ConsultaServicioRepository {
  /// Registra una nueva consulta y devuelve la copia persistida.
  Future<Result<ConsultaServicio, Failure>> createConsulta(
    ConsultaServicio consulta,
  );

  /// Historial de consultas realizadas por un cliente.
  Future<Result<List<ConsultaServicio>, Failure>> getConsultasByCustomer(
    String customerId,
  );

  /// Historial de consultas recibidas por un proveedor.
  Future<Result<List<ConsultaServicio>, Failure>> getConsultasByProvider(
    String providerId,
  );

  /// Historial de consultas asociadas a una ficha/servicio.
  Future<Result<List<ConsultaServicio>, Failure>> getConsultasByService(
    String serviceId,
  );
}
