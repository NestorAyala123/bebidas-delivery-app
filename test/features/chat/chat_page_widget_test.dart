import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/chat/domain/entities/chat_conversation.dart';
import 'package:bebidas_delivery_app/features/chat/domain/usecases/enviar_mensaje_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/domain/usecases/marcar_conversacion_leida_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/domain/usecases/obtener_conversaciones_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/infrastructure/repositories/in_memory_chat_repository.dart';
import 'package:bebidas_delivery_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:bebidas_delivery_app/features/chat/presentation/pages/chat_page.dart';

void main() {
  late InMemoryChatRepository repository;
  late ChatController controller;

  setUp(() {
    repository = InMemoryChatRepository();
    controller = ChatController(
      obtenerConversacionesUseCase: ObtenerConversacionesUseCase(repository),
      enviarMensajeUseCase: EnviarMensajeUseCase(repository),
      marcarConversacionLeidaUseCase: MarcarConversacionLeidaUseCase(
        repository,
      ),
      chatRepository: repository,
    );
    controller.loadConversations();
  });

  tearDown(() async {
    controller.dispose();
    await repository.dispose();
  });

  testWidgets('muestra historial y envía un mensaje de texto', (tester) async {
    final conversation = ChatConversation(
      id: 'conv-store-001',
      customerId: 'customer-demo',
      counterpartId: 'store-001',
      counterpartName: 'Licorera El Barril',
      role: ChatPeerRole.store,
      contextId: 'store-001',
      contextLabel: 'Pedido en Av. Flavio Reyes y Calle 24',
      updatedAt: DateTime(2026, 11, 15, 9, 34),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(conversation: conversation, controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Licorera El Barril'), findsWidgets);
    expect(
      find.text('Buenas tardes, ¿tienen packs de cerveza artesanal?'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextField).first,
      'Perfecto, espero la confirmación',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Perfecto, espero la confirmación'), findsOneWidget);
  });
}
