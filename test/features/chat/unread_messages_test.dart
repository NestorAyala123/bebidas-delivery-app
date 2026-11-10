import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/features/auth/infrastructure/mock_auth_repository.dart';
import 'package:bebidas_delivery_app/features/chat/application/dtos/chat_dtos.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/create_conversation_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/list_conversations_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/mark_conversation_read_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/open_inquiry_chat_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/send_message_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/watch_unread_messages_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/domain/entities/conversation.dart';
import 'package:bebidas_delivery_app/features/chat/infrastructure/catalog_chat_counterpart_directory.dart';
import 'package:bebidas_delivery_app/features/chat/infrastructure/in_memory_chat_repository.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/event_service.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/ficha_servicio.dart';
import 'package:bebidas_delivery_app/features/event_services/infrastructure/repositories/in_memory_ficha_servicio_repository.dart';
import 'package:bebidas_delivery_app/features/stores/infrastructure/repositories/in_memory_store_repository.dart';
import 'package:bebidas_delivery_app/features/users/application/use_cases/get_profile_use_case.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';
import 'package:bebidas_delivery_app/features/users/infrastructure/in_memory_user_repository.dart';

FichaServicio _ficha(String id, String providerId) => FichaServicio(
  id: id,
  providerId: providerId,
  title: 'Servicio $id',
  description: 'Descripción',
  serviceType: EventServiceType.bartender,
  estimatedPrice: 100,
  locationLabel: 'Manta',
  contactPhone: '+593000000',
  createdAt: '2026-11-01T00:00:00Z',
);

void main() {
  late InMemoryChatRepository chat;
  late OpenInquiryChatUseCase openInquiry;
  late SendMessageUseCase sendMessage;
  late MarkConversationReadUseCase markRead;
  late WatchUnreadMessagesUseCase watchUnread;
  late ListConversationsUseCase listConversations;
  late IdentityContract client;
  late IdentityContract store;
  late IdentityContract driver;
  late IdentityContract provider;
  var clock = DateTime.utc(2026, 11, 10, 12);

  IdentityContract identity(String role) => IdentityContract.fromUser(
    MockAccounts.all.firstWhere((a) => a.user.role.name == role).user,
  );

  DateTime tick() => clock = clock.add(const Duration(minutes: 1));

  Future<void> say(Conversation c, IdentityContract who, String text) async {
    final result = await sendMessage(
      SendMessageRequest(conversationId: c.id, senderId: who.id, text: text),
      requester: who,
    );
    expect(result.isSuccess, isTrue, reason: result.failureOrNull?.message);
  }

  setUp(() {
    final users = InMemoryUserRepository(MockAccounts.all.map((a) => a.user));
    final getProfile = GetProfileUseCase(users);
    chat = InMemoryChatRepository(now: tick);
    final services = InMemoryFichaServicioRepository(
      initialFichas: [
        _ficha('svc-mine', 'seed-eventProvider'),
        _ficha('svc-other', 'otro-proveedor'),
      ],
    );
    openInquiry = OpenInquiryChatUseCase(
      CreateConversationUseCase(chat, getProfile, now: tick),
      CatalogChatCounterpartDirectory(
        stores: InMemoryStoreRepository(),
        services: services,
        demoLinks: DemoChatLinks.all,
      ),
      now: tick,
    );
    sendMessage = SendMessageUseCase(chat, now: tick);
    markRead = MarkConversationReadUseCase(chat, now: tick);
    watchUnread = WatchUnreadMessagesUseCase(chat);
    listConversations = ListConversationsUseCase(chat, getProfile);
    client = identity('client');
    store = identity('store');
    driver = identity('driver');
    provider = identity('eventProvider');
  });

  Future<Conversation> storeChat() async => (await openInquiry.forStore(
    storeId: 'store-001',
    storeName: 'Licorera El Barril',
    requester: client,
  )).dataOrNull!;

  group('No leídos y bandeja', () {
    test('the inbox shows the last message and unread count', () async {
      final conversation = await storeChat();
      await say(conversation, client, 'Hola');
      await say(conversation, client, '¿Tienen hielo?');

      final storeInbox = (await listConversations(requester: store))
          .dataOrNull!
          .single;
      final clientInbox = (await listConversations(requester: client))
          .dataOrNull!
          .single;

      expect(storeInbox.unreadCount, 2);
      expect(storeInbox.lastMessage?.text, '¿Tienen hielo?');
      // My own messages never count as unread.
      expect(clientInbox.unreadCount, 0);
    });

    test('reading clears the count only for the reader', () async {
      final conversation = await storeChat();
      await say(conversation, client, 'Hola');
      await say(conversation, store, 'Buenas, ¿qué necesitas?');

      expect(
        (await markRead(conversation.id, requester: store)).isSuccess,
        true,
      );

      final storeInbox = (await listConversations(requester: store))
          .dataOrNull!
          .single;
      final clientInbox = (await listConversations(requester: client))
          .dataOrNull!
          .single;
      expect(storeInbox.unreadCount, 0);
      expect(clientInbox.unreadCount, 1);

      await say(conversation, client, 'Una caja de cerveza');
      final again = (await listConversations(requester: store))
          .dataOrNull!
          .single;
      expect(again.unreadCount, 1);
    });

    test('only participants can mark a conversation as read', () async {
      final conversation = await storeChat();
      await say(conversation, client, 'Hola');

      final outsider = await markRead(conversation.id, requester: driver);
      final missing = await markRead('cnv-nope', requester: store);

      expect(outsider.isFailure, isTrue);
      expect(missing.isFailure, isTrue);
      // The real participant still has the message pending.
      final storeInbox = (await listConversations(requester: store))
          .dataOrNull!
          .single;
      expect(storeInbox.unreadCount, 1);
    });
  });

  group('Aviso de mensajes nuevos', () {
    test(
      'the unread stream updates live and names the newest message',
      () async {
        final conversation = await storeChat();
        final events = <UnreadMessages>[];
        final subscription = watchUnread(requester: store).dataOrNull!
            .listen(events.add);
        await pumpEventQueue();

        await say(conversation, client, 'Hola');
        await pumpEventQueue();
        await say(conversation, client, '¿Siguen abiertos?');
        await pumpEventQueue();
        await markRead(conversation.id, requester: store);
        await pumpEventQueue();
        await subscription.cancel();

        expect(events.map((e) => e.total), [0, 1, 2, 0]);
        expect(events[2].latest?.text, '¿Siguen abiertos?');
      },
    );

    test('outsiders are never notified of other people\'s messages', () async {
      final conversation = await storeChat();
      final events = <int>[];
      final subscription = watchUnread(requester: driver).dataOrNull!
          .listen((e) => events.add(e.total));
      await pumpEventQueue();

      await say(conversation, client, 'Hola');
      await say(conversation, store, 'Hola, cliente');
      await pumpEventQueue();
      await subscription.cancel();

      expect(events, everyElement(0));
    });
  });

  group('Proveedor → cliente desde una consulta', () {
    test('reuses the chat the client opened for the same service', () async {
      final fromClient = (await openInquiry.forService(
        serviceId: 'svc-mine',
        serviceTitle: 'Bartender',
        requester: client,
      )).dataOrNull!;
      final fromProvider = await openInquiry.forServiceCustomer(
        serviceId: 'svc-mine',
        serviceTitle: 'Bartender',
        customerId: client.id,
        requester: provider,
      );

      expect(fromProvider.dataOrNull?.id, fromClient.id);
    });

    test(
      'only the provider of that service, and with a real customer',
      () async {
        final notMine = await openInquiry.forServiceCustomer(
          serviceId: 'svc-other',
          serviceTitle: 'Otro',
          customerId: client.id,
          requester: provider,
        );
        final asStore = await openInquiry.forServiceCustomer(
          serviceId: 'svc-mine',
          serviceTitle: 'Bartender',
          customerId: client.id,
          requester: store,
        );
        final ghostCustomer = await openInquiry.forServiceCustomer(
          serviceId: 'svc-mine',
          serviceTitle: 'Bartender',
          customerId: 'customer-demo',
          requester: provider,
        );
        final notAClient = await openInquiry.forServiceCustomer(
          serviceId: 'svc-mine',
          serviceTitle: 'Bartender',
          customerId: driver.id,
          requester: provider,
        );

        expect(notMine.failureOrNull?.message, 'Este servicio no es tuyo');
        expect(asStore.isFailure, isTrue);
        expect(ghostCustomer.failureOrNull?.message, contains('cuenta'));
        expect(notAClient.isFailure, isTrue);
      },
    );
  });
}
