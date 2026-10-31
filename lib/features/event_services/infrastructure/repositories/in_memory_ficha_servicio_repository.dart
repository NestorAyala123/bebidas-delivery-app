import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/event_service.dart';
import '../../domain/entities/ficha_servicio.dart';
import '../../domain/repositories/ficha_servicio_repository.dart';

/// Implementación en memoria del repositorio de fichas de proveedores de eventos.
///
/// Proporciona persistencia durante el ciclo de vida de la aplicación y datos iniciales
/// realistas para consultas, pruebas automatizadas y demostraciones.
class InMemoryFichaServicioRepository implements FichaServicioRepository {
  final List<FichaServicio> _fichas;

  InMemoryFichaServicioRepository({List<FichaServicio>? initialFichas})
      : _fichas = initialFichas != null
            ? List<FichaServicio>.from(initialFichas)
            : [
                const FichaServicio(
                  id: 'svc-001',
                  providerId: 'prov-001',
                  title: 'Bartender Profesional para Fiestas',
                  description:
                      'Coctelería artesanal y de autor: mojitos, gin tonic, pisco sour y margaritas. Incluye cristalería y herramientas profesionales para bodas y recepciones.',
                  serviceType: EventServiceType.bartender,
                  estimatedPrice: 150.00,
                  locationLabel: 'Manta, Manabí',
                  contactPhone: '+593 99 111 2233',
                  createdAt: '2026-10-20T10:00:00Z',
                  isAvailable: true,
                ),
                const FichaServicio(
                  id: 'svc-002',
                  providerId: 'prov-002',
                  title: 'Hielo en Bloque y Enfriadores Express',
                  description:
                      'Distribución urgente de hielo en cubos, frappé y bloques refrigerados. Alquiler de conservadoras térmicas grandes para mantener tus bebidas frías todo el evento.',
                  serviceType: EventServiceType.iceAndCoolers,
                  estimatedPrice: 80.00,
                  locationLabel: 'Portoviejo y Manta, Manabí',
                  contactPhone: '+593 98 444 5566',
                  createdAt: '2026-10-21T11:30:00Z',
                  isAvailable: true,
                ),
                const FichaServicio(
                  id: 'svc-003',
                  providerId: 'prov-003',
                  title: 'DJ & Equipo de Sonido JBL',
                  description:
                      'Sets de música crossover en vivo, altavoces JBL activos de alta fidelidad, microfonía inalámbrica y torres de luces robóticas LED para hasta 300 invitados.',
                  serviceType: EventServiceType.soundAndDj,
                  estimatedPrice: 300.00,
                  locationLabel: 'Manta, Manabí',
                  contactPhone: '+593 96 777 8899',
                  createdAt: '2026-10-22T14:15:00Z',
                  isAvailable: true,
                ),
                const FichaServicio(
                  id: 'svc-004',
                  providerId: 'prov-004',
                  title: 'Barra Móvil Iluminada & Cocteles',
                  description:
                      'Montaje de barra portátil moderna con iluminación neón, insumos de alta gama, jarabes botánicos hechos en casa y 2 bármanes con atención por 5 horas.',
                  serviceType: EventServiceType.customCocktailBar,
                  estimatedPrice: 220.00,
                  locationLabel: 'Barbasquillo / Manta, Manabí',
                  contactPhone: '+593 99 333 0011',
                  createdAt: '2026-10-23T16:00:00Z',
                  isAvailable: true,
                ),
                const FichaServicio(
                  id: 'svc-005',
                  providerId: 'prov-005',
                  title: 'Maridaje y Pasabocas Gourmet',
                  description:
                      'Tablas de quesos finos, jamones curados, frutos secos y selección de vinos tintos y blancos especialmente elegidos para reuniones ejecutivas.',
                  serviceType: EventServiceType.other,
                  estimatedPrice: 180.00,
                  locationLabel: 'Manta, Manabí',
                  contactPhone: '+593 95 888 9900',
                  createdAt: '2026-10-24T09:45:00Z',
                  isAvailable: true,
                ),
              ];

  @override
  Future<Result<List<FichaServicio>, Failure>> getAllFichas() async {
    // Retorna ordenadas por fecha más reciente
    final list = List<FichaServicio>.from(_fichas);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(list);
  }

  @override
  Future<Result<List<FichaServicio>, Failure>> getFichasByType(
    EventServiceType serviceType,
  ) async {
    final list = _fichas
        .where((f) => f.serviceType == serviceType)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(list);
  }

  @override
  Future<Result<List<FichaServicio>, Failure>> getFichasByProvider(
    String providerId,
  ) async {
    final list = _fichas
        .where((f) => f.providerId == providerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(list);
  }

  @override
  Future<Result<FichaServicio, Failure>> getFichaById(String id) async {
    try {
      final ficha = _fichas.firstWhere((f) => f.id == id);
      return Success(ficha);
    } catch (_) {
      return FailureResult(
        NotFoundFailure('No se encontró la ficha de servicio con ID: $id'),
      );
    }
  }

  @override
  Future<Result<FichaServicio, Failure>> publishFicha(FichaServicio ficha) async {
    final id = ficha.id.isEmpty
        ? 'svc-${DateTime.now().millisecondsSinceEpoch}'
        : ficha.id;
    final createdAt = ficha.createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : ficha.createdAt;

    final newFicha = ficha.copyWith(id: id, createdAt: createdAt);

    // Si ya existe (actualización), la reemplaza; si no, la agrega
    final index = _fichas.indexWhere((f) => f.id == id);
    if (index >= 0) {
      _fichas[index] = newFicha;
    } else {
      _fichas.add(newFicha);
    }

    return Success(newFicha);
  }

  @override
  Future<Result<void, Failure>> deleteFicha(String id) async {
    _fichas.removeWhere((f) => f.id == id);
    return const Success(null);
  }
}

