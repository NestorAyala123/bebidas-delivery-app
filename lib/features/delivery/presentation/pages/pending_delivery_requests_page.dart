import 'package:flutter/material.dart';

import '../../domain/entities/delivery_request.dart';
import '../../domain/use_cases/get_pending_delivery_requests_use_case.dart';

/// Pantalla para que el repartidor visualice las solicitudes de delivery pendientes.
/// 100% desacoplada de infrastructure/, solo consume casos de uso inyectados por constructor.
class PendingDeliveryRequestsPage extends StatefulWidget {
  final GetPendingDeliveryRequestsUseCase getPendingRequestsUseCase;

  const PendingDeliveryRequestsPage({
    super.key,
    required this.getPendingRequestsUseCase,
  });

  @override
  State<PendingDeliveryRequestsPage> createState() =>
      _PendingDeliveryRequestsPageState();
}

class _PendingDeliveryRequestsPageState
    extends State<PendingDeliveryRequestsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<DeliveryRequest> _requests = const [];

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.getPendingRequestsUseCase();

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _requests = result.dataOrNull ?? const [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes Pendientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _isLoading ? null : _loadPendingRequests,
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
          padding: const EdgeInsets.all(16.0),
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
                onPressed: _loadPendingRequests,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Text('No hay solicitudes pendientes disponibles'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Solicitud #${request.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Pendiente',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Origen: ${request.originAddress}'),
                const SizedBox(height: 4),
                Text('Destino: ${request.destinationAddress}'),
                const Divider(height: 16),
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
                      '\$${request.referenceFare.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
