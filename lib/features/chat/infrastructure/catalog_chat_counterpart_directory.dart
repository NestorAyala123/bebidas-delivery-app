import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../event_services/domain/repositories/ficha_servicio_repository.dart';
import '../../stores/domain/repositories/store_repository.dart';
import '../domain/repositories/chat_counterpart_directory.dart';

/// Resolves who answers a chat using the stores and event-services modules.
///
/// [demoLinks] links the sample stores/providers that have no real account yet
/// (map test data, seeded service cards) to the demo accounts. It is
/// development data only: with Firestore, `Store.ownerId` and
/// `FichaServicio.providerId` are real user ids and the map stays empty.
class CatalogChatCounterpartDirectory implements ChatCounterpartDirectory {
  final StoreRepository stores;
  final FichaServicioRepository services;
  final Map<String, String> demoLinks;

  const CatalogChatCounterpartDirectory({
    required this.stores,
    required this.services,
    this.demoLinks = const {},
  });

  @override
  Future<Result<String, Failure>> storeOwnerId(String storeId) async {
    final store = (await stores.getStoreById(storeId)).dataOrNull;
    final ownerId = store?.ownerId ?? '';
    if (ownerId.isNotEmpty) return _resolve(ownerId, 'Comercio no encontrado');
    // Sample stores (map test data) are linked by their own id.
    final linked = demoLinks[storeId];
    if (linked != null) return Success(linked);
    return const FailureResult(
      NotFoundFailure('Este comercio todavía no tiene una cuenta para chatear'),
    );
  }

  @override
  Future<Result<String, Failure>> serviceProviderId(String serviceId) async {
    final ficha = await services.getFichaById(serviceId);
    final providerId = ficha.dataOrNull?.providerId;
    if (providerId == null) {
      return FailureResult(
        ficha.failureOrNull ?? const NotFoundFailure('Servicio no encontrado'),
      );
    }
    return _resolve(providerId, 'Proveedor no encontrado');
  }

  Result<String, Failure> _resolve(String id, String notFound) {
    final resolved = demoLinks[id] ?? id;
    if (resolved.isEmpty) return FailureResult(NotFoundFailure(notFound));
    return Success(resolved);
  }
}

/// Demo accounts behind the sample data of other modules.
class DemoChatLinks {
  DemoChatLinks._();

  static const String demoStoreUserId = 'seed-store';
  static const String demoProviderUserId = 'seed-eventProvider';

  static const Map<String, String> all = {
    // Comercios de prueba del mapa (MockLocationRepository).
    'store-001': demoStoreUserId,
    'store-002': demoStoreUserId,
    'store-003': demoStoreUserId,
    'store-004': demoStoreUserId,
    'store-005': demoStoreUserId,
    // Proveedores de las fichas sembradas (InMemoryFichaServicioRepository).
    'prov-001': demoProviderUserId,
    'prov-002': demoProviderUserId,
    'prov-003': demoProviderUserId,
    'prov-004': demoProviderUserId,
    'prov-005': demoProviderUserId,
  };
}
