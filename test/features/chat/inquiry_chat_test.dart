import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/features/auth/infrastructure/mock_auth_repository.dart';
import 'package:bebidas_delivery_app/features/chat/application/dtos/chat_dtos.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/create_conversation_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/list_conversations_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/open_inquiry_chat_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/send_message_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/application/use_cases/watch_messages_use_case.dart';
import 'package:bebidas_delivery_app/features/chat/domain/entities/conversation.dart';
import 'package:bebidas_delivery_app/features/chat/domain/services/conversation_policy.dart';
import 'package:bebidas_delivery_app/features/chat/infrastructure/catalog_chat_counterpart_directory.dart';
import 'package:bebidas_delivery_app/features/chat/infrastructure/in_memory_chat_repository.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/event_service.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/ficha_servicio.dart';
import 'package:bebidas_delivery_app/features/event_services/infrastructure/repositories/in_memory_ficha_servicio_repository.dart';
import 'package:bebidas_delivery_app/features/stores/domain/entities/store.dart';
import 'package:bebidas_delivery_app/features/stores/infrastructure/repositories/in_memory_store_repository.dart';
import 'package:bebidas_delivery_app/features/users/application/use_cases/get_profile_use_case.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/role.dart';
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
  late CreateConversationUseCase createConversation;
  late OpenInquiryChatUseCase openInquiry;
  late SendMessageUseCase sendMessage;
  late WatchMessagesUseCase watchMessages;
  late ListConversationsUseCase listConversations;
  late IdentityContract client;
  late IdentityContract store;
  late IdentityContract driver;
  late IdentityContract provider;

  IdentityContract identity(String role) => IdentityContract.fromUser(
    MockAccounts.all.firstWhere((a) => a.user.role.name == role).user,
  );

  setUp(() async {
    final users = InMemoryUserRepository(MockAccounts.all.map((a) => a.user));
    final getProfile = GetProfileUseCase(users);
    final stores = InMemoryStoreRepository();
    await stores.createStore(
      const Store(
        id: 'store-real',
        ownerId: 'seed-store',
        name: 'Licorería Real',
        address: 'Calle 1',
        isOpen: true,
      ),
    );
    await stores.createStore(
      const Store(
        id: 'store-orphan',
        ownerId: 'current-user',
        name: 'Sin cuenta',
        address: 'Calle 2',
        isOpen: true,
      ),
    );
    final services = InMemoryFichaServicioRepository(
      initialFichas: [
        _ficha('svc-seed', 'prov-001'),
        _ficha('svc-real', 'seed-eventProvider'),
        _ficha('svc-orphan', 'prov-user-current'),
      ],
    );
    chat = InMemoryChatRepository();
    createConversation = CreateConversationUseCase(chat, getProfile);
    openInquiry = OpenInquiryChatUseCase(
      createConversation,
      CatalogChatCounterpartDirectory(
        stores: stores,
        services: services,
        demoLinks: DemoChatLinks.all,
      ),
    );
    sendMessage = SendMessageUseCase(chat);
    watchMessages = WatchMessagesUseCase(chat);
    listConversations = ListConversationsUseCase(chat, getProfile);
    client = identity('client');
    store = identity('store');
    driver = identity('driver');
    provider = identity('eventProvider');
  });

  group('ConversationPolicy', () {
    test('store and service chats are only client ↔ owner', () {
      String? reason(ConversationType type, Role a, Role b) =>
          ConversationPolicy.denialReason(
            type: type,
            roles: [a, b],
            subjectId: 'x',
          );

      expect(
        reason(ConversationType.storeInquiry, Role.client, Role.store),
        isNull,
      );
      expect(
        reason(ConversationType.storeInquiry, Role.driver, Role.store),
        isNotNull,
      );
      expect(
        reason(
          ConversationType.serviceInquiry,
          Role.client,
          Role.eventProvider,
        ),
        isNull,
      );
      expect(
        reason(ConversationType.serviceInquiry, Role.store, Role.eventProvider),
        isNotNull,
      );
    });

    test('inquiries need their subject and orders need an order id', () {
      expect(
        ConversationPolicy.denialReason(
          type: ConversationType.storeInquiry,
          roles: [Role.client, Role.store],
        ),
        isNotNull,
      );
      expect(
        ConversationPolicy.denialReason(
          type: ConversationType.orderSupport,
          roles: [Role.client, Role.store],
        ),
        isNotNull,
      );
      expect(
        ConversationPolicy.denialReason(
          type: ConversationType.orderSupport,
          roles: [Role.client, Role.store],
          orderId: 'order-1',
        ),
        isNull,
      );
    });

    test('direct chats block pairs with no business reason', () {
      expect(ConversationPolicy.canTalkDirectly(Role.client, Role.store), true);
      expect(ConversationPolicy.canTalkDirectly(Role.store, Role.driver), true);
      expect(ConversationPolicy.canTalkDirectly(Role.store, Role.store), false);
      expect(
        ConversationPolicy.canTalkDirectly(Role.driver, Role.eventProvider),
        false,
      );
      expect(
        ConversationPolicy.canTalkDirectly(Role.client, Role.client),
        false,
      );
    });
  });

  group('Cliente → comercio', () {
    test('opens a chat with the real owner of the store', () async {
      final result = await openInquiry.forStore(
        storeId: 'store-real',
        storeName: 'Licorería Real',
        requester: client,
      );

      final conversation = result.dataOrNull!;
      expect(conversation.type, ConversationType.storeInquiry);
      expect(conversation.subjectId, 'store-real');
      expect(conversation.hasParticipant(client.id), isTrue);
      expect(conversation.hasParticipant(store.id), isTrue);
    });

    test('map sample stores reach the demo store account', () async {
      final result = await openInquiry.forStore(
        storeId: 'store-001',
        storeName: 'Licorera El Barril',
        requester: client,
      );

      expect(result.dataOrNull?.hasParticipant(store.id), isTrue);
    });

    test('reopening the same store returns the same conversation', () async {
      final first = await openInquiry.forStore(
        storeId: 'store-real',
        storeName: 'Licorería Real',
        requester: client,
      );
      final again = await openInquiry.forStore(
        storeId: 'store-real',
        storeName: 'Licorería Real',
        requester: client,
      );
      final otherStore = await openInquiry.forStore(
        storeId: 'store-001',
        storeName: 'Licorera El Barril',
        requester: client,
      );

      expect(again.dataOrNull!.id, first.dataOrNull!.id);
      expect(otherStore.dataOrNull!.id, isNot(first.dataOrNull!.id));
    });

    test('only clients can start it', () async {
      for (final requester in [store, driver, provider]) {
        final result = await openInquiry.forStore(
          storeId: 'store-real',
          storeName: 'Licorería Real',
          requester: requester,
        );
        expect(result.isFailure, isTrue, reason: requester.role.name);
      }
    });

    test(
      'fails clearly for unknown stores or stores without account',
      () async {
        final unknown = await openInquiry.forStore(
          storeId: 'nope',
          storeName: '?',
          requester: client,
        );
        final orphan = await openInquiry.forStore(
          storeId: 'store-orphan',
          storeName: 'Sin cuenta',
          requester: client,
        );

        expect(unknown.failureOrNull?.message, contains('cuenta'));
        expect(orphan.failureOrNull?.message, contains('cuenta'));
      },
    );

    test(
      'a direct request cannot fake a store inquiry with a driver',
      () async {
        final result = await createConversation(
          CreateConversationRequest(
            type: ConversationType.storeInquiry,
            subjectId: 'store-real',
            participants: [
              for (final person in [client, driver])
                ConversationParticipant(
                  userId: person.id,
                  role: 'store',
                  joinedAt: DateTime.utc(2026),
                ),
            ],
          ),
          requester: client,
        );

        expect(result.isFailure, isTrue);
      },
    );
  });

  group('Cliente → proveedor de eventos', () {
    test('opens a chat with the provider of the service', () async {
      final seeded = await openInquiry.forService(
        serviceId: 'svc-seed',
        serviceTitle: 'Bartender',
        requester: client,
      );
      final published = await openInquiry.forService(
        serviceId: 'svc-real',
        serviceTitle: 'DJ',
        requester: client,
      );

      expect(seeded.dataOrNull?.type, ConversationType.serviceInquiry);
      expect(seeded.dataOrNull?.hasParticipant(provider.id), isTrue);
      expect(published.dataOrNull?.hasParticipant(provider.id), isTrue);
      expect(published.dataOrNull?.id, isNot(seeded.dataOrNull?.id));
    });

    test('only clients can start it and the service must exist', () async {
      final asProvider = await openInquiry.forService(
        serviceId: 'svc-real',
        serviceTitle: 'DJ',
        requester: provider,
      );
      final asStore = await openInquiry.forService(
        serviceId: 'svc-real',
        serviceTitle: 'DJ',
        requester: store,
      );
      final missing = await openInquiry.forService(
        serviceId: 'svc-missing',
        serviceTitle: '?',
        requester: client,
      );
      final orphan = await openInquiry.forService(
        serviceId: 'svc-orphan',
        serviceTitle: '?',
        requester: client,
      );

      expect(asProvider.isFailure, isTrue);
      expect(asStore.isFailure, isTrue);
      expect(missing.isFailure, isTrue);
      expect(orphan.failureOrNull?.message, contains('cuenta'));
    });
  });

  test('both sides talk; outsiders can neither read nor write', () async {
    final conversation = (await openInquiry.forService(
      serviceId: 'svc-real',
      serviceTitle: 'DJ',
      requester: client,
    )).dataOrNull!;

    final sent = await sendMessage(
      SendMessageRequest(
        conversationId: conversation.id,
        senderId: client.id,
        text: '¿Tienen fecha el sábado?',
      ),
      requester: client,
    );
    final reply = await sendMessage(
      SendMessageRequest(
        conversationId: conversation.id,
        senderId: provider.id,
        text: 'Sí, a partir de las 20:00',
      ),
      requester: provider,
    );
    final intruderWrite = await sendMessage(
      SendMessageRequest(
        conversationId: conversation.id,
        senderId: store.id,
        text: 'hola',
      ),
      requester: store,
    );
    final intruderRead = await watchMessages(conversation.id, requester: store);
    final messages = await (await watchMessages(
      conversation.id,
      requester: provider,
    )).dataOrNull!.first;

    expect(sent.isSuccess, isTrue);
    expect(reply.isSuccess, isTrue);
    expect(intruderWrite.isFailure, isTrue);
    expect(intruderRead.isFailure, isTrue);
    expect(messages.map((m) => m.senderId), [client.id, provider.id]);
  });

  test('inboxes show the subject and only to participants', () async {
    await openInquiry.forStore(
      storeId: 'store-real',
      storeName: 'Licorería Real',
      requester: client,
    );
    await openInquiry.forService(
      serviceId: 'svc-real',
      serviceTitle: 'DJ & Sonido',
      requester: client,
    );

    final mine = (await listConversations(requester: client)).dataOrNull!;
    final storeInbox = (await listConversations(requester: store)).dataOrNull!;
    final providerInbox = (await listConversations(requester: provider))
        .dataOrNull!;
    final driverInbox = (await listConversations(requester: driver))
        .dataOrNull!;

    expect(mine, hasLength(2));
    expect(storeInbox.single.title, 'Licorería Real · Cliente Demo');
    expect(storeInbox.single.kindLabel, 'Consulta a comercio');
    expect(providerInbox.single.title, 'DJ & Sonido · Cliente Demo');
    expect(driverInbox, isEmpty);
  });
}
