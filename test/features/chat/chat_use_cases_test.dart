import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/features/auth/infrastructure/mock_auth_repository.dart';
import 'package:bebidas_delivery_app/features/chat/application/dtos/chat_dtos.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/create_conversation_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/list_conversations_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/send_message_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/watch_messages_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/domain/entities/conversation.dart';
import 'package:bebidas_delivery_app/features/chat/infrastructure/in_memory_chat_repository.dart';
import 'package:bebidas_delivery_app/features/users/application/use_cases/get_profile_use_case.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';
import 'package:bebidas_delivery_app/features/users/infrastructure/in_memory_user_repository.dart';

void main() {
  late InMemoryChatRepository chat;
  late CreateConversationUseCase createConversation;
  late SendMessageUseCase sendMessage;
  late WatchMessagesUseCase watchMessages;
  late ListConversationsUseCase listConversations;
  late IdentityContract client;
  late IdentityContract store;
  late IdentityContract driver;

  IdentityContract identity(String role) => IdentityContract.fromUser(
    MockAccounts.all.firstWhere((a) => a.user.role.name == role).user,
  );

  CreateConversationRequest requestBetween(List<IdentityContract> people) =>
      CreateConversationRequest(
        type: ConversationType.direct,
        participants: [
          for (final person in people)
            ConversationParticipant(
              userId: person.id,
              role: 'ignored',
              joinedAt: DateTime.utc(2026, 1, 1),
            ),
        ],
      );

  setUp(() {
    final users = InMemoryUserRepository(MockAccounts.all.map((a) => a.user));
    final getProfile = GetProfileUseCase(users);
    chat = InMemoryChatRepository();
    createConversation = CreateConversationUseCase(chat, getProfile);
    sendMessage = SendMessageUseCase(chat);
    watchMessages = WatchMessagesUseCase(chat);
    listConversations = ListConversationsUseCase(chat, getProfile);
    client = identity('client');
    store = identity('store');
    driver = identity('driver');
  });

  Future<Conversation> openClientStore() async => (await createConversation(
    requestBetween([client, store]),
    requester: client,
  )).dataOrNull!;

  test('creates a conversation using the verified roles', () async {
    final conversation = await openClientStore();

    expect(conversation.participants.map((p) => p.userId), [
      client.id,
      store.id,
    ]);
    expect(conversation.participants.map((p) => p.role), ['client', 'store']);
  });

  test('is idempotent for the same participants', () async {
    final first = await openClientStore();
    final second = (await createConversation(
      requestBetween([store, client]),
      requester: store,
    )).dataOrNull!;

    expect(second.id, first.id);
  });

  test('rejects conversations the requester is not part of', () async {
    final result = await createConversation(
      requestBetween([store, driver]),
      requester: client,
    );

    expect(result.isFailure, isTrue);
  });

  test('rejects duplicated, single or unknown participants', () async {
    final alone = await createConversation(
      requestBetween([client]),
      requester: client,
    );
    final duplicated = await createConversation(
      requestBetween([client, client]),
      requester: client,
    );
    final unknown = await createConversation(
      CreateConversationRequest(
        type: ConversationType.direct,
        participants: [
          ConversationParticipant(
            userId: client.id,
            role: 'client',
            joinedAt: DateTime.now(),
          ),
          ConversationParticipant(
            userId: 'ghost',
            role: 'client',
            joinedAt: DateTime.now(),
          ),
        ],
      ),
      requester: client,
    );

    expect(alone.isFailure, isTrue);
    expect(duplicated.isFailure, isTrue);
    expect(unknown.isFailure, isTrue);
  });

  test('participants exchange messages in order', () async {
    final conversation = await openClientStore();
    final stream = (await watchMessages(
      conversation.id,
      requester: store,
    )).dataOrNull!;
    final snapshots = <List<String>>[];
    final subscription = stream.listen(
      (messages) => snapshots.add(messages.map((m) => m.text).toList()),
    );

    final first = await sendMessage(
      SendMessageRequest(
        conversationId: conversation.id,
        senderId: client.id,
        text: '  Hola, ¿tienen cerveza?  ',
      ),
      requester: client,
    );
    await sendMessage(
      SendMessageRequest(
        conversationId: conversation.id,
        senderId: store.id,
        text: 'Sí, hay stock',
      ),
      requester: store,
    );
    await pumpEventQueue();
    await subscription.cancel();

    expect(first.dataOrNull?.text, 'Hola, ¿tienen cerveza?');
    expect(snapshots.first, isEmpty);
    expect(snapshots.last, ['Hola, ¿tienen cerveza?', 'Sí, hay stock']);
  });

  test('non participants can neither read nor write', () async {
    final conversation = await openClientStore();

    final read = await watchMessages(conversation.id, requester: driver);
    final write = await sendMessage(
      SendMessageRequest(
        conversationId: conversation.id,
        senderId: driver.id,
        text: 'intruso',
      ),
      requester: driver,
    );

    expect(read.isFailure, isTrue);
    expect(write.isFailure, isTrue);
    expect(
      (await chat.getMessagesStream(conversation.id).first),
      isEmpty,
    );
  });

  test('cannot send as another user or to a missing conversation', () async {
    final conversation = await openClientStore();

    final spoofed = await sendMessage(
      SendMessageRequest(
        conversationId: conversation.id,
        senderId: store.id,
        text: 'suplantación',
      ),
      requester: client,
    );
    final missing = await sendMessage(
      SendMessageRequest(
        conversationId: 'nope',
        senderId: client.id,
        text: 'hola',
      ),
      requester: client,
    );

    expect(spoofed.isFailure, isTrue);
    expect(missing.isFailure, isTrue);
  });

  test('validates empty, oversized and non-text messages', () async {
    final conversation = await openClientStore();
    Future<bool> fails(String text, {String type = 'text'}) async =>
        (await sendMessage(
          SendMessageRequest(
            conversationId: conversation.id,
            senderId: client.id,
            text: text,
            type: type,
          ),
          requester: client,
        )).isFailure;

    expect(await fails('   '), isTrue);
    expect(await fails('a' * (SendMessageUseCase.maxLength + 1)), isTrue);
    expect(await fails('hola', type: 'image'), isTrue);
  });

  test('lists only my conversations, titled with the other person', () async {
    await openClientStore();

    final mine = (await listConversations(requester: client)).dataOrNull!;
    final stores = (await listConversations(requester: store)).dataOrNull!;
    final others = (await listConversations(requester: driver)).dataOrNull!;

    expect(mine.single.title, 'Comercio Demo');
    expect(stores.single.title, 'Cliente Demo');
    expect(others, isEmpty);
  });
}
