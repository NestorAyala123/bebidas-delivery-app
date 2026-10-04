/// Roles supported by the identity module.
///
/// The serialized values are part of the public identity contract. Do not
/// rename them without a contract version bump.
enum Role {
  client('client'),
  store('store'),
  driver('driver'),
  eventProvider('event_provider');

  const Role(this.value);

  final String value;

  static Role? fromValue(String value) {
    for (final role in Role.values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

enum Permission {
  readOwnProfile('profile:read:own'),
  updateOwnProfile('profile:update:own'),
  manageStoreProfile('store:manage'),
  manageCatalog('catalog:manage'),
  manageOrders('orders:manage'),
  viewDeliveryRequests('delivery:requests:read'),
  manageDeliveryOffers('delivery:offers:manage'),
  manageEventServices('event_services:manage'),
  createConversation('chat:conversation:create'),
  readConversation('chat:conversation:read'),
  sendMessage('chat:message:send');

  const Permission(this.value);

  final String value;
}

/// Central RBAC matrix. Backend authorization must enforce the same matrix.
const Map<Role, Set<Permission>> rolePermissions = {
  Role.client: {
    Permission.readOwnProfile,
    Permission.updateOwnProfile,
    Permission.createConversation,
    Permission.readConversation,
    Permission.sendMessage,
  },
  Role.store: {
    Permission.readOwnProfile,
    Permission.updateOwnProfile,
    Permission.manageStoreProfile,
    Permission.manageCatalog,
    Permission.manageOrders,
    Permission.createConversation,
    Permission.readConversation,
    Permission.sendMessage,
  },
  Role.driver: {
    Permission.readOwnProfile,
    Permission.updateOwnProfile,
    Permission.viewDeliveryRequests,
    Permission.manageDeliveryOffers,
    Permission.createConversation,
    Permission.readConversation,
    Permission.sendMessage,
  },
  Role.eventProvider: {
    Permission.readOwnProfile,
    Permission.updateOwnProfile,
    Permission.manageEventServices,
    Permission.createConversation,
    Permission.readConversation,
    Permission.sendMessage,
  },
};

bool hasPermission(Role role, Permission permission) =>
    rolePermissions[role]?.contains(permission) ?? false;
