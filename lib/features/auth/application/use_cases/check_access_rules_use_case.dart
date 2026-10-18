import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/domain/entities/role.dart';

class CheckAccessRulesUseCase {
  const CheckAccessRulesUseCase();

  Result<bool, Failure> call({
    required Role role,
    required Permission permission,
  }) => Success(hasPermission(role, permission));
}
