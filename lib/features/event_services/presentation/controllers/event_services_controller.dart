import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/event_service.dart';
import '../../domain/entities/ficha_servicio.dart';
import '../../domain/usecases/obtener_servicios_use_case.dart';
import '../../domain/usecases/publicar_ficha_use_case.dart';

/// Controlador para la gestión y consulta de fichas básicas de proveedores de eventos.
class EventServicesController extends ChangeNotifier {
  final ObtenerServiciosUseCase obtenerServiciosUseCase;
  final PublicarFichaUseCase publicarFichaUseCase;

  bool _isLoading = false;
  bool _isPublishing = false;
  String? _errorMessage;
  List<FichaServicio> _fichas = [];
  EventServiceType? _selectedType;
  String _searchQuery = '';

  EventServicesController({
    required this.obtenerServiciosUseCase,
    required this.publicarFichaUseCase,
  });

  bool get isLoading => _isLoading;
  bool get isPublishing => _isPublishing;
  String? get errorMessage => _errorMessage;
  List<FichaServicio> get fichas => _fichas;
  EventServiceType? get selectedType => _selectedType;
  String get searchQuery => _searchQuery;

  /// Retorna las fichas filtradas por el término de búsqueda actual
  List<FichaServicio> get filteredFichas {
    if (_searchQuery.trim().isEmpty) {
      return _fichas;
    }
    final q = _searchQuery.toLowerCase().trim();
    return _fichas.where((f) {
      return f.title.toLowerCase().contains(q) ||
          f.description.toLowerCase().contains(q) ||
          f.locationLabel.toLowerCase().contains(q);
    }).toList();
  }

  /// Carga la lista de fichas desde el caso de uso
  Future<void> loadFichas({EventServiceType? serviceType}) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedType = serviceType;
    notifyListeners();

    final result = await obtenerServiciosUseCase(serviceType: serviceType);

    switch (result) {
      case Success(:final data):
        _fichas = data;
        _errorMessage = null;
      case FailureResult(:final failure):
        _errorMessage = failure.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Cambia el filtro de categoría y recarga
  Future<void> filterByType(EventServiceType? type) async {
    if (_selectedType == type) {
      // Toggle off si ya está seleccionado
      _selectedType = null;
    } else {
      _selectedType = type;
    }
    await loadFichas(serviceType: _selectedType);
  }

  /// Actualiza el query de búsqueda local
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Publica una nueva ficha básica y la añade a la lista activa
  Future<Result<FichaServicio, Object>> publishFicha(FichaServicio ficha) async {
    _isPublishing = true;
    _errorMessage = null;
    notifyListeners();

    final result = await publicarFichaUseCase(ficha);

    switch (result) {
      case Success(:final data):
        // Recargar fichas para reflejar la recién publicada
        await loadFichas(serviceType: _selectedType);
        _isPublishing = false;
        notifyListeners();
        return Success(data);
      case FailureResult(:final failure):
        _isPublishing = false;
        _errorMessage = failure.message;
        notifyListeners();
        return FailureResult(failure);
    }
  }
}

