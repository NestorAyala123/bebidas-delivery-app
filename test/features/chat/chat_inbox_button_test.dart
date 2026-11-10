import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/app/dependency_injection/injection_container.dart';
import 'package:bebidas_delivery_app/core/di/service_locator.dart';
import 'package:bebidas_delivery_app/features/auth/application/dtos/auth_dtos.dart';
import 'package:bebidas_delivery_app/features/auth/di/auth_di.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/state/auth_controller.dart';
import 'package:bebidas_delivery_app/features/chat/application/dtos/chat_dtos.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/open_inquiry_chat_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/send_message_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/di/chat_di.dart';
import 'package:bebidas_delivery_app/features/chat/presentation/widgets/chat_inbox_button.dart';
import 'package:bebidas_delivery_app/features/event_services/di/event_services_di.dart';
import 'package:bebidas_delivery_app/features/stores/di/stores_products_di.dart';
import 'package:bebidas_delivery_app/features/users/di/users_di.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';

Widget _screen() => MaterialApp(
  home: Scaffold(
    appBar: AppBar(
      title: const Text('Pedidos'),
      actions: const [ChatInboxButton()],
    ),
  ),
);

void main() {
  testWidgets('renders nothing when the chat module is not registered', (
    tester,
  ) async {
    sl.reset();
    await tester.pumpWidget(_screen());

    expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
  });

  group('with chat and a session', () {
    late AuthController auth;

    Future<IdentityContract> loginAs(String email, String password) async {
      expect(
        await auth.login(LoginRequest(email: email, password: password)),
        isTrue,
      );
      return auth.identity!;
    }

    setUp(() async {
      sl.reset();
      await InjectionContainer.init([
        UsersDi(),
        AuthDi(),
        StoresProductsDi(),
        ChatDi(),
        EventServicesDi(),
      ]);
      auth = sl.get<AuthController>();
    });

    testWidgets('counts unread messages and shows an in-app notice', (
      tester,
    ) async {
      final client = await loginAs('cliente@demo.com', 'cliente123');
      final conversation = (await sl.get<OpenInquiryChatUseCase>().forStore(
        storeId: 'store-001',
        storeName: 'Licorera El Barril',
        requester: client,
      )).dataOrNull!;
      await auth.logout();
      await loginAs('comercio@demo.com', 'comercio123');

      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();
      expect(find.byTooltip('Mensajes'), findsOneWidget);

      // The client writes while the store is on another screen.
      await tester.runAsync(
        () => sl.get<SendMessageUseCase>()(
          SendMessageRequest(
            conversationId: conversation.id,
            senderId: client.id,
            text: '¿Tienen cerveza fría?',
          ),
          requester: client,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Mensajes (1 sin leer)'), findsOneWidget);
      expect(find.text('Nuevo mensaje: ¿Tienen cerveza fría?'), findsOneWidget);
      expect(find.text('Ver'), findsOneWidget);
    });

    testWidgets('logout clears the badge', (tester) async {
      final client = await loginAs('cliente@demo.com', 'cliente123');
      final conversation = (await sl.get<OpenInquiryChatUseCase>().forStore(
        storeId: 'store-001',
        storeName: 'Licorera El Barril',
        requester: client,
      )).dataOrNull!;
      await sl.get<SendMessageUseCase>()(
        SendMessageRequest(
          conversationId: conversation.id,
          senderId: client.id,
          text: 'Hola',
        ),
        requester: client,
      );
      await auth.logout();
      await loginAs('comercio@demo.com', 'comercio123');

      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();
      expect(find.byTooltip('Mensajes (1 sin leer)'), findsOneWidget);

      await tester.runAsync(auth.logout);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Mensajes'), findsOneWidget);
    });
  });
}
