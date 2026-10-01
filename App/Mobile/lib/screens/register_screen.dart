import 'package:flutter/material.dart';

import '../widgets/auth_screen.dart';
import 'main_shell.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => AuthScreen(
    title: 'Buat akun baru',
    subtitle: 'Simpan riwayat scan dan pantau laporan keamanan Anda.',
    fields: const [
      AuthField(label: 'Nama lengkap', hint: 'Nama Anda'),
      AuthField(label: 'Email', hint: 'nama@email.com'),
      AuthField(label: 'Password', hint: 'Minimal 6 karakter', obscure: true),
    ],
    actionLabel: 'Daftar',
    footerPrompt: 'Sudah punya akun?',
    footerAction: 'Masuk',
    onFooterTap: () => Navigator.of(context).pop(),
    onSubmit: () => _openHome(context),
  );
}

void _openHome(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const MainShell()),
    (route) => false,
  );
}
