import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../auth/presentation/routes/auth_routes.dart';
import '../../auth/presentation/state/current_identity.dart';
import '../../users/domain/entities/identity_contract.dart';
import '../application/use_cases/open_inquiry_chat_use_case.dart';
import '../domain/entities/chat_conversation.dart';
import '../domain/entities/chat_message.dart';
import '../domain/entities/conversation.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/usecases/crear_conversacion_use_case.dart';
import '../domain/usecases/enviar_mensaje_use_case.dart';
import '../infrastructure/repositories/in_memory_chat_repository.dart';
import 'chat_controller_factory.dart';
import 'pages/chat_page.dart';
import 'routes/chat_routes.dart';

/// Punto de entrada reutilizable para abrir un chat desde otros módulos.
class ChatLauncher {
  ChatLauncher._();

  /// Cliente → comercio (desde el mapa o la ficha del comercio).
  static Future<void> openStoreChat(
    BuildContext context, {
    required String storeId,
    required String storeName,
  }) => _launch(
    context,
    title: storeName,
    open: (useCase, identity) => useCase.forStore(
      storeId: storeId,
      storeName: storeName,
      requester: identity,
    ),
  );

  /// Cliente → proveedor (desde la ficha del servicio para eventos).
  static Future<void> openServiceChat(
    BuildContext context, {
    required String serviceId,
    required String serviceTitle,
  }) => _launch(
    context,
    title: serviceTitle,
    open: (useCase, identity) => useCase.forService(
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      requester: identity,
    ),
  );

  /// Proveedor → cliente de una consulta (desde "Mis consultas").
  static Future<void> openServiceCustomerChat(
    BuildContext context, {
    required String serviceId,
    required String serviceTitle,
    required String customerId,
    required String customerName,
  }) => _launch(
    context,
    title: '$serviceTitle · $customerName',
    open: (useCase, identity) => useCase.forServiceCustomer(
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      customerId: customerId,
      requester: identity,
    ),
  );

  /// Opens the signed-in user's inbox.
  static Future<void> openInbox(BuildContext context) =>
      Navigator.pushNamed(context, ChatRoutes.conversations);

  static Future<void> _launch(
    BuildContext context, {
    required String title,
    required Future<Result<Conversation, Failure>> Function(
      OpenInquiryChatUseCase useCase,
      IdentityContract identity,
    )
    open,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final identity = currentIdentity();
    if (identity == null) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Inicia sesión como cliente para chatear'),
          action: SnackBarAction(
            label: 'Iniciar sesión',
            onPressed: () => Navigator.pushNamed(context, AuthRoutes.login),
          ),
        ),
      );
      return;
    }
    final result = await open(sl.get<OpenInquiryChatUseCase>(), identity);
    if (!context.mounted) return;
    result.fold(
      onSuccess: (conversation) => Navigator.pushNamed(
        context,
        ChatRoutes.room,
        arguments: ChatPageArguments(
          conversationId: conversation.id,
          title: title,
        ),
      ),
      onFailure: (failure) =>
          messenger.showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  /// Garantiza el hilo con [counterpartId] y abre la pantalla de chat.
  ///
  /// [contextId] vincula la conversación con la tienda, ficha de servicio o
  /// entrega de origen. Si se envía [initialMessage], se publica al abrir.
  static Future<void> open(
    BuildContext context, {
    required String counterpartId,
    required String counterpartName,
    required ChatPeerRole role,
    String? contextId,
    String contextLabel = '',
    String initialMessage = '',
    String userId = 'customer-demo',
    String userName = 'Cliente',
  }) async {
    final ChatRepository repository = sl.isRegistered<ChatRepository>()
        ? sl.get<ChatRepository>()
        : InMemoryChatRepository();

    final now = DateTime.now();
    final conversation = ChatConversation(
      id: 'conv-$counterpartId-${contextId ?? 'general'}',
      customerId: userId,
      counterpartId: counterpartId,
      counterpartName: counterpartName,
      role: role,
      contextId: contextId,
      contextLabel: contextLabel,
      updatedAt: now,
    );

    final ensured = await CrearConversacionUseCase(repository)(conversation);
    final saved = ensured.dataOrNull ?? conversation;

    if (initialMessage.trim().isNotEmpty) {
      await EnviarMensajeUseCase(repository)(
        conversationId: saved.id,
        senderId: userId,
        senderName: userName,
        text: initialMessage,
      );
    }

    if (!context.mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversation: saved,
          controller: buildChatController(
            repository: repository,
            userId: userId,
            userName: userName,
          ),
        ),
      ),
    );
  }

  /// Mensaje de sistema con el resumen de una consulta de evento.
  static String buildConsultationMessage({
    required String serviceTitle,
    required String eventDate,
    required int guestCount,
    required String location,
  }) {
    return 'Hola, envié una consulta para "$serviceTitle" el $eventDate '
        'para $guestCount invitados en $location. ¿Podemos coordinar detalles?';
  }

  /// Construye un mensaje local para pruebas o integraciones.
  static ChatMessage localMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String senderName = '',
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: 'msg-${now.microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      sentAt: now,
    );
  }
}
