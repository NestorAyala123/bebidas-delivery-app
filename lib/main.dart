import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/dependency_injection/injection_container.dart';
import 'app/router/app_router.dart';
import 'features/auth/di/auth_di.dart';
import 'features/auth/presentation/routes/auth_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register modular feature routes
  AppRouter.registerModules([
    AuthRoutes(),
  ]);

  // Register modular dependency injection modules
  await InjectionContainer.init([
    AuthDi(),
  ]);

  runApp(const BebidasDeliveryApp());
}
