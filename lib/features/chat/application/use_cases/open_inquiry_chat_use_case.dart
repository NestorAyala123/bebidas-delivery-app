import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_counterpart_directory.dart';
import '../dtos/chat_dtos.dart';
import 'create_conversation_use_case.dart';

/// Opens (or reopens) the chat a client starts from a store or a service card.
///
/// The counterpart is resolved from the store / service, never chosen by the
/// client, so a client can only reach the person who answers for it.
class OpenInquiryChatUseCase {
  final CreateConversationUseCase createConversation;
  final ChatCounterpartDirectory directory;
  final DateTime Function() now;

  OpenInquiryChatUseCase(
    this.createConversation,
    this.directory, {
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  /// Cliente → comercio.
  Future<Result<Conversation, Failure>> forStore({
    required String storeId,
    required String storeName,
    required IdentityContract requester,
  }) async {
    if (requester.rbacRole != Role.client) {
      return const FailureResult(
        UnauthorizedFailure('Solo los clientes pueden escribir a un comercio'),
      );
    }
    final owner = await directory.storeOwnerId(storeId);
    return _open(
      type: ConversationType.storeInquiry,
      counterpart: owner,
      subjectId: storeId,
      subjectTitle: storeName,
      requester: requester,
      unavailable: 'Este comercio todavía no tiene una cuenta para chatear',
    );
  }

  /// Cliente → proveedor de servicios para eventos.
  Future<Result<Conversation, Failure>> forService({
    required String serviceId,
    required String serviceTitle,
    required IdentityContract requester,
  }) async {
    if (requester.rbacRole != Role.client) {
      return const FailureResult(
        UnauthorizedFailure('Solo los clientes pueden consultar un servicio'),
      );
    }
    final provider = await directory.serviceProviderId(serviceId);
    return _open(
      type: ConversationType.serviceInquiry,
      counterpart: provider,
      subjectId: serviceId,
      subjectTitle: serviceTitle,
      requester: requester,
      unavailable: 'Este proveedor todavía no tiene una cuenta para chatear',
    );
  }

  /// Proveedor → cliente que le hizo una consulta sobre [serviceId].
  ///
  /// Only the provider who answers for the service may do it, so a provider
  /// cannot open chats about other providers' services.
  Future<Result<Conversation, Failure>> forServiceCustomer({
    required String serviceId,
    required String serviceTitle,
    required String customerId,
    required IdentityContract requester,
  }) async {
    if (requester.rbacRole != Role.eventProvider) {
      return const FailureResult(
        UnauthorizedFailure('Solo el proveedor puede responder esta consulta'),
      );
    }
    final provider = (await directory.serviceProviderId(serviceId)).dataOrNull;
    if (provider != requester.id) {
      return const FailureResult(
        UnauthorizedFailure('Este servicio no es tuyo'),
      );
    }
    final joinedAt = now();
    final result = await createConversation(
      CreateConversationRequest(
        type: ConversationType.serviceInquiry,
        subjectId: serviceId,
        subjectTitle: serviceTitle.trim().isEmpty ? null : serviceTitle.trim(),
        participants: [
          ConversationParticipant(
            userId: customerId,
            role: '',
            joinedAt: joinedAt,
          ),
          ConversationParticipant(
            userId: requester.id,
            role: requester.rbacRole.value,
            joinedAt: joinedAt,
          ),
        ],
      ),
      requester: requester,
    );
    if (result.failureOrNull is NotFoundFailure) {
      return const FailureResult(
        NotFoundFailure(
          'Este cliente todavía no tiene una cuenta para chatear',
        ),
      );
    }
    return result;
  }

  Future<Result<Conversation, Failure>> _open({
    required ConversationType type,
    required Result<String, Failure> counterpart,
    required String subjectId,
    required String subjectTitle,
    required IdentityContract requester,
    required String unavailable,
  }) async {
    final counterpartId = counterpart.dataOrNull;
    if (counterpartId == null || counterpartId.trim().isEmpty) {
      return FailureResult(
        counterpart.failureOrNull ?? NotFoundFailure(unavailable),
      );
    }
    if (subjectId.trim().isEmpty) {
      return const FailureResult(ValidationFailure('Falta el identificador'));
    }
    final joinedAt = now();
    final result = await createConversation(
      CreateConversationRequest(
        type: type,
        subjectId: subjectId,
        subjectTitle: subjectTitle.trim().isEmpty ? null : subjectTitle.trim(),
        participants: [
          ConversationParticipant(
            userId: requester.id,
            role: requester.rbacRole.value,
            joinedAt: joinedAt,
          ),
          ConversationParticipant(
            userId: counterpartId,
            role: '',
            joinedAt: joinedAt,
          ),
        ],
      ),
      requester: requester,
    );
    // An unknown counterpart user means the store/service has no account yet.
    if (result.failureOrNull is NotFoundFailure) {
      return FailureResult(NotFoundFailure(unavailable));
    }
    return result;
  }
}
