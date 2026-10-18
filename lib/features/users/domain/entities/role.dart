enum Role { client, store, driver, eventProvider }

enum Permission { manageCatalog }

bool hasPermission(Role role, Permission permission) {
  switch (permission) {
    case Permission.manageCatalog:
      return role == Role.store;
  }
}
