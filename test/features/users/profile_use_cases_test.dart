import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/features/auth/application/use_cases/login_use_case.dart';
import 'package:bebidas_delivery_app/features/auth/infrastructure/mock_auth_repository.dart';
import 'package:bebidas_delivery_app/features/users/application/dtos/profile_dtos.dart';
import 'package:bebidas_delivery_app/features/users/application/use_cases/get_profile_use_case.dart';
import 'package:bebidas_delivery_app/features/users/application/use_cases/list_contacts_use_case.dart';
import 'package:bebidas_delivery_app/features/users/application/use_cases/update_profile_use_case.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/identity_contract.dart';
import 'package:bebidas_delivery_app/features/users/infrastructure/in_memory_user_repository.dart';

void main() {
  late InMemoryUserRepository users;
  late MockAuthRepository auth;
  late IdentityContract client;
  late IdentityContract store;

  setUp(() async {
    users = InMemoryUserRepository(MockAccounts.all.map((a) => a.user));
    auth = MockAuthRepository(users: users);
    client = IdentityContract.fromUser(
      (await LoginUseCase(auth)(
        email: 'cliente@demo.com',
        password: 'cliente123',
      )).dataOrNull!.user,
    );
    store = IdentityContract.fromUser(
      (await LoginUseCase(auth)(
        email: 'comercio@demo.com',
        password: 'comercio123',
      )).dataOrNull!.user,
    );
  });

  test('owner updates name and phone, and the change is persisted', () async {
    final result = await UpdateProfileUseCase(users)(
      client.id,
      const UpdateProfileRequest(
        displayName: '  Ana Pérez ',
        phoneNumber: '+593991112233',
      ),
      requester: client,
    );

    expect(result.dataOrNull?.displayName, 'Ana Pérez');
    final stored = (await users.getUserById(client.id)).dataOrNull!;
    expect(stored.phoneNumber, '+593991112233');
    // A new login sees the edited profile, not the seed.
    final relogin = await LoginUseCase(auth)(
      email: 'cliente@demo.com',
      password: 'cliente123',
    );
    expect(relogin.dataOrNull?.user.name, 'Ana Pérez');
  });

  test('blank phone clears the number', () async {
    final result = await UpdateProfileUseCase(users)(
      client.id,
      const UpdateProfileRequest(displayName: 'Ana', phoneNumber: '   '),
      requester: client,
    );

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull?.phoneNumber, isNull);
  });

  test('rejects editing another user profile', () async {
    final result = await UpdateProfileUseCase(users)(
      store.id,
      const UpdateProfileRequest(displayName: 'Hackeado'),
      requester: client,
    );

    expect(result.isFailure, isTrue);
    expect((await users.getUserById(store.id)).dataOrNull?.name, isNot('Hackeado'));
  });

  test('validates name length and phone format', () async {
    final useCase = UpdateProfileUseCase(users);

    final shortName = await useCase(
      client.id,
      const UpdateProfileRequest(displayName: 'A'),
      requester: client,
    );
    final badPhone = await useCase(
      client.id,
      const UpdateProfileRequest(displayName: 'Ana', phoneNumber: '12ab'),
      requester: client,
    );

    expect(shortName.isFailure, isTrue);
    expect(badPhone.isFailure, isTrue);
  });

  test('other users only see the public identity', () async {
    final own = await GetProfileUseCase(users)(client.id, requester: client);
    final foreign = await GetProfileUseCase(users)(
      client.id,
      requester: store,
    );

    expect(own.dataOrNull?.email, 'cliente@demo.com');
    expect(foreign.dataOrNull?.displayName, 'Cliente Demo');
    expect(foreign.dataOrNull?.email, isEmpty);
    expect(foreign.dataOrNull?.phoneNumber, isNull);
  });

  test('contacts exclude the requester and hide contact data', () async {
    final result = await ListContactsUseCase(users)(requester: client);
    final contacts = result.dataOrNull!;

    expect(contacts.any((c) => c.id == client.id), isFalse);
    expect(contacts, hasLength(3));
    expect(contacts.every((c) => c.email.isEmpty), isTrue);
  });
}
