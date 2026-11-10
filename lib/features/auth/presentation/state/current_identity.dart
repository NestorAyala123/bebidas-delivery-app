import '../../../../core/di/service_locator.dart';
import '../../../users/domain/entities/identity_contract.dart';
import 'auth_controller.dart';

/// Identity of the signed-in user for other modules' screens, or `null` when
/// nobody is signed in (or auth is not registered, e.g. in isolated tests).
IdentityContract? currentIdentity() => sl.isRegistered<AuthController>()
    ? sl.get<AuthController>().identity
    : null;
