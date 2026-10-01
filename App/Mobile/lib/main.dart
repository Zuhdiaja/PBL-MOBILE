import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/app_colors.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LinkGuard',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
    ),
    home: const LoginScreen(),
  );
}
