import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../application/dtos/auth_dtos.dart';
import '../../../users/domain/entities/app_user.dart';
import '../state/auth_controller.dart';
import 'login_page.dart';
import 'profile_page.dart';

class RegisterPage extends StatefulWidget {
  static const route = '/register';

  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _controller = sl.get<AuthController>();
  UserRole _role = UserRole.client;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await _controller.register(
      RegisterRequest(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        role: _role,
      ),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, ProfilePage.route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Error de registro'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crear cuenta')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: UserRole.values
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(_roleLabel(role)),
                      ),
                    )
                    .toList(),
                onChanged: (role) => setState(() => _role = role!),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _controller.isLoading ? null : _submit,
                child: const Text('Registrarme'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, LoginPage.route),
                child: const Text('Ya tengo una cuenta'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _roleLabel(UserRole role) => switch (role) {
  UserRole.client => 'Cliente',
  UserRole.store => 'Comercio',
  UserRole.driver => 'Repartidor',
  UserRole.eventProvider => 'Proveedor de eventos',
};
