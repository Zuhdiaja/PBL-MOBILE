import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/auth_dependencies.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'screens/main_shell.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/startup_gate.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _theme = ValueNotifier(ThemeMode.system);
  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppThemeScope(
    controller: _theme,
    child: ValueListenableBuilder<ThemeMode>(
      valueListenable: _theme,
      child: const _LaunchGate(),
      builder: (context, mode, child) => MaterialApp(
        title: 'LinkGuard',
        debugShowCheckedModeBanner: false,
        theme: linkGuardTheme(Brightness.light),
        darkTheme: linkGuardTheme(Brightness.dark),
        themeMode: mode,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: context.colors.dark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: context.colors.dark
                ? Brightness.dark
                : Brightness.light,
            systemNavigationBarColor: context.colors.paper,
            systemNavigationBarIconBrightness: context.colors.dark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: child!,
        ),
        home: child,
      ),
    ),
  );
}

class _LaunchGate extends StatefulWidget {
  const _LaunchGate();
  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  final _auth = AuthDependencies();

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StartupGate(
    controller: _auth.auth,
    child: _AuthGate(auth: _auth),
  );
}

/// Swaps between login and the app shell using the launch gate’s session.
///
/// It lives inside [MaterialApp] and renders the current screen directly
/// instead of pushing routes. The launch gate owns the shared dependencies.
class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.auth});
  final AuthDependencies auth;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  /// Shared so the session survives navigation between login and the shell.
  AuthDependencies get _auth => widget.auth;

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
