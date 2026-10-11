import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/auth_dependencies.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'screens/main_shell.dart';
import 'theme/app_colors.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LinkGuard',
    debugShowCheckedModeBanner: false,
    builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: child!,
    ),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blue,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.blue
                : AppColors.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? AppColors.blue
                : AppColors.muted,
          ),
        ),
      ),
      useMaterial3: true,
    ),
    home: const _AuthGate(),
  );
}

/// Owns the auth dependencies and swaps between login and the app shell.
///
/// It lives inside [MaterialApp] and renders the current screen directly
/// instead of pushing routes, so the shared dependencies outlive both screens.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  /// Shared so the session survives navigation between login and the shell.
  final _auth = AuthDependencies();

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  void _signOut() => _auth.auth.submitSignOut();

  Widget _buildLoginPage() => LoginPage(
    controller: _auth.auth,
    demoAccount: _auth.demoAccount,
    registerPageBuilder:
        // The gate rebuilds into the shell once the session opens, so this
        // page only needs to get out of the way.
        (_) => RegisterPage(
          controller: _auth.auth,
          onRegistered: () => Navigator.of(context).maybePop(),
        ),
    onSignedIn: () {},
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _auth.auth,
    builder: (context, _) => _auth.auth.isSignedIn
        ? MainShell(auth: _auth, onSignOut: _signOut)
        : _buildLoginPage(),
  );
}
