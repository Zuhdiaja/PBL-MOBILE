import 'dart:async';

import 'package:flutter/material.dart';

import '../app/auth_dependencies.dart';
import '../app/history_dependencies.dart';
import '../app/input_scan_dependencies.dart';
import '../app/scan_results_dependencies.dart';
import '../features/auth/presentation/pages/profile_page.dart';
import '../features/auth/presentation/pages/settings_page.dart';
import '../features/history/presentation/pages/history_screen.dart';
import '../features/history/presentation/pages/notifications_screen.dart';
import '../features/history/presentation/pages/report_status_screen.dart';
import '../features/history/presentation/pages/stats_screen.dart';
import '../features/input_scan/presentation/pages/home_screen.dart';
import '../features/input_scan/presentation/pages/scan_qr_screen.dart';
import '../features/input_scan/presentation/pages/scan_url_screen.dart';
import '../features/input_scan/presentation/pages/share_link_screen.dart';
import '../features/scan_results/domain/entities/scan_result.dart';
import '../features/scan_results/presentation/pages/report_prediction_screen.dart';
import '../features/scan_results/presentation/pages/scan_detail_screen.dart';
import '../features/scan_results/presentation/pages/scan_result_screen.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/scan_components.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.auth, required this.onSignOut});

  /// Auth wiring shared with the login screen.
  final AuthDependencies auth;

  /// Called after the session is closed.
  final VoidCallback onSignOut;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final _inputScan = InputScanDependencies();
  late final _scanResults = ScanResultsDependencies(
    tokenStore: widget.auth.apiTokenStore,
  );
  late final _history = HistoryDependencies(
    tokenStore: widget.auth.apiTokenStore,
    accountRepository: widget.auth.accountRepository,
  );
  StreamSubscription<String>? _shareSubscription;

  @override
  void initState() {
    super.initState();
    _listenForSharedLinks();
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    _inputScan.dispose();
    _scanResults.dispose();
    _history.dispose();
    super.dispose();
  }

  /// Opens the share form when another app hands LinkGuard a link.
  ///
  /// The plugin is unavailable in previews and widget tests, so a missing
  /// platform channel is ignored instead of surfacing an error.
  Future<void> _listenForSharedLinks() async {
    try {
      final initial = await _inputScan.shareIntent.takeInitialText();
      final url = _inputScan.extractSharedUrl(initial);
      if (url != null) _openSharedLink(url);
    } catch (_) {
      // No share sheet on this platform.
    }
    _shareSubscription = _inputScan.shareIntent.textStream().listen((text) {
      final url = _inputScan.extractSharedUrl(text);
      if (url != null) _openSharedLink(url);
    }, onError: (_) {});
  }

  void _openSharedLink(String url) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ShareLinkScreen(
            controller: _inputScan.createShareLink(initialUrl: url),
            onNavigate: _selectTab,
            onViewResults: _openResults,
          ),
        ),
      );
    });
  }

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedIndex = index);
  }

  Future<void> _openScan({bool paste = false}) async {
    _selectTab(2);
    if (paste) {
      final message = await _inputScan.scanUrl.pasteIntoFirstField();
      if (mounted && message != null) showScanMessage(context, message);
    }
  }

  void _openResults() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ScanResultScreen(
        controller: _scanResults.scanResults,
        onOpenDetail: _openDetail,
        onNavigate: _selectTab,
      ),
    ),
  );

  void _openDetail(ScanResult result) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ScanDetailScreen(
        result: result,
        loadResult: () => _scanResults.loadResult(result.id),
        onReport: _openReport,
        onNavigate: _selectTab,
      ),
    ),
  );

  void _openReport(ScanResult result) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReportPredictionScreen(
        controller: _scanResults.createReportController(result),
        onNavigate: _selectTab,
      ),
    ),
  );

  void _openNotifications() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NotificationsScreen(controller: _history.notifications),
    ),
  );

  void _openReportStatus() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReportStatusScreen(controller: _history.reportStatus),
    ),
  );

  void _openQr() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ScanQrScreen(
        controller: _inputScan.scanQr,
        onNavigate: _selectTab,
        onViewResults: _openResults,
      ),
    ),
  );

  void _openShare() {
    final controller = _inputScan.createShareLink();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShareLinkScreen(
          controller: controller,
          onNavigate: _selectTab,
          onViewResults: _openResults,
        ),
      ),
    );
  }

  void _openSettings() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SettingsPage(
        controller: widget.auth.settings,
        onNavigate: _selectTab,
      ),
    ),
  );

  void _signOut() {
    widget.auth.auth.submitSignOut();
    widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: IndexedStack(
        index: _selectedIndex,
        children:
            [
                  HomeScreen(
                    controller: _inputScan.home,
                    name:
                        (widget.auth.auth.account ?? widget.auth.displayAccount)
                            .firstName,
                    initials:
                        (widget.auth.auth.account ?? widget.auth.displayAccount)
                            .initials,
                    onNotifications: _openNotifications,
                    onRecentScan: (scan) =>
                        _openDetail(_scanResults.findResult(scan.id)),
                    onScan: _openScan,
                    onPaste: () => _openScan(paste: true),
                    onQr: _openQr,
                    onShare: _openShare,
                    onHistory: () => _selectTab(3),
                    onProfile: () => _selectTab(4),
                  ),
                  StatsScreen(controller: _history.stats),
                  ScanUrlScreen(
                    controller: _inputScan.scanUrl,
                    onQr: _openQr,
                    onShare: _openShare,
                    onViewResults: _openResults,
                  ),
                  HistoryScreen(
                    controller: _history.history,
                    onOpenDetail: (entry) =>
                        _openDetail(_scanResults.findResult(entry.id)),
                  ),
                  ProfilePage(
                    controller: widget.auth.profile,
                    account:
                        widget.auth.auth.account ?? widget.auth.displayAccount,
                    onSettings: _openSettings,
                    onSignOut: _signOut,
                    onReportStatus: _openReportStatus,
                    onNotifications: _openNotifications,
                  ),
                ].indexed
                .map(
                  (entry) => TickerMode(
                    enabled: entry.$1 == _selectedIndex,
                    child: entry.$2,
                  ),
                )
                .toList(),
      ),
    ),
    bottomNavigationBar: AppBottomNavigation(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _selectTab,
    ),
  );
}
