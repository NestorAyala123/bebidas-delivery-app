import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../../domain/entities/delivery_request.dart';
import '../../domain/use_cases/accept_delivery_offer_use_case.dart';
import '../../domain/use_cases/get_delivery_history_use_case.dart';
import '../../domain/use_cases/get_delivery_offers_use_case.dart';
import '../../domain/use_cases/get_delivery_rating_use_case.dart';
import '../../domain/use_cases/register_delivery_rating_use_case.dart';
import '../../domain/use_cases/reject_delivery_offer_use_case.dart';
import '../../domain/use_cases/submit_delivery_offer_use_case.dart';
import '../utils/delivery_formatters.dart';
import '../widgets/delivery_status_chip.dart';
import 'delivery_request_detail_page.dart';

/// Pantalla de historial de delivery por usuario autenticado.
///
/// - Cliente: solicitudes asociadas a su customerId.
/// - Comercio: solicitudes asociadas a su storeId.
/// - Repartidor: operaciones en las que participó (asignaciones vigentes o
///   negociaciones con ofertas).
///
/// Cada operación se muestra en una tarjeta y permite consultar el detalle,
/// reutilizando el motor de negociación de `DeliveryRequestDetailPage`.
class DeliveryHistoryPage extends StatefulWidget {
  final IdentityContract identity;
  final GetDeliveryHistoryUseCase? getDeliveryHistoryUseCase;
  final GetDeliveryOffersUseCase? getOffersUseCase;
  final SubmitDeliveryOfferUseCase? submitOfferUseCase;
  final AcceptDeliveryOfferUseCase? acceptOfferUseCase;
  final RejectDeliveryOfferUseCase? rejectOfferUseCase;
  final GetDeliveryRatingUseCase? getDeliveryRatingUseCase;
  final RegisterDeliveryRatingUseCase? registerDeliveryRatingUseCase;

  const DeliveryHistoryPage({
    super.key,
    required this.identity,
    this.getDeliveryHistoryUseCase,
    this.getOffersUseCase,
    this.submitOfferUseCase,
    this.acceptOfferUseCase,
    this.rejectOfferUseCase,
    this.getDeliveryRatingUseCase,
    this.registerDeliveryRatingUseCase,
  });

  @override
  State<DeliveryHistoryPage> createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<DeliveryRequest> _history = const [];

  GetDeliveryHistoryUseCase get _getHistory =>
      widget.getDeliveryHistoryUseCase ?? sl.get<GetDeliveryHistoryUseCase>();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _getHistory(identity: widget.identity);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _history = result.dataOrNull ?? const <DeliveryRequest>[];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage =
            result.failureOrNull?.message ?? 'Error al cargar el historial';
        _isLoading = false;
      });
    }
  }

  Future<void> _openOperation(DeliveryRequest request) async {
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
          getDeliveryRatingUseCase: widget.getDeliveryRatingUseCase,
          registerDeliveryRatingUseCase: widget.registerDeliveryRatingUseCase,
        ),
      ),
    );

    // Si la operación se resolvió desde el detalle, refrescar el historial.
    if (mounted) {
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _isLoading ? null : _loadHistory,
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
                onPressed: _loadHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
              child: Column(
                children: [
                  Icon(Icons.history_outlined, size: 48, color: Colors.grey),
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
            ..._history.map(_buildHistoryCard),
        ],
      ),
    );
  }

  String get _emptyMessage => switch (widget.identity.rbacRole) {
    Role.driver => 'No hay operaciones de delivery para este repartidor.',
    Role.client => 'No tienes solicitudes de delivery registradas.',
    Role.store => 'No hay operaciones de delivery para este comercio.',
    Role.eventProvider => 'El historial de delivery está disponible para clientes, comercios y repartidores.',
  };

  Widget _buildHistoryCard(DeliveryRequest request) {
    final agreedFare = request.agreedFareInCents;

    return Card(
      key: Key('history-${request.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openOperation(request),
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
              Text('Pedido: ${request.orderId}'),
              const SizedBox(height: 4),
              Text('Fecha: ${formatDateTime(request.createdAt)}'),
              const SizedBox(height: 4),
              Text('Origen: ${request.originAddress}'),
              const SizedBox(height: 4),
              Text('Destino: ${request.destinationAddress}'),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tarifa de referencia'),
                  Text(
                    formatCents((request.referenceFare * 100).round()),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (agreedFare != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tarifa acordada'),
                    Text(
                      formatCents(agreedFare),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ],
              if (request.assignedDriverId != null) ...[
                const SizedBox(height: 4),
                Text('Repartidor asignado: ${request.assignedDriverId}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
