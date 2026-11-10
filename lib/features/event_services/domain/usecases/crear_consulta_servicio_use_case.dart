import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/consulta_servicio.dart';
import '../repositories/consulta_servicio_repository.dart';

/// Caso de uso para validar y registrar una consulta / solicitud de
/// cotización enviada por un cliente a un proveedor de eventos.
///
/// Reglas de dominio puras:
/// - La ficha, el proveedor y el cliente deben estar identificados.
/// - El nombre del cliente debe tener al menos 3 caracteres.
/// - El teléfono debe contener entre 7 y 15 dígitos.
/// - La fecha tentativa debe ser válida y no anterior a hoy.
/// - La cantidad de invitados debe ser mayor que cero.
/// - La ubicación del evento es obligatoria.
/// - El presupuesto ofrecido no puede ser negativo.
class CrearConsultaServicioUseCase {
  final ConsultaServicioRepository _repository;

  const CrearConsultaServicioUseCase(this._repository);

  Future<Result<ConsultaServicio, Failure>> call(
    ConsultaServicio consulta,
  ) async {
    final serviceId = consulta.serviceId.trim();
    if (serviceId.isEmpty) {
      return const FailureResult(
        ValidationFailure('La consulta debe estar asociada a un servicio'),
      );
    }

    final serviceTitle = consulta.serviceTitle.trim();
    if (serviceTitle.isEmpty) {
      return const FailureResult(
        ValidationFailure('El título del servicio es obligatorio'),
      );
    }

    final providerId = consulta.providerId.trim();
    if (providerId.isEmpty) {
      return const FailureResult(
        ValidationFailure('La consulta debe estar asociada a un proveedor'),
      );
    }

    final customerId = consulta.customerId.trim();
    if (customerId.isEmpty) {
      return const FailureResult(
        ValidationFailure('La consulta debe estar asociada a un cliente'),
      );
    }

    final customerName = consulta.customerName.trim();
    if (customerName.length < 3) {
      return const FailureResult(
        ValidationFailure(
          'El nombre del cliente debe tener al menos 3 caracteres',
        ),
      );
    }

    final customerPhone = consulta.customerPhone.trim();
    final phoneDigits = customerPhone.replaceAll(RegExp(r'\D'), '');
    final phoneFormatValid = RegExp(r'^[0-9+\s()\-]+$').hasMatch(customerPhone);
    if (customerPhone.isEmpty ||
        !phoneFormatValid ||
        phoneDigits.length < 7 ||
        phoneDigits.length > 15) {
      return const FailureResult(
        ValidationFailure(
          'Ingresa un teléfono de contacto válido (entre 7 y 15 dígitos)',
        ),
      );
    }

    final eventDate = consulta.eventDate.trim();
    final parsedDate = DateTime.tryParse(eventDate);
    if (parsedDate == null) {
      return const FailureResult(
        ValidationFailure(
          'La fecha tentativa del evento no es válida. Usa el formato AAAA-MM-DD',
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
    );
    if (eventDay.isBefore(today)) {
      return const FailureResult(
        ValidationFailure(
          'La fecha tentativa del evento no puede ser anterior a hoy',
        ),
      );
    }

    if (consulta.guestCount <= 0) {
      return const FailureResult(
        ValidationFailure(
          'La cantidad estimada de invitados debe ser mayor que cero',
        ),
      );
    }

    if (consulta.guestCount > 10000) {
      return const FailureResult(
        ValidationFailure(
          'La cantidad de invitados parece demasiado alta. Verifica el dato.',
        ),
      );
    }

    final location = consulta.location.trim();
    if (location.isEmpty) {
      return const FailureResult(
        ValidationFailure('La ubicación del evento es obligatoria'),
      );
    }

    if (consulta.budgetOffered < 0) {
      return const FailureResult(
        ValidationFailure('El presupuesto ofrecido no puede ser negativo'),
      );
    }

    final sanitized = consulta.copyWith(
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      providerId: providerId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      eventDate: eventDate,
      location: location,
      notes: consulta.notes.trim(),
      status: ConsultaServicioStatus.pendiente,
      createdAt: consulta.createdAt.trim().isEmpty
          ? DateTime.now().toIso8601String()
          : consulta.createdAt.trim(),
    );

    return _repository.createConsulta(sanitized);
  }
}
