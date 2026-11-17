import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/chat/domain/usecases/enviar_mensaje_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/domain/usecases/marcar_conversacion_leida_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/domain/usecases/obtener_conversaciones_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/infrastructure/repositories/in_memory_chat_repository.dart';
import 'package:bebidas_delivery_app/features/chat/presentation/controllers/chat_controller.dart';

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
      simulateIncoming: (conversationId) =>
          repository.simulateIncomingMessage(conversationId: conversationId),
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.dispose();
  });

  test('carga conversaciones y calcula el total de no leídos', () async {
    controller.loadConversations();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(controller.isLoading, isFalse);
    expect(controller.conversations, isNotEmpty);
    expect(controller.totalUnread, greaterThan(0));
  });

  test('abre conversación, marca leída y envía mensaje', () async {
    controller.loadConversations();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final conversation = controller.conversations.firstWhere(
      (c) => c.id == 'conv-store-001',
    );
    controller.openConversation(conversation);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(controller.messages, isNotEmpty);

    final sent = await controller.sendMessage('Mensaje de prueba');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(sent, isTrue);
    expect(
      controller.messages.map((m) => m.text),
      contains('Mensaje de prueba'),
    );
  });

  test('mensaje entrante simulado genera aviso en la app', () async {
    controller.loadConversations();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    controller.openConversation(
      controller.conversations.firstWhere((c) => c.id == 'conv-prov-001'),
    );

    await controller.simulateIncomingMessage();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(controller.latestNotification, isNotNull);
    expect(controller.latestNotification!.conversationId, 'conv-prov-001');

    controller.dismissNotification();
    expect(controller.latestNotification, isNull);
  });

  test('rechaza mensajes vacíos con error de validación', () async {
    controller.loadConversations();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    controller.openConversation(controller.conversations.first);

    final sent = await controller.sendMessage('   ');

    expect(sent, isFalse);
    expect(controller.errorMessage, isNotNull);
  });
}
