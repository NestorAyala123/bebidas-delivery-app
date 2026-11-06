import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';

/// Port that tells the chat who answers for a store or an event service.
///
/// Contracts from the work plan:
/// - Catálogo → chat: `storeId` → owner user (`Store.ownerId`).
/// - Servicios → chat: `serviceId` → `providerId`.
///
/// The chat module does not read the stores or event-services repositories
/// directly; an infrastructure adapter implements this port.
abstract class ChatCounterpartDirectory {
  /// User id of the person who answers for [storeId].
  Future<Result<String, Failure>> storeOwnerId(String storeId);

  /// User id of the provider that published [serviceId].
  Future<Result<String, Failure>> serviceProviderId(String serviceId);
}
