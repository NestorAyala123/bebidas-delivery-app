import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/app/dependency_injection/injection_container.dart';
import 'package:bebidas_delivery_app/core/di/service_locator.dart';
import 'package:bebidas_delivery_app/features/auth/application/dtos/auth_dtos.dart';
import 'package:bebidas_delivery_app/features/auth/di/auth_di.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/state/auth_controller.dart';
import 'package:bebidas_delivery_app/features/auth/presentation/state/current_identity.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/open_inquiry_chat_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/di/chat_di.dart';
import 'package:bebidas_delivery_app/features/chat/presentation/pages/chat_page.dart';
import 'package:bebidas_delivery_app/features/chat/presentation/pages/conversations_page.dart';
import 'package:bebidas_delivery_app/features/event_services/di/event_services_di.dart';
import 'package:bebidas_delivery_app/features/stores/di/stores_products_di.dart';
import 'package:bebidas_delivery_app/features/users/di/users_di.dart';

void main() {
  late AuthController auth;

  Future<void> loginAs(String email, String password) async {
    final ok = await auth.login(LoginRequest(email: email, password: password));
    expect(ok, isTrue);
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

  test('logout clears the identity other modules read', () async {
    await loginAs('cliente@demo.com', 'cliente123');
    expect(currentIdentity()?.id, 'seed-client');

    await auth.logout();

    expect(currentIdentity(), isNull);
    expect(auth.errorMessage, isNull);
  });

  test('failed login shows a readable message', () async {
    final ok = await auth.login(
      const LoginRequest(email: 'cliente@demo.com', password: 'incorrecta'),
    );

    expect(ok, isFalse);
    expect(auth.errorMessage, 'Correo o contraseña incorrectos');
  });

  testWidgets('the chat reacts to logout and to a change of account', (
    tester,
  ) async {
    await loginAs('cliente@demo.com', 'cliente123');
    final conversation = (await sl.get<OpenInquiryChatUseCase>().forService(
      serviceId: 'svc-001',
      serviceTitle: 'Bartender',
      requester: auth.identity!,
    )).dataOrNull!;

    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(
          arguments: ChatPageArguments(
            conversationId: conversation.id,
            title: 'Bartender',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Escribe el primer mensaje'), findsOneWidget);

    await auth.logout();
    await tester.pumpAndSettle();
    expect(find.textContaining('sesión no está activa'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    // Another account that is not part of the conversation is denied.
    await loginAs('comercio@demo.com', 'comercio123');
    await tester.pumpAndSettle();
    expect(find.text('No participas en esta conversación'), findsOneWidget);

    // The provider of the service is a participant.
    await auth.logout();
    await loginAs('eventos@demo.com', 'eventos123');
    await tester.pumpAndSettle();
    expect(find.text('Escribe el primer mensaje'), findsOneWidget);
  });

  testWidgets('the inbox shows store and service chats with their subject', (
    tester,
  ) async {
    await loginAs('cliente@demo.com', 'cliente123');
    final open = sl.get<OpenInquiryChatUseCase>();
    await open.forStore(
      storeId: 'store-001',
      storeName: 'Licorera El Barril',
      requester: auth.identity!,
    );
    await open.forService(
      serviceId: 'svc-001',
      serviceTitle: 'Bartender Profesional',
      requester: auth.identity!,
    );

    await tester.pumpWidget(const MaterialApp(home: ConversationsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Licorera El Barril · Comercio Demo'), findsOneWidget);
    expect(find.text('Bartender Profesional · Eventos Demo'), findsOneWidget);
    expect(find.text('Consulta a comercio'), findsOneWidget);
  });
}
