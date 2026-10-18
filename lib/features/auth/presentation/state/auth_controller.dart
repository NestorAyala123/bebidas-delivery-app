import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../application/dtos/auth_dtos.dart';
import '../../application/use_cases/get_current_user_use_case.dart';
import '../../application/use_cases/login_use_case.dart';
import '../../application/use_cases/logout_use_case.dart';
import '../../application/use_cases/register_use_case.dart';
import '../../domain/entities/user_session.dart';

class AuthController extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthController({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  });

  UserSession? session;
  bool isLoading = false;
  String? errorMessage;

  bool get isAuthenticated => session != null;

  Future<bool> login(LoginRequest request) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final result = await loginUseCase(
      email: request.email,
      password: request.password,
    );
    return _finish(result);
  }

  Future<bool> register(RegisterRequest request) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final result = await registerUseCase(request);
    return _finish(result);
  }

  Future<void> restoreSession() async {
    final result = await getCurrentUserUseCase();
    if (result case Success(data: final currentSession)) {
      session = currentSession;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await logoutUseCase();
    session = null;
    notifyListeners();
  }

  bool _finish(Result<UserSession, Failure> result) {
    isLoading = false;
    if (result case Success(data: final currentSession)) {
      session = currentSession;
      notifyListeners();
      return true;
    }
    errorMessage = result.failureOrNull?.toString();
    notifyListeners();
    return false;
  }
}
