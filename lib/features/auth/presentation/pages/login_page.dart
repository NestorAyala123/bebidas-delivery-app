import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../application/dtos/auth_dtos.dart';
import '../state/auth_controller.dart';
import 'profile_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  static const route = '/login';

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _controller = sl.get<AuthController>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await _controller.login(
      LoginRequest(email: _email.text, password: _password.text),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, ProfilePage.route);
    } else {
      _showError(_controller.errorMessage ?? 'No fue posible iniciar sesión');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Iniciar sesión')),
    body: _AuthForm(
      email: _email,
      password: _password,
      loading: _controller.isLoading,
      onSubmit: _submit,
      footer: TextButton(
        onPressed: () => Navigator.pushNamed(context, RegisterPage.route),
        child: const Text('Crear una cuenta'),
      ),
    ),
  );
}

class _AuthForm extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController password;
  final bool loading;
  final VoidCallback onSubmit;
  final Widget footer;

  const _AuthForm({
    required this.email,
    required this.password,
    required this.loading,
    required this.onSubmit,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: loading ? null : onSubmit,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Continuar'),
            ),
            footer,
            const Text(
              'Demo: cliente@demo.com / cliente123',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
