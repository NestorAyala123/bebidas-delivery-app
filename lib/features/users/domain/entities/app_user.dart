enum UserRole { client, store, driver, eventProvider }

class AppUser {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final UserRole role;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
  });

  bool get isClient => role == UserRole.client;
  bool get isStore => role == UserRole.store;
  bool get isDriver => role == UserRole.driver;
  bool get isEventProvider => role == UserRole.eventProvider;
}
