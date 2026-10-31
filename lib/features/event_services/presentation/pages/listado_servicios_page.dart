import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/event_service.dart';
import '../../domain/entities/ficha_servicio.dart';
import '../../domain/usecases/obtener_servicios_use_case.dart';
import '../../domain/usecases/publicar_ficha_use_case.dart';
import '../../infrastructure/repositories/in_memory_ficha_servicio_repository.dart';
import '../controllers/event_services_controller.dart';
import 'detalle_ficha_page.dart';
import 'mis_consultas_page.dart';
import 'publicar_ficha_page.dart';

/// Pantalla para consultar y filtrar las fichas básicas de proveedores de eventos.
///
/// Implementa:
/// - Consulta de fichas desde el caso de uso y repositorio en infraestructura.
/// - Filtrado interactivo por categorías de evento (Bartender, Hielo, Sonido, Barra, etc.).
/// - Buscador por texto en tiempo real.
/// - Acceso a publicación de nuevas fichas mediante [PublicarFichaPage].
/// - Consulta detallada de la ficha mediante [DetalleFichaPage].
class ListadoServiciosPage extends StatefulWidget {
  final EventServicesController? controller;

  const ListadoServiciosPage({super.key, this.controller});

  @override
  State<ListadoServiciosPage> createState() => _ListadoServiciosPageState();
}

class _ListadoServiciosPageState extends State<ListadoServiciosPage> {
  late final EventServicesController _controller;
  bool _isControllerInternal = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _isControllerInternal = true;
      final obtener = ServiceLocator.instance.isRegistered<ObtenerServiciosUseCase>()
          ? ServiceLocator.instance.get<ObtenerServiciosUseCase>()
          : null;
      final publicar = ServiceLocator.instance.isRegistered<PublicarFichaUseCase>()
          ? ServiceLocator.instance.get<PublicarFichaUseCase>()
          : null;

      if (obtener != null && publicar != null) {
        _controller = EventServicesController(
          obtenerServiciosUseCase: obtener,
          publicarFichaUseCase: publicar,
        );
      } else {
        // Fallback autónomo si la pantalla se prueba sin contenedor previo
        final repo = InMemoryFichaServicioRepository();
        _controller = EventServicesController(
          obtenerServiciosUseCase: ObtenerServiciosUseCase(repo),
          publicarFichaUseCase: PublicarFichaUseCase(repo),
        );
      }
    }

    _controller.addListener(_onControllerUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadFichas();
    });
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _searchController.dispose();
    if (_isControllerInternal) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Servicios para Eventos'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Mis Consultas de Eventos',
            onPressed: _navigateToMisConsultas,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Publicar Ficha',
            onPressed: _navigateToPublish,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de Búsqueda ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar proveedor o servicio...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _controller.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) => _controller.setSearchQuery(val),
            ),
          ),

          // ── Selector de Categorías (Chips) ────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _controller.selectedType == null,
                  onSelected: (_) => _controller.filterByType(null),
                ),
                const SizedBox(width: 8),
                ...EventServiceType.values.map((type) {
                  final isSelected = _controller.selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(_typeLabel(type)),
                      selected: isSelected,
                      onSelected: (_) => _controller.filterByType(type),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── Estado de Carga o Error ───────────────────────────────────────
          if (_controller.isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Consultando fichas de eventos...'),
                  ],
                ),
              ),
            )
          else if (_controller.errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        _controller.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _controller.loadFichas(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_controller.filteredFichas.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No se encontraron fichas para este criterio',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        _controller.setSearchQuery('');
                        _controller.filterByType(null);
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar filtros'),
                    ),
                  ],
                ),
              ),
            )
          else
            // ── Lista de Fichas Básicas ─────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: _controller.filteredFichas.length,
                itemBuilder: (context, index) {
                  final ficha = _controller.filteredFichas[index];
                  return _FichaCard(
                    ficha: ficha,
                    onTap: () => _navigateToDetail(ficha),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToPublish,
        icon: const Icon(Icons.add),
        label: const Text('Publicar servicio'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  void _navigateToDetail(FichaServicio ficha) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleFichaPage(ficha: ficha),
      ),
    );
  }

  void _navigateToMisConsultas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MisConsultasPage(),
      ),
    );
  }

  void _navigateToPublish() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PublicarFichaPage(controller: _controller),
      ),
    );

    if (created == true) {
      _controller.loadFichas();
    }
  }

  static String _typeLabel(EventServiceType type) => switch (type) {
        EventServiceType.bartender => 'Bartender',
        EventServiceType.iceAndCoolers => 'Hielo & Enfriadores',
        EventServiceType.soundAndDj => 'Sonido & DJ',
        EventServiceType.customCocktailBar => 'Barra de Cocteles',
        EventServiceType.other => 'Otro',
      };
}

// ── FichaCard Widget ─────────────────────────────────────────────────────────

class _FichaCard extends StatelessWidget {
  final FichaServicio ficha;
  final VoidCallback onTap;

  const _FichaCard({required this.ficha, required this.onTap});

  static const Map<EventServiceType, IconData> _icons = {
    EventServiceType.bartender: Icons.sports_bar,
    EventServiceType.iceAndCoolers: Icons.ac_unit,
    EventServiceType.soundAndDj: Icons.music_note,
    EventServiceType.customCocktailBar: Icons.local_bar,
    EventServiceType.other: Icons.miscellaneous_services,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _icons[ficha.serviceType] ?? Icons.miscellaneous_services;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ficha.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ficha.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _InfoChip(
                          icon: Icons.location_on,
                          label: ficha.locationLabel,
                        ),
                        _InfoChip(
                          icon: Icons.attach_money,
                          label: '\$${ficha.estimatedPrice.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('Consultar ficha'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

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
