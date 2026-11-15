import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../../delivery/domain/entities/delivery_status.dart';
import '../../application/use_cases/actualizar_estado_entrega_use_case.dart';
import '../../application/use_cases/calificar_entrega_use_case.dart';
import '../../application/use_cases/cancelar_entrega_use_case.dart';
import '../../application/use_cases/enviar_oferta_repartidor_use_case.dart';
import '../../application/use_cases/obtener_historial_entregas_use_case.dart';
import '../../application/use_cases/obtener_negociacion_use_case.dart';
import '../../application/use_cases/proponer_oferta_cliente_use_case.dart';
import '../../application/use_cases/seleccionar_oferta_repartidor_use_case.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../../domain/repositories/delivery_negotiation_repository.dart';
import '../../domain/services/delivery_lifecycle_service.dart';
import '../../domain/services/offer_negotiation_service.dart';

/// Controlador de la negociación de entrega: propuesta del cliente, ofertas
/// de repartidores, selección única, estados, historial y calificación.
class DeliveryNegotiationController extends ChangeNotifier {
  final DeliveryNegotiationRepository repository;

  final ObtenerNegociacionUseCase obtenerNegociacionUseCase;
  final ObtenerHistorialEntregasUseCase obtenerHistorialUseCase;
  final ProponerOfertaClienteUseCase proponerOfertaUseCase;
  final EnviarOfertaRepartidorUseCase enviarOfertaUseCase;
  final SeleccionarOfertaRepartidorUseCase seleccionarOfertaUseCase;
  final ActualizarEstadoEntregaUseCase actualizarEstadoUseCase;
  final CalificarEntregaUseCase calificarEntregaUseCase;
  final CancelarEntregaUseCase cancelarEntregaUseCase;

  final OfferNegotiationService comparisonService;
  final DeliveryLifecycleService lifecycleService;

  DeliveryNegotiation? _negotiation;
  List<DeliveryNegotiation> _history = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  DeliveryNegotiationController({
    required this.repository,
    this.comparisonService = const OfferNegotiationService(),
    this.lifecycleService = const DeliveryLifecycleService(),
  }) : obtenerNegociacionUseCase = ObtenerNegociacionUseCase(repository),
       obtenerHistorialUseCase = ObtenerHistorialEntregasUseCase(repository),
       proponerOfertaUseCase = ProponerOfertaClienteUseCase(
         repository,
         negotiationService: comparisonService,
       ),
       enviarOfertaUseCase = EnviarOfertaRepartidorUseCase(repository),
       seleccionarOfertaUseCase = SeleccionarOfertaRepartidorUseCase(
         repository,
       ),
       actualizarEstadoUseCase = ActualizarEstadoEntregaUseCase(
         repository,
         lifecycleService: lifecycleService,
       ),
       calificarEntregaUseCase = CalificarEntregaUseCase(repository),
       cancelarEntregaUseCase = CancelarEntregaUseCase(repository);

  DeliveryNegotiation? get negotiation => _negotiation;
  List<DeliveryNegotiation> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  OfferComparison get comparison => comparisonService.compareOffers(
    _negotiation?.comparableOffers ?? const [],
  );

  DeliveryStatus? get nextStatus {
    final negotiation = _negotiation;
    if (negotiation == null) return null;
    return lifecycleService.nextStatus(negotiation.status);
  }

  String get nextActionLabel {
    final negotiation = _negotiation;
    if (negotiation == null) return '';
    return lifecycleService.nextActionLabel(negotiation.status);
  }

  Future<void> loadNegotiation(String negotiationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await obtenerNegociacionUseCase(negotiationId);
    switch (result) {
      case Success(:final data):
        _negotiation = data;
        _replaceInHistory(data);
      case FailureResult(:final failure):
        _errorMessage = failure.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHistory(String customerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await obtenerHistorialUseCase(customerId);
    switch (result) {
      case Success(:final data):
        _history = data;
      case FailureResult(:final failure):
        _errorMessage = failure.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> proposeClientOffer(double amount) async {
    final negotiation = _negotiation;
    if (negotiation == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await proponerOfertaUseCase(
      negotiationId: negotiation.id,
      amount: amount,
    );
    _isSaving = false;
    return _applyResult(
      result,
      success: 'Propuesta enviada a los repartidores',
    );
  }

  Future<bool> addDriverOffer({
    required String driverId,
    required String driverName,
    required double amount,
  }) async {
    final negotiation = _negotiation;
    if (negotiation == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await enviarOfertaUseCase(
      negotiationId: negotiation.id,
      driverId: driverId,
      driverName: driverName,
      amount: amount,
    );
    _isSaving = false;
    return _applyResult(result, success: 'Oferta de $driverName registrada');
  }

  /// Simula el escenario de cierre: dos repartidores envían ofertas y solo
  /// una puede quedar seleccionada.
  Future<bool> simulateTwoDriverOffers() async {
    final negotiation = _negotiation;
    if (negotiation == null) return false;

    final first = await addDriverOffer(
      driverId: 'drv-701',
      driverName: 'Carlos Mendoza',
      amount: _round(negotiation.customerOffer + 0.50),
    );
    if (!first) return false;

    return addDriverOffer(
      driverId: 'drv-702',
      driverName: 'Marcos Vera',
      amount: _round((negotiation.customerOffer - 0.25).clamp(1, 200)),
    );
  }

  Future<bool> selectOffer(String offerId) async {
    final negotiation = _negotiation;
    if (negotiation == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await seleccionarOfertaUseCase(
      negotiationId: negotiation.id,
      offerId: offerId,
    );
    _isSaving = false;
    return _applyResult(
      result,
      success: 'Repartidor asignado y resto de ofertas cerradas',
    );
  }

  Future<bool> advanceStatus({DeliveryStatus? next}) async {
    final negotiation = _negotiation;
    if (negotiation == null) return false;

    final target = next ?? lifecycleService.nextStatus(negotiation.status);
    if (target == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await actualizarEstadoUseCase(
      negotiationId: negotiation.id,
      next: target,
    );
    _isSaving = false;
    return _applyResult(
      result,
      success: 'Estado actualizado a ${target.label}',
    );
  }

  Future<bool> rateDelivery(int stars, {String comment = ''}) async {
    final negotiation = _negotiation;
    if (negotiation == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await calificarEntregaUseCase(
      negotiationId: negotiation.id,
      stars: stars,
      comment: comment,
    );
    _isSaving = false;
    return _applyResult(result, success: '¡Gracias por calificar la entrega!');
  }

  Future<bool> cancelDelivery({String reason = ''}) async {
    final negotiation = _negotiation;
    if (negotiation == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final result = await cancelarEntregaUseCase(
      negotiationId: negotiation.id,
      reason: reason,
    );
    _isSaving = false;
    return _applyResult(result, success: 'Entrega cancelada');
  }

  bool _applyResult(
    Result<DeliveryNegotiation, dynamic> result, {
    required String success,
  }) {
    switch (result) {
      case Success(:final data):
        _negotiation = data;
        _replaceInHistory(data);
        _errorMessage = null;
        _successMessage = success;
        notifyListeners();
        return true;
      case FailureResult(:final failure):
        _errorMessage = failure.message;
        notifyListeners();
        return false;
    }
  }

  void _replaceInHistory(DeliveryNegotiation negotiation) {
    final index = _history.indexWhere((item) => item.id == negotiation.id);
    if (index >= 0) {
      _history[index] = negotiation;
    } else {
      _history.add(negotiation);
    }
  }

  static double _round(num value) => double.parse(value.toStringAsFixed(2));

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
