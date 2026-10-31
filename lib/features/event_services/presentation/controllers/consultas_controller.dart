import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/consulta_servicio.dart';
import '../../domain/usecases/crear_consulta_servicio_use_case.dart';
import '../../domain/usecases/obtener_consultas_servicio_use_case.dart';

/// Controlador de presentación para el flujo de consultas / cotizaciones
/// de servicios de eventos.
class ConsultasController extends ChangeNotifier {
  final CrearConsultaServicioUseCase crearConsultaServicioUseCase;
  final ObtenerConsultasServicioUseCase obtenerConsultasServicioUseCase;

  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _successMessage;
  List<ConsultaServicio> _consultas = [];

  ConsultasController({
    required this.crearConsultaServicioUseCase,
    required this.obtenerConsultasServicioUseCase,
  });

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<ConsultaServicio> get consultas => List.unmodifiable(_consultas);

  int get pendingCount => _consultas
      .where((consulta) => consulta.status == ConsultaServicioStatus.pendiente)
      .length;

  int get answeredCount => _consultas
      .where((consulta) => consulta.status == ConsultaServicioStatus.respondida)
      .length;

  int get acceptedCount => _consultas
      .where((consulta) => consulta.status == ConsultaServicioStatus.aceptada)
      .length;

  /// Carga el historial de consultas del cliente o proveedor indicado.
  Future<void> loadConsultas({
    String? customerId,
    String? providerId,
    String? serviceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await obtenerConsultasServicioUseCase(
      customerId: customerId,
      providerId: providerId,
      serviceId: serviceId,
    );

    switch (result) {
      case Success(:final data):
        _consultas = data;
        _errorMessage = null;
      case FailureResult(:final failure):
        _errorMessage = failure.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Registra una consulta y devuelve la entidad persistida.
  Future<ConsultaServicio?> crearConsulta(ConsultaServicio consulta) async {
    _isSending = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await crearConsultaServicioUseCase(consulta);

    switch (result) {
      case Success(:final data):
        _consultas = [data, ..._consultas];
        _successMessage = 'Consulta enviada correctamente al proveedor';
        _isSending = false;
        notifyListeners();
        return data;
      case FailureResult(:final failure):
        _errorMessage = failure.message;
        _isSending = false;
        notifyListeners();
        return null;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
