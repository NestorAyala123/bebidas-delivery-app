import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../users/application/dtos/profile_dtos.dart';
import '../../../users/application/use_cases/update_profile_use_case.dart';
import '../state/auth_controller.dart';

class EditProfilePage extends StatefulWidget {
  static const route = '/profile/edit';

  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = sl.get<AuthController>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.session?.user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final requester = _auth.identity;
    if (requester == null || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await sl.get<UpdateProfileUseCase>()(
      requester.id,
      UpdateProfileRequest(displayName: _name.text, phoneNumber: _phone.text),
      requester: requester,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      onSuccess: (identity) {
        _auth.refreshProfile(identity);
        Navigator.pop(context);
      },
      onFailure: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editar perfil')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: UpdateProfileUseCase.maxNameLength,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    return length < UpdateProfileUseCase.minNameLength
                        ? 'Ingresa tu nombre'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 16,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    hintText: '+593991112233',
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return null;
                    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)
                        ? null
                        : 'Usa de 7 a 15 dígitos';
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
