import 'package:flutter/material.dart';

import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_form.dart';

/// Signs an existing user in.
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.controller,
    required this.demoAccount,
    required this.registerPageBuilder,
    required this.onSignedIn,
  });

  final AuthController controller;

  /// Prefills the form so the demo credentials are one tap away.
  final UserAccount demoAccount;

  /// Built by the app layer so this feature does not own navigation.
  final WidgetBuilder registerPageBuilder;

  /// Called once the session is open.
  final VoidCallback onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailController = TextEditingController(
    text: widget.demoAccount.email,
  );
  late final TextEditingController _passwordController =
      TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final signedIn = widget.controller.submitSignIn(
      SignInRequest(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
    if (signedIn) widget.onSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AuthForm(
        title: 'Selamat datang kembali',
        subtitle: 'Masuk untuk melihat riwayat pemeriksaan dan status laporan.',
        fields: [
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
        actionLabel: 'Masuk',
        errorMessage: controller.errorMessage,
        footerPrompt: 'Belum punya akun?',
        footerAction: 'Daftar sekarang',
        onFooterTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: widget.registerPageBuilder)),
        onSubmit: _submit,
      ),
    );
  }
}
