import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../application/use_cases/login_use_case.dart';
import '../../infrastructure/mock_auth_repository.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final LoginUseCase? loginUseCase;

  const LoginPage({super.key, this.loginUseCase});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  LoginUseCase get _useCase =>
      widget.loginUseCase ??
      (sl.isRegistered<LoginUseCase>()
          ? sl.get<LoginUseCase>()
          : LoginUseCase(MockAuthRepository()));


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillPreset(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _useCase(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess && result.dataOrNull != null) {
      final session = result.dataOrNull!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bienvenido ${session.email}'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(session: session)),
      );
    } else {
      setState(() {
        _errorMessage =
            result.failureOrNull?.message ?? 'Error al iniciar sesión';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_person_outlined,
                    size: 64,
                    color: Color(0xFF7A1C2C),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ingresa a tu cuenta',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accede para gestionar pedidos, productos o entregas.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'ejemplo@correo.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'El correo es obligatorio';
                      }
                      if (!trimmed.contains('@')) {
                        return 'Formato de correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return 'La contraseña es obligatoria';
                      }
                      if (trimmed.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Ingresar',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Demo Accounts Quick Selection
                  Text(
                    'Cuentas de prueba rápida:',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        label: const Text('Cliente'),
                        avatar: const Icon(Icons.person, size: 16),
                        onPressed: () =>
                            _fillPreset('cliente@delivery.com', '123456'),
                      ),
                      ActionChip(
                        label: const Text('Comercio'),
                        avatar: const Icon(Icons.storefront, size: 16),
                        onPressed: () =>
                            _fillPreset('tienda@delivery.com', '123456'),
                      ),
                      ActionChip(
                        label: const Text('Repartidor'),
                        avatar: const Icon(Icons.two_wheeler, size: 16),
                        onPressed: () =>
                            _fillPreset('driver@delivery.com', '123456'),
                      ),
                      ActionChip(
                        label: const Text('Eventos'),
                        avatar: const Icon(Icons.celebration, size: 16),
                        onPressed: () =>
                            _fillPreset('eventos@delivery.com', '123456'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
