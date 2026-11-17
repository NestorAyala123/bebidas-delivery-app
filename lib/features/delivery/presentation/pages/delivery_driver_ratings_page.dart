import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../ratings/domain/entities/rating.dart';
import '../../domain/use_cases/get_driver_ratings_use_case.dart';
import '../utils/delivery_formatters.dart';

/// Pantalla de historial de calificaciones recibidas por un repartidor.
///
/// - Muestra puntuación, comentario y fecha de cada calificación.
/// - Muestra promedio y cantidad de calificaciones cuando los datos existen.
/// - Estado vacío cuando el repartidor aún no tiene calificaciones.
class DeliveryDriverRatingsPage extends StatefulWidget {
  final IdentityContract identity;
  final GetDriverRatingsUseCase? getDriverRatingsUseCase;

  const DeliveryDriverRatingsPage({
    super.key,
    required this.identity,
    this.getDriverRatingsUseCase,
  });

  @override
  State<DeliveryDriverRatingsPage> createState() =>
      _DeliveryDriverRatingsPageState();
}

class _DeliveryDriverRatingsPageState extends State<DeliveryDriverRatingsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Rating> _ratings = const [];

  GetDriverRatingsUseCase get _getDriverRatings =>
      widget.getDriverRatingsUseCase ?? sl.get<GetDriverRatingsUseCase>();

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _getDriverRatings(
      driverId: widget.identity.id,
      driverIdentity: widget.identity,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _ratings = result.dataOrNull ?? const <Rating>[];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage =
            result.failureOrNull?.message ??
            'Error al cargar las calificaciones';
        _isLoading = false;
      });
    }
  }

  double get _averageScore {
    if (_ratings.isEmpty) return 0;
    final total = _ratings.fold<int>(0, (sum, r) => sum + r.score);
    return total / _ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Calificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: _isLoading ? null : _loadRatings,
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
                onPressed: _loadRatings,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_ratings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_outline, size: 48, color: Colors.amber),
              const SizedBox(height: 12),
              const Text(
                'Aún no tiene calificaciones recibidas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRatings,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Promedio de calificaciones',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_averageScore.toStringAsFixed(1)} / 5',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Calificaciones recibidas (${_ratings.length})'),
          const SizedBox(height: 8),
          ..._ratings.map(_buildRatingCard),
        ],
      ),
    );
  }

  Widget _buildRatingCard(Rating rating) {
    return Card(
      key: Key('driver-rating-${rating.deliveryRequestId}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Entrega #${rating.deliveryRequestId}')),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${rating.score} / 5',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              rating.hasComment
                  ? 'Comentario: ${rating.comment}'
                  : 'Sin comentario.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text('Fecha: ${formatDateTime(rating.createdAt)}'),
          ],
        ),
      ),
    );
  }
}
