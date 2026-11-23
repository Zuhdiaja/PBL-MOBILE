import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app/auth_dependencies.dart';
import 'app/theme_dependencies.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'screens/main_shell.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_preference_store.dart';
import 'widgets/startup_gate.dart';
import 'notifications/push_notification_service.dart';
import 'notifications/push_account.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final theme = ThemeDependencies();
  await theme.controller.load();
  PushNotificationService? push;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      push = PushNotificationService();
      await push.initialize().timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint('Notifikasi tidak tersedia: $error');
      push?.dispose();
      push = null;
    }
  }
  runApp(MyApp(theme: theme.controller, push: push));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.theme, this.auth, this.push});

  /// App-wide theme choice. When omitted the app follows the device theme
  /// without persistence, which keeps widget tests plugin-free.
  final ThemeController? theme;

  /// Auth wiring override for tests. The app builds the real one when omitted.
  final AuthDependencies? auth;
  final PushNotificationService? push;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _theme = widget.theme ?? ThemeController(MemoryThemeStore());

  @override
  void dispose() {
    _theme.dispose();
    widget.push?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppThemeScope(
    controller: _theme,
    child: ListenableBuilder(
      listenable: _theme,
      child: _LaunchGate(auth: widget.auth, push: widget.push),
      builder: (context, child) => MaterialApp(
        title: 'LinkGuard',
        debugShowCheckedModeBanner: false,
        theme: linkGuardTheme(Brightness.light),
        darkTheme: linkGuardTheme(Brightness.dark),
        themeMode: _theme.mode,
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
  const _LaunchGate({this.auth, this.push});
  final AuthDependencies? auth;
  final PushNotificationService? push;
  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  late final bool _ownsAuth = widget.auth == null;
  late final AuthDependencies _auth = widget.auth ?? AuthDependencies();

  @override
  void dispose() {
    if (_ownsAuth) _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StartupGate(
    controller: _auth.auth,
    child: _WelcomeGate(auth: _auth, push: widget.push),
  );
}

class _WelcomeGate extends StatefulWidget {
  const _WelcomeGate({required this.auth, this.push});
  final AuthDependencies auth;
  final PushNotificationService? push;

  @override
  State<_WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<_WelcomeGate> {
  bool _onboardingComplete = false;

  Future<void> _completeOnboarding() async {
    final permission = widget.push?.permission;
    if (permission != null && await permission.shouldExplain() && mounted) {
      if (!mounted) return;
      final enable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notifikasi laporan'),
          content: const Text(
            'Aktifkan notifikasi untuk menerima kabar tentang laporan LinkGuard.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Aktifkan'),
            ),
          ],
        ),
      );
      if (enable != null) await permission.markExplained();
      if (enable == true) {
        final granted = await permission.request();
        if (!granted && mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Notifikasi belum aktif'),
              content: const Text(
                'Anda dapat mengaktifkan notifikasi melalui pengaturan aplikasi.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    permission.openSettings();
                  },
                  child: const Text('Buka pengaturan'),
                ),
              ],
            ),
          );
        }
      }
    }
    if (mounted) setState(() => _onboardingComplete = true);
  }

  @override
  Widget build(BuildContext context) => _onboardingComplete
      ? _AuthGate(auth: widget.auth, push: widget.push)
      : OnboardingPage(onComplete: _completeOnboarding);
}

/// Swaps between login and the app shell using the launch gate’s session.
///
/// It lives inside [MaterialApp] and renders the current screen directly
/// instead of pushing routes. The launch gate owns the shared dependencies.
class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.auth, this.push});
  final AuthDependencies auth;
  final PushNotificationService? push;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _pushAccount;
  @override
  void initState() {
    super.initState();
    _auth.auth.addListener(_syncPush);
    _syncPush();
  }

  void _syncPush() {
    final id = _auth.auth.account?.id;
    if (_pushAccount == id) return;
    _pushAccount = id;
    PushAccount.accountId = id;
    if (id != null) {
      unawaited(
        PushAccount.preference(refresh: true).catchError((Object _) => false),
      );
      final tokens = widget.push?.tokens;
      if (tokens != null) unawaited(tokens.sync().catchError((Object _) {}));
    } else {
      widget.push?.navigation.take();
    }
  }

  @override
  void dispose() {
    _auth.auth.removeListener(_syncPush);
    super.dispose();
  }

  /// Shared so the session survives navigation between login and the shell.
  AuthDependencies get _auth => widget.auth;

  Future<void> _signOut() async {
    await widget.push?.tokens.unlink();
    await _auth.auth.submitSignOut();
  }

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
        ? MainShell(
            auth: _auth,
            onSignOut: _signOut,
            notificationNavigation: widget.push?.navigation,
          )
        : _buildLoginPage(),
  );
}
