import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../chat/domain/entities/chat_conversation.dart';
import '../../../chat/presentation/chat_launcher.dart';
import '../../domain/entities/consulta_servicio.dart';
import '../../domain/usecases/crear_consulta_servicio_use_case.dart';
import '../../domain/usecases/obtener_consultas_servicio_use_case.dart';
import '../../infrastructure/repositories/in_memory_consulta_servicio_repository.dart';
import '../controllers/consultas_controller.dart';

enum _ConsultaFilter { todas, pendientes, respondidas, aceptadas }

/// Pantalla de seguimiento de las consultas / cotizaciones de eventos.
///
/// El cliente puede revisar el estado de cada solicitud y abrir un canal
/// directo de chat con el proveedor (módulo Chat de Nibia).
class MisConsultasPage extends StatefulWidget {
  final ConsultasController? controller;
  final String customerId;
  final String? providerId;

  const MisConsultasPage({
    super.key,
    this.controller,
    this.customerId = 'customer-demo',
    this.providerId,
  });

  @override
  State<MisConsultasPage> createState() => _MisConsultasPageState();
}

class _MisConsultasPageState extends State<MisConsultasPage> {
  late final ConsultasController _controller;
  late final bool _isControllerInternal;
  _ConsultaFilter _filter = _ConsultaFilter.todas;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _controller = widget.controller!;
      _isControllerInternal = false;
    } else {
      _isControllerInternal = true;
      final crear =
          ServiceLocator.instance.isRegistered<CrearConsultaServicioUseCase>()
          ? ServiceLocator.instance.get<CrearConsultaServicioUseCase>()
          : null;
      final obtener =
          ServiceLocator.instance
              .isRegistered<ObtenerConsultasServicioUseCase>()
          ? ServiceLocator.instance.get<ObtenerConsultasServicioUseCase>()
          : null;

      if (crear != null && obtener != null) {
        _controller = ConsultasController(
          crearConsultaServicioUseCase: crear,
          obtenerConsultasServicioUseCase: obtener,
        );
      } else {
        final repo = InMemoryConsultaServicioRepository();
        _controller = ConsultasController(
          crearConsultaServicioUseCase: CrearConsultaServicioUseCase(repo),
          obtenerConsultasServicioUseCase: ObtenerConsultasServicioUseCase(
            repo,
          ),
        );
      }
    }

    _controller.addListener(_onControllerUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _load() {
    if (widget.providerId != null && widget.providerId!.trim().isNotEmpty) {
      return _controller.loadConsultas(providerId: widget.providerId);
    }
    return _controller.loadConsultas(customerId: widget.customerId);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (_isControllerInternal) {
      _controller.dispose();
    }
    super.dispose();
  }

  List<ConsultaServicio> get _filteredConsultas {
    switch (_filter) {
      case _ConsultaFilter.todas:
        return _controller.consultas;
      case _ConsultaFilter.pendientes:
        return _controller.consultas
            .where(
              (consulta) => consulta.status == ConsultaServicioStatus.pendiente,
            )
            .toList();
      case _ConsultaFilter.respondidas:
        return _controller.consultas
            .where(
              (consulta) =>
                  consulta.status == ConsultaServicioStatus.respondida,
            )
            .toList();
      case _ConsultaFilter.aceptadas:
        return _controller.consultas
            .where(
              (consulta) => consulta.status == ConsultaServicioStatus.aceptada,
            )
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Mis Consultas de Eventos'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar historial',
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_controller.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Consultando tus solicitudes de eventos...'),
          ],
        ),
      );
    }

    if (_controller.errorMessage != null && _controller.consultas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 52, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _controller.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildFilterBar(context),
        Expanded(
          child: _filteredConsultas.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _filteredConsultas.length,
                    itemBuilder: (context, index) {
                      final consulta = _filteredConsultas[index];
                      return _ConsultaCard(
                        consulta: consulta,
                        onChat: () => _openChat(context, consulta),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final filters = <(_ConsultaFilter, String, int)>[
      (_ConsultaFilter.todas, 'Todas', _controller.consultas.length),
      (_ConsultaFilter.pendientes, 'Pendientes', _controller.pendingCount),
      (_ConsultaFilter.respondidas, 'Respondidas', _controller.answeredCount),
      (_ConsultaFilter.aceptadas, 'Aceptadas', _controller.acceptedCount),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: filters.map((item) {
          final (filter, label, count) = item;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$label ($count)'),
              selected: _filter == filter,
              onSelected: (_) => setState(() => _filter = filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Aún no tienes consultas de eventos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Explora las fichas de proveedores y solicita una cotización '
              'para tu próximo evento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.celebration_outlined),
              label: const Text('Explorar servicios'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChat(
    BuildContext context,
    ConsultaServicio consulta,
  ) async {
    await ChatLauncher.open(
      context,
      counterpartId: consulta.providerId,
      counterpartName: 'Proveedor ${consulta.providerId}',
      role: ChatPeerRole.eventProvider,
      contextId: consulta.serviceId,
      contextLabel: consulta.serviceTitle,
      initialMessage: ChatLauncher.buildConsultationMessage(
        serviceTitle: consulta.serviceTitle,
        eventDate: consulta.eventDate,
        guestCount: consulta.guestCount,
        location: consulta.location,
      ),
    );
  }
}

class _ConsultaCard extends StatelessWidget {
  final ConsultaServicio consulta;
  final VoidCallback onChat;

  const _ConsultaCard({required this.consulta, required this.onChat});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    consulta.serviceTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: consulta.status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _InfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: _formatEventDate(consulta.eventDate),
                ),
                _InfoItem(
                  icon: Icons.groups_outlined,
                  label: '${consulta.guestCount} invitados',
                ),
                if (consulta.budgetOffered > 0)
                  _InfoItem(
                    icon: Icons.attach_money,
                    label:
                        '\$${consulta.budgetOffered.toStringAsFixed(2)} ofrecidos',
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _InfoItem(
              icon: Icons.location_on_outlined,
              label: consulta.location,
            ),
            if (consulta.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  consulta.notes,
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Proveedor: ${consulta.providerId}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat con Nibia'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatEventDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final ConsultaServicioStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ConsultaServicioStatus.pendiente => ('Pendiente', Colors.orange),
      ConsultaServicioStatus.respondida => ('Respondida', Colors.blue),
      ConsultaServicioStatus.aceptada => ('Aceptada', Colors.green),
      ConsultaServicioStatus.rechazada => ('Rechazada', Colors.red),
      ConsultaServicioStatus.cancelada => ('Cancelada', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color.shade800,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
