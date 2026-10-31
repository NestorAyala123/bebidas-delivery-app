import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/event_service.dart';
import '../../domain/entities/ficha_servicio.dart';
import '../../domain/usecases/publicar_ficha_use_case.dart';
import '../controllers/event_services_controller.dart';

/// Pantalla con formulario para publicar una ficha básica de proveedor de eventos.
class PublicarFichaPage extends StatefulWidget {
  final EventServicesController? controller;

  const PublicarFichaPage({super.key, this.controller});

  @override
  State<PublicarFichaPage> createState() => _PublicarFichaPageState();
}

class _PublicarFichaPageState extends State<PublicarFichaPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  EventServiceType _selectedType = EventServiceType.bartender;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final now = DateTime.now().toIso8601String();

    final nuevaFicha = FichaServicio(
      id: '',
      providerId: 'prov-user-current',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      serviceType: _selectedType,
      estimatedPrice: price,
      locationLabel: _locationController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      createdAt: now,
      isAvailable: true,
    );

    if (widget.controller != null) {
      final res = await widget.controller!.publishFicha(nuevaFicha);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      switch (res) {
        case Success():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Ficha de servicio publicada con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        case FailureResult(:final failure):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.toString()),
              backgroundColor: Colors.red,
            ),
          );
      }
    } else {
      // Resolución directa por UseCase si no se inyectó controlador específico
      final useCase = ServiceLocator.instance.isRegistered<PublicarFichaUseCase>()
          ? ServiceLocator.instance.get<PublicarFichaUseCase>()
          : null;

      if (useCase != null) {
        final res = await useCase(nuevaFicha);
        if (!mounted) return;
        setState(() => _isSubmitting = false);

        switch (res) {
          case Success():
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Ficha de servicio publicada con éxito!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          case FailureResult(:final failure):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
              ),
            );
        }
      } else {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Ficha de Eventos'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datos de la Ficha Básica',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Publica tu servicio para que los clientes que organizan fiestas o eventos puedan contratarte.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Tipo de Servicio
              const Text(
                'Categoría de Servicio',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<EventServiceType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.category),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(
                    value: EventServiceType.bartender,
                    child: Text('Bartender / Coctelero'),
                  ),
                  DropdownMenuItem(
                    value: EventServiceType.iceAndCoolers,
                    child: Text('Hielo y Enfriadores'),
                  ),
                  DropdownMenuItem(
                    value: EventServiceType.soundAndDj,
                    child: Text('Sonido y DJ'),
                  ),
                  DropdownMenuItem(
                    value: EventServiceType.customCocktailBar,
                    child: Text('Barra de Cocteles Móvil'),
                  ),
                  DropdownMenuItem(
                    value: EventServiceType.other,
                    child: Text('Otro Servicio para Eventos'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Título
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título del Servicio *',
                  hintText: 'Ej. Bartender Profesional para Bodas',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 3) {
                    return 'Ingresa un título de al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Precio Estimado
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Precio Estimado (USD) *',
                  hintText: '150.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa un precio referencial';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Ingresa un monto numérico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Teléfono de Contacto
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono / WhatsApp *',
                  hintText: '+593 99 123 4567',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El teléfono de contacto es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ubicación / Zona de cobertura
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Zona de Cobertura / Ciudad *',
                  hintText: 'Ej. Manta, Portoviejo, Manabí',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Indica la ciudad o zona de cobertura';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Descripción y Alcance *',
                  hintText: 'Detalla lo que incluye tu servicio (horas de atención, equipos, insumos...)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Botón Publicar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.publish),
                  label: Text(
                    _isSubmitting ? 'Publicando...' : 'Publicar Ficha Básica',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

