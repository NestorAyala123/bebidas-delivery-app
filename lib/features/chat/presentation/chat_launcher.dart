import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../auth/presentation/routes/auth_routes.dart';
import '../../auth/presentation/state/current_identity.dart';
import '../../users/domain/entities/identity_contract.dart';
import '../application/use_cases/open_inquiry_chat_use_case.dart';
import '../domain/entities/conversation.dart';
import 'pages/chat_page.dart';
import 'routes/chat_routes.dart';

/// Public entry point for other modules to open a chat from their screens.
///
/// Other modules only pass the `storeId` / `serviceId` they already show; the
/// chat module checks the session, resolves the counterpart and the access
/// rules, and opens the room.
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
}
