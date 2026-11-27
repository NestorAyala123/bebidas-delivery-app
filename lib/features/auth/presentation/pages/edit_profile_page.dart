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
        Navigator.pop(context, true);
      },
      onFailure: (failure) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: colors.primaryContainer,
                        foregroundColor: colors.onPrimaryContainer,
                        child: const Icon(
                          Icons.manage_accounts_outlined,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Mantén tus datos al día',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Actualiza la información que se muestra en tu perfil.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 26),
                      TextFormField(
                        key: const Key('edit-profile-name'),
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        maxLength: UpdateProfileUseCase.maxNameLength,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          final length = value?.trim().length ?? 0;
                          if (length < UpdateProfileUseCase.minNameLength) {
                            return 'El nombre debe tener al menos 2 caracteres';
                          }
                          if (length > UpdateProfileUseCase.maxNameLength) {
                            return 'El nombre es demasiado largo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('edit-profile-phone'),
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        maxLength: 16,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono (opcional)',
                          hintText: '+593991112233',
                          prefixIcon: Icon(Icons.phone_outlined),
                          helperText: 'Entre 7 y 15 dígitos.',
                        ),
                        validator: (value) {
                          final phone = value?.trim() ?? '';
                          if (phone.isEmpty) return null;
                          return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)
                              ? null
                              : 'Usa de 7 a 15 dígitos';
                        },
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _saving ? 'Guardando...' : 'Guardar cambios',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
