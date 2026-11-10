import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/consulta_servicio.dart';
import '../../domain/entities/event_service.dart';
import '../../domain/entities/ficha_servicio.dart';
import '../../domain/usecases/crear_consulta_servicio_use_case.dart';
import '../../domain/usecases/obtener_consultas_servicio_use_case.dart';
import '../../infrastructure/repositories/in_memory_consulta_servicio_repository.dart';
import '../controllers/consultas_controller.dart';

/// Formulario guiado para que un cliente solicite una cotización / consulta
/// a un proveedor de servicios de eventos.
class SolicitarConsultaPage extends StatefulWidget {
  final FichaServicio ficha;
  final ConsultasController? controller;
  final String customerId;
  final String? initialCustomerName;
  final String? initialCustomerPhone;

  const SolicitarConsultaPage({
    super.key,
    required this.ficha,
    this.controller,
    this.customerId = 'customer-demo',
    this.initialCustomerName,
    this.initialCustomerPhone,
  });

  @override
  State<SolicitarConsultaPage> createState() => _SolicitarConsultaPageState();
}

class _SolicitarConsultaPageState extends State<SolicitarConsultaPage> {
  late final ConsultasController _controller;
  late final bool _isControllerInternal;

  final _formKey = GlobalKey<FormState>();
  final _eventDateController = TextEditingController();
  final _guestCountController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.initialCustomerName ?? '';
    _phoneController.text = widget.initialCustomerPhone ?? '';

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
        // Fallback autónomo para pruebas de widget o arranques aislados.
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
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (_isControllerInternal) {
      _controller.dispose();
    }
    _eventDateController.dispose();
    _guestCountController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickEventDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now.add(const Duration(days: 7));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
      helpText: 'Fecha tentativa del evento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _eventDateController.text = _formatDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final consulta = ConsultaServicio(
      id: '',
      serviceId: widget.ficha.id,
      serviceTitle: widget.ficha.title,
      providerId: widget.ficha.providerId,
      customerId: widget.customerId,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      eventDate: _eventDateController.text.trim(),
      guestCount: int.tryParse(_guestCountController.text.trim()) ?? 0,
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      budgetOffered: double.tryParse(_budgetController.text.trim()) ?? 0.0,
      status: ConsultaServicioStatus.pendiente,
      createdAt: '',
    );

    final created = await _controller.crearConsulta(consulta);

    if (!mounted) return;

    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'No se pudo enviar la consulta',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.mark_email_read_outlined,
          color: Colors.green,
          size: 42,
        ),
        title: const Text('¡Consulta enviada!'),
        content: Text(
          'Tu solicitud para "${widget.ficha.title}" fue registrada. '
          'El proveedor podrá responder con una cotización y podrás '
          'dar seguimiento desde "Mis Consultas de Eventos".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );

    if (mounted) {
      Navigator.pop(context, created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Solicitar Cotización'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ServiceSummary(ficha: widget.ficha),
              const SizedBox(height: 20),
              const Text(
                'Datos del evento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('consulta_event_date_field'),
                controller: _eventDateController,
                decoration: InputDecoration(
                  labelText: 'Fecha tentativa del evento *',
                  hintText: 'AAAA-MM-DD',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar_outlined),
                    tooltip: 'Elegir fecha',
                    onPressed: _pickEventDate,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return 'Selecciona la fecha tentativa del evento';
                  }
                  final parsed = DateTime.tryParse(text);
                  if (parsed == null) {
                    return 'Usa el formato AAAA-MM-DD';
                  }
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final eventDay = DateTime(
                    parsed.year,
                    parsed.month,
                    parsed.day,
                  );
                  if (eventDay.isBefore(today)) {
                    return 'La fecha no puede ser anterior a hoy';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('consulta_guest_count_field'),
                      controller: _guestCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Invitados estimados *',
                        hintText: 'Ej. 80',
                        prefixIcon: const Icon(Icons.groups_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        final count = int.tryParse((value ?? '').trim());
                        if (count == null || count <= 0) {
                          return 'Ingresa un número válido';
                        }
                        if (count > 10000) {
                          return 'Verifica la cantidad';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: const Key('consulta_budget_field'),
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Presupuesto (opcional)',
                        hintText: 'Ej. 250.00',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return null;
                        final budget = double.tryParse(text);
                        if (budget == null || budget < 0) {
                          return 'Monto inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('consulta_location_field'),
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Ubicación del evento *',
                  hintText: 'Dirección, sector o local',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 5) {
                    return 'Indica la ubicación del evento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Datos de contacto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('consulta_name_field'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nombre de contacto *',
                  hintText: '¿Quién solicita la cotización?',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 3) {
                    return 'Ingresa tu nombre completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('consulta_phone_field'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono de contacto *',
                  hintText: '0991234567',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  final phone = (value ?? '').trim();
                  final digits = phone.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 7 || digits.length > 15) {
                    return 'Ingresa un teléfono válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('consulta_notes_field'),
                controller: _notesController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Notas o requerimientos especiales',
                  hintText:
                      'Ej. Barra frente a la piscina, música hasta las 2am...',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (_controller.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withAlpha(90)),
                  ),
                  child: Text(
                    _controller.errorMessage!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('consulta_submit_button'),
                  onPressed: _controller.isSending ? null : _submit,
                  icon: _controller.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    _controller.isSending
                        ? 'Enviando consulta...'
                        : 'Enviar Consulta al Proveedor',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '* Campos obligatorios',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceSummary extends StatelessWidget {
  final FichaServicio ficha;

  const _ServiceSummary({required this.ficha});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withAlpha(50)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: Icon(_iconForType(ficha.serviceType)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ficha.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ficha.locationLabel} · \$${ficha.estimatedPrice.toStringAsFixed(2)} ref.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(EventServiceType type) {
    switch (type) {
      case EventServiceType.bartender:
        return Icons.local_bar;
      case EventServiceType.iceAndCoolers:
        return Icons.ac_unit;
      case EventServiceType.soundAndDj:
        return Icons.speaker_group;
      case EventServiceType.customCocktailBar:
        return Icons.liquor;
      case EventServiceType.other:
        return Icons.celebration;
    }
  }
}
