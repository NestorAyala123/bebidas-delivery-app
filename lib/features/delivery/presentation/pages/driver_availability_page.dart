import 'package:flutter/material.dart';

import '../../domain/entities/driver_status.dart';
import '../../domain/use_cases/get_driver_availability_use_case.dart';
import '../../domain/use_cases/set_driver_availability_use_case.dart';

/// Pantalla mínima para consultar y alternar el estado operativo del repartidor.
/// 100% desacoplada de infrastructure/, solo depende de domain/.
class DriverAvailabilityPage extends StatefulWidget {
  final String driverId;
  final GetDriverAvailabilityUseCase getAvailabilityUseCase;
  final SetDriverAvailabilityUseCase setAvailabilityUseCase;

  const DriverAvailabilityPage({
    super.key,
    this.driverId = 'driver-1',
    required this.getAvailabilityUseCase,
    required this.setAvailabilityUseCase,
  });

  @override
  State<DriverAvailabilityPage> createState() => _DriverAvailabilityPageState();
}

class _DriverAvailabilityPageState extends State<DriverAvailabilityPage> {
  DriverStatus? _currentStatus;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.getAvailabilityUseCase(widget.driverId);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _currentStatus = result.dataOrNull;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage =
            result.failureOrNull?.message ?? 'Error al consultar disponibilidad';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAvailability() async {
    if (_isLoading) return;

    final targetStatus = _currentStatus == DriverStatus.available
        ? DriverStatus.busy
        : DriverStatus.available;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.setAvailabilityUseCase(
      driverId: widget.driverId,
      status: targetStatus,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _currentStatus = targetStatus;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage =
            result.failureOrNull?.message ?? 'Error al actualizar disponibilidad';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disponibilidad del Repartidor'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                'Repartidor: ${widget.driverId}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (_isLoading && _currentStatus == null)
                const CircularProgressIndicator()
              else ...[
                Text(
                  _currentStatus == DriverStatus.available
                      ? 'Disponible'
                      : 'Ocupado',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _currentStatus == DriverStatus.available
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _toggleAvailability,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _currentStatus == DriverStatus.available
                              ? Icons.do_not_disturb_on
                              : Icons.check_circle,
                        ),
                  label: Text(
                    _currentStatus == DriverStatus.available
                        ? 'Cambiar a Ocupado'
                        : 'Cambiar a Disponible',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
