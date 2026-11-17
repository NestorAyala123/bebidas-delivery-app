import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../../domain/entities/delivery_request.dart';
import '../../domain/use_cases/accept_delivery_offer_use_case.dart';
import '../../domain/use_cases/get_delivery_history_use_case.dart';
import '../../domain/use_cases/get_delivery_offers_use_case.dart';
import '../../domain/use_cases/get_driver_availability_use_case.dart';
import '../../domain/use_cases/get_pending_delivery_requests_use_case.dart';
import '../../domain/use_cases/reject_delivery_offer_use_case.dart';
import '../../domain/use_cases/set_driver_availability_use_case.dart';
import '../../domain/use_cases/submit_delivery_offer_use_case.dart';
import '../utils/delivery_formatters.dart';
import '../widgets/delivery_status_chip.dart';
import 'delivery_history_page.dart';
import 'delivery_request_detail_page.dart';
import 'driver_availability_page.dart';

/// Pantalla principal del flujo de ofertas de delivery.
///
/// - Repartidor: consulta solicitudes pendientes y accede a la negociación.
/// - Cliente / comercio: consulta únicamente sus propias solicitudes en
///   negociación para comparar y responder a las ofertas.
///
/// El filtrado por propietario es solo de visibilidad: la autorización
/// definitiva la aplican los casos de uso y el repositorio.
class DeliveryOffersPage extends StatefulWidget {
  final IdentityContract identity;
  final GetPendingDeliveryRequestsUseCase? getPendingRequestsUseCase;
  final GetDeliveryOffersUseCase? getOffersUseCase;
  final SubmitDeliveryOfferUseCase? submitOfferUseCase;
  final AcceptDeliveryOfferUseCase? acceptOfferUseCase;
  final RejectDeliveryOfferUseCase? rejectOfferUseCase;
  final GetDeliveryHistoryUseCase? getDeliveryHistoryUseCase;

  const DeliveryOffersPage({
    super.key,
    required this.identity,
    this.getPendingRequestsUseCase,
    this.getOffersUseCase,
    this.submitOfferUseCase,
    this.acceptOfferUseCase,
    this.rejectOfferUseCase,
    this.getDeliveryHistoryUseCase,
  });

  @override
  State<DeliveryOffersPage> createState() => _DeliveryOffersPageState();
}

class _DeliveryOffersPageState extends State<DeliveryOffersPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<DeliveryRequest> _requests = const [];

  GetPendingDeliveryRequestsUseCase get _getPendingRequests =>
      widget.getPendingRequestsUseCase ??
      sl.get<GetPendingDeliveryRequestsUseCase>();

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _getPendingRequests();

    if (!mounted) return;

    if (result.isSuccess) {
      final all = result.dataOrNull ?? const <DeliveryRequest>[];
      setState(() {
        _requests = _scopeRequests(all);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage =
            result.failureOrNull?.message ?? 'Error al cargar solicitudes';
        _isLoading = false;
      });
    }
  }

  /// Acota la lista según el rol. Es un filtro de visibilidad de la vista;
  /// la autorización definitiva permanece en los casos de uso.
  List<DeliveryRequest> _scopeRequests(List<DeliveryRequest> requests) {
    return switch (widget.identity.rbacRole) {
      Role.driver => List<DeliveryRequest>.unmodifiable(requests),
      Role.client =>
        requests.where((r) => r.customerId == widget.identity.id).toList(),
      Role.store =>
        requests.where((r) => r.storeId == widget.identity.id).toList(),
      Role.eventProvider => const <DeliveryRequest>[],
    };
  }

  String get _title => switch (widget.identity.rbacRole) {
    Role.driver => 'Ofertas de Delivery',
    Role.client => 'Mis Solicitudes de Delivery',
    Role.store => 'Delivery del Comercio',
    Role.eventProvider => 'Delivery',
  };

  String get _emptyMessage => switch (widget.identity.rbacRole) {
    Role.driver => 'No hay solicitudes pendientes para ofertar.',
    Role.client => 'No tienes solicitudes de delivery en negociación.',
    Role.store =>
      'No hay solicitudes de delivery de tu comercio en negociación.',
    Role.eventProvider => 'El módulo de delivery está disponible para clientes, comercios y repartidores.',
  };

  Future<void> _openAvailability() async {
    if (!sl.isRegistered<GetDriverAvailabilityUseCase>() ||
        !sl.isRegistered<SetDriverAvailabilityUseCase>()) {
      _showSnackBar('La gestión de disponibilidad no está configurada.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverAvailabilityPage(
          driverId: widget.identity.id,
          getAvailabilityUseCase: sl.get<GetDriverAvailabilityUseCase>(),
          setAvailabilityUseCase: sl.get<SetDriverAvailabilityUseCase>(),
        ),
      ),
    );

    if (mounted) {
      await _loadRequests();
    }
  }

  Future<void> _openRequest(DeliveryRequest request) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryRequestDetailPage(
          request: request,
          identity: widget.identity,
          getOffersUseCase: widget.getOffersUseCase,
          submitOfferUseCase: widget.submitOfferUseCase,
          acceptOfferUseCase: widget.acceptOfferUseCase,
          rejectOfferUseCase: widget.rejectOfferUseCase,
        ),
      ),
    );

    // Una asignación retira la solicitud de la lista de pendientes.
    if (mounted) {
      await _loadRequests();
    }
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryHistoryPage(
          identity: widget.identity,
          getDeliveryHistoryUseCase: widget.getDeliveryHistoryUseCase,
          getOffersUseCase: widget.getOffersUseCase,
          submitOfferUseCase: widget.submitOfferUseCase,
          acceptOfferUseCase: widget.acceptOfferUseCase,
          rejectOfferUseCase: widget.rejectOfferUseCase,
        ),
      ),
    );

    if (mounted) {
      await _loadRequests();
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: _isLoading ? null : _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _isLoading ? null : _loadRequests,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade900, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRequests,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final isDriver = widget.identity.rbacRole == Role.driver;

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (isDriver) _buildDriverCard(),
          if (isDriver) const SizedBox(height: 8),
          if (_requests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    _emptyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          else
            ..._requests.map(_buildRequestCard),
        ],
      ),
    );
  }

  Widget _buildDriverCard() {
    return Card(
      color: Colors.orange.shade50,
      child: ListTile(
        leading: const Icon(Icons.two_wheeler, color: Colors.deepOrange),
        title: Text(widget.identity.displayName),
        subtitle: const Text(
          'Gestiona tu disponibilidad antes de enviar ofertas.',
        ),
        trailing: TextButton(
          key: const Key('manage-driver-availability'),
          onPressed: _openAvailability,
          child: const Text('Gestionar'),
        ),
      ),
    );
  }

  Widget _buildRequestCard(DeliveryRequest request) {
    final isDriver = widget.identity.rbacRole == Role.driver;

    return Card(
      key: Key('request-${request.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openRequest(request),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Solicitud #${request.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  DeliveryStatusChip(status: request.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('Origen: ${request.originAddress}'),
              const SizedBox(height: 4),
              Text('Destino: ${request.destinationAddress}'),
              const SizedBox(height: 4),
              Text(
                'Modalidad: ${deliveryModeLabel(request.deliveryMode.name)}',
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    request.distanceInKm != null
                        ? '${request.distanceInKm} km'
                        : 'Distancia no especificada',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    formatMoney(request.referenceFare),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isDriver
                          ? 'Toca para ver las ofertas y proponer una tarifa.'
                          : 'Toca para comparar las ofertas recibidas.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
