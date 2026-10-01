import 'package:flutter/material.dart';

import '../data/demo_account.dart';
import '../widgets/auth_screen.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: DemoAccount.email);
  final _passwordController = TextEditingController(text: DemoAccount.password);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthScreen(
    title: 'Selamat datang kembali',
    subtitle: 'Masuk untuk melihat riwayat pemeriksaan dan status laporan.',
    fields: [
      AuthField(
        label: 'Email',
        hint: 'nama@email.com',
        controller: _emailController,
      ),
      AuthField(
        label: 'Password',
        hint: 'Minimal 6 karakter',
        obscure: true,
        controller: _passwordController,
      ),
    ],
    actionLabel: 'Masuk',
    footerPrompt: 'Belum punya akun?',
    footerAction: 'Daftar sekarang',
    onFooterTap: () => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen())),
    onSubmit: _submit,
  );

  void _submit() {
    if (DemoAccount.matches(_emailController.text, _passwordController.text)) {
      _openHome(context);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Email atau password salah.')),
      );
  }
}

void _openHome(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const MainShell()),
    (route) => false,
  );
}
