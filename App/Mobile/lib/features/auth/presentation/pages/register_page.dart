import 'package:flutter/material.dart';

import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form.dart';

/// Creates an account and opens a session for it.
class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.controller,
    required this.onRegistered,
  });

  final AuthController controller;

  /// Called once the session is open.
  final VoidCallback onRegistered;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final registered = widget.controller.submitRegister(
      RegisterRequest(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
    if (registered) widget.onRegistered();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AuthForm(
        title: 'Buat akun baru',
        subtitle: 'Simpan riwayat scan dan pantau laporan keamanan Anda.',
        fields: [
          AuthField(
            label: 'Nama lengkap',
            hint: 'Nama Anda',
            controller: _nameController,
          ),
          AuthField(
            label: 'Email',
            hint: 'nama@email.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          AuthField(
            label: 'Password',
            hint: 'Minimal 6 karakter',
            obscure: true,
            controller: _passwordController,
          ),
        ],
        actionLabel: 'Daftar',
        errorMessage: controller.errorMessage,
        footerPrompt: 'Sudah punya akun?',
        footerAction: 'Masuk',
        onFooterTap: () => Navigator.of(context).pop(),
        onSubmit: _submit,
      ),
    );
  }
}
