import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'scan_components.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.kind, this.url});
  final String kind;
  final String? url;
  static const titles = {
    'home': 'Beranda',
    'history': 'Riwayat pindai',
    'stats': 'Statistik',
    'profile': 'Profil',
    'detail': 'Detail hasil',
    'results': 'Hasil pindai',
    'reports': 'Status laporan',
    'notifications': 'Notifikasi',
  };
  @override
  Widget build(BuildContext context) {
    final title = titles[kind] ?? kind;
    return LoadingPulse(
      child: Semantics(
        label: 'Memuat $title',
        liveRegion: true,
        child: ScanPage(
          children: [
            if ([
              'detail',
              'results',
              'reports',
              'notifications',
            ].contains(kind))
              Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: Text(title, style: sectionTitleStyle)),
                ],
              )
            else
              Text(title, style: pageTitleStyle),
            const SizedBox(height: 24),
            ...switch (kind) {
              'results' => _results(context),
              'detail' => _detail(context),
              'stats' => _stats(context),
              'reports' => _reports(context),
              'notifications' => _notifications(context),
              _ => [const SkeletonRows(count: 3)],
            },
            const SizedBox(height: 20),
            Text(
              'Memuat ${title.toLowerCase()}…',
              style: TextStyle(fontSize: 12, color: context.colors.muted),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(BuildContext context) => [
    const SkeletonBox(width: 164, height: 18),
    const SizedBox(height: 10),
    const SkeletonBox(width: 210, height: 12),
    const SizedBox(height: 24),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 15),
                  SizedBox(height: 12),
                  SkeletonBox(width: 112, height: 18),
                ],
              ),
            ),
            if (i < 2) Divider(height: 1, color: context.colors.line),
          ],
        ],
      ),
    ),
    const SizedBox(height: 24),
    ScanButton(
      label: 'Periksa URL lain',
      icon: Icons.arrow_forward_rounded,
      onPressed: () => Navigator.of(context).maybePop(),
    ),
  ];

  List<Widget> _detail(BuildContext context) => [
    const Row(
      children: [
        SkeletonBox(width: 42, height: 42),
        SizedBox(width: 12),
        SkeletonBox(width: 118, height: 22),
      ],
    ),
    const SizedBox(height: 14),
    if (url != null)
      SelectableText(
        url!,
        style: TextStyle(fontSize: 13, color: context.colors.muted),
      )
    else
      const SkeletonBox(width: 210, height: 13),
    const SizedBox(height: 20),
    Divider(color: context.colors.line),
    const SizedBox(height: 18),
    const Text(
      'Saran keamanan',
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 14),
    const _SkeletonLines(count: 3),
    const SizedBox(height: 24),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tingkat risiko', style: TextStyle(fontSize: 11)),
                SizedBox(height: 12),
                SkeletonBox(width: 68, height: 18),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keyakinan model', style: TextStyle(fontSize: 11)),
                SizedBox(height: 12),
                SkeletonBox(width: 54, height: 18),
              ],
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 24),
    const Text(
      'Arti keyakinan model',
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 12),
    const _SkeletonLines(count: 3),
    const SizedBox(height: 24),
    const Text(
      'Rincian pemeriksaan',
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    const SkeletonRows(count: 2),
    Divider(color: context.colors.line),
    for (final label in ['Waktu pemindaian', 'Model', 'Metode'])
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: context.colors.muted),
              ),
            ),
            const SkeletonBox(width: 100, height: 12),
          ],
        ),
      ),
  ];

  List<Widget> _stats(BuildContext context) => [
    Row(
      children: [
        Expanded(
          child: Text(
            'Total pemindaian',
            style: TextStyle(fontSize: 14, color: context.colors.muted),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: context.colors.softSurface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('7 hari terakhir', style: TextStyle(fontSize: 11)),
        ),
      ],
    ),
    const SizedBox(height: 12),
    const SkeletonBox(width: 64, height: 42),
    const SizedBox(height: 22),
    const SkeletonBox(height: 7),
    const SizedBox(height: 14),
    const Row(
      children: [
        SkeletonBox(width: 110, height: 11),
        Spacer(),
        SkeletonBox(width: 110, height: 11),
      ],
    ),
    const SizedBox(height: 28),
    const Text('Aktivitas tujuh hari', style: sectionTitleStyle),
    const SizedBox(height: 16),
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        height: 158,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SkeletonBox(
                        height: const [
                          35.0,
                          56.0,
                          42.0,
                          76.0,
                          60.0,
                          96.0,
                          80.0,
                        ][i],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        const [
                          'Sab',
                          'Min',
                          'Sen',
                          'Sel',
                          'Rab',
                          'Kam',
                          'Jum',
                        ][i],
                        style: TextStyle(
                          fontSize: 10,
                          color: context.colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 28),
    Row(
      children: [
        for (final label in ['Phishing', 'Malware', 'Laporan'])
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 36, height: 24),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: context.colors.muted),
                ),
              ],
            ),
          ),
      ],
    ),
  ];

  List<Widget> _reports(BuildContext context) => [
    Text(
      'Pantau proses peninjauan laporan yang telah Anda kirim.',
      style: TextStyle(fontSize: 13, height: 1.7, color: context.colors.muted),
    ),
    const SizedBox(height: 14),
    const SkeletonBox(width: 160, height: 11),
    const SizedBox(height: 10),
    for (var i = 0; i < 3; i++) ...[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.description_outlined,
              size: 20,
              color: context.colors.muted,
            ),
            const SizedBox(width: 12),
            const Expanded(child: _SkeletonLines(count: 3)),
            const SizedBox(width: 12),
            const SkeletonBox(width: 52, height: 21),
          ],
        ),
      ),
      Divider(height: 1, color: context.colors.line),
    ],
  ];

  List<Widget> _notifications(BuildContext context) => [
    Text(
      'Pemberitahuan saat laporan selesai ditinjau.',
      style: TextStyle(fontSize: 13, height: 1.7, color: context.colors.muted),
    ),
    const SizedBox(height: 12),
    const Row(
      children: [
        Expanded(child: SkeletonBox(width: 120, height: 11)),
        SizedBox(width: 16),
        TextButton(
          onPressed: null,
          child: Text('Tandai semua dibaca', style: TextStyle(fontSize: 11)),
        ),
      ],
    ),
    for (var i = 0; i < 4; i++) ...[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: context.colors.muted,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLines(count: 3),
                  SizedBox(height: 10),
                  SkeletonBox(width: 44, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
      Divider(height: 1, color: context.colors.line),
    ],
  ];
}

class _SkeletonLines extends StatelessWidget {
  const _SkeletonLines({this.count = 2});
  final int count;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < count; i++)
        Padding(
          padding: EdgeInsets.only(bottom: i < count - 1 ? 12 : 0),
          child: FractionallySizedBox(
            widthFactor: i == count - 1 ? .65 : 1,
            child: const SkeletonBox(height: 12),
          ),
        ),
    ],
  );
}

class SkeletonRows extends StatelessWidget {
  const SkeletonRows({super.key, this.count = 3});
  final int count;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < count; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 22, height: 22),
              SizedBox(width: 12),
              Expanded(child: _SkeletonLines()),
            ],
          ),
        ),
    ],
  );
}

class LoadingRows extends StatelessWidget {
  const LoadingRows({super.key, required this.label, this.count = 3});
  final String label;
  final int count;
  @override
  Widget build(BuildContext context) => LoadingPulse(
    child: Semantics(
      label: label,
      liveRegion: true,
      child: SkeletonRows(count: count),
    ),
  );
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14});
  final double? width;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Color.lerp(
        context.colors.paper,
        context.colors.skeleton,
        _SkeletonPulseScope.maybeOf(context),
      ),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    this.onComplete,
    this.busy = false,
    this.recovery,
  });
  final VoidCallback? onComplete;
  final bool busy;
  final Widget? recovery;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: context.colors.scanner,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: context.colors.scanner,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.scannerAccent),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'LinkGuard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Periksa sebelum membuka.',
                    style: TextStyle(
                      color: AppColors.scannerCopy,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (onComplete != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 450),
                      onEnd: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) onComplete?.call();
                        });
                      },
                      builder: (context, value, _) => SizedBox(
                        width: 120,
                        height: 2,
                        child: LinearProgressIndicator(
                          value:
                              busy && !MediaQuery.disableAnimationsOf(context)
                              ? null
                              : value,
                          color: AppColors.scannerAccent,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 2),
                  if (recovery != null) ...[
                    const SizedBox(height: 24),
                    recovery!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// One pulse per loading page; stops when hidden, completed or motion is reduced.
class LoadingPulse extends StatefulWidget {
  const LoadingPulse({super.key, required this.child});
  final Widget child;
  @override
  State<LoadingPulse> createState() => _LoadingPulseState();
}

class _LoadingPulseState extends State<LoadingPulse>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => _SkeletonPulseScope(
      value: .62 + .38 * _controller.value,
      child: child!,
    ),
  );
}

class _SkeletonPulseScope extends InheritedWidget {
  const _SkeletonPulseScope({required this.value, required super.child});
  final double value;
  static double maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_SkeletonPulseScope>()
          ?.value ??
      1;
  @override
  bool updateShouldNotify(_SkeletonPulseScope oldWidget) =>
      oldWidget.value != value;
}
