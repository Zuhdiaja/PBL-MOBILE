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
    required this.registerPageBuilder,
    required this.onSignedIn,
    this.demoAccount,
  });

  final AuthController controller;

  /// Prefills the form for previews. The real app passes null.
  final UserAccount? demoAccount;

  /// Built by the app layer so this feature does not own navigation.
  final WidgetBuilder registerPageBuilder;

  /// Called once the session is open.
  final VoidCallback onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailController = TextEditingController(
    text: widget.demoAccount?.email ?? '',
  );
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final signedIn = await widget.controller.submitSignIn(
      SignInRequest(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
    if (signedIn && mounted) widget.onSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AuthForm(
        title: 'Masuk.',
        subtitle: 'Lanjutkan untuk melihat riwayat Anda.',
        fields: [
          AuthField(
            label: 'Email',
            hint: 'nama@email.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          AuthField(
            label: 'Kata sandi',
            hint: 'Kata sandi Anda',
            obscure: true,
            controller: _passwordController,
          ),
        ],
        actionLabel: 'Masuk',
        errorMessage: controller.errorMessage,
        isSubmitting: controller.isSubmitting,
        footerPrompt: 'Belum punya akun?',
        footerAction: 'Daftar sekarang',
        onFooterTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: widget.registerPageBuilder)),
        onSubmit: _submit,
      ),
    );
  }
}
