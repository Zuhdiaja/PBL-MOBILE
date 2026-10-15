import 'dart:async';

import '../../domain/usecases/prepare_scan_preview.dart';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/scan_preview.dart';

Future<void> showScanPreview(
  BuildContext context,
  ScanPreview preview, {
  required VoidCallback onViewResults,
  required FutureOr<PreviewResult> Function() preparePreview,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final ready = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => ScanProcessingScreen(
        urls: preview.urls.map((url) => url.value).toList(),
        preparePreview: preparePreview,
      ),
    ),
  );
  if (!context.mounted || ready != true) return;
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pratinjau pemeriksaan', style: sectionTitleStyle),
            const SizedBox(height: 8),
            const Text(
              'Tautan siap diperiksa. Belum ada penilaian keamanan pada pratinjau ini.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),
            for (final url in preview.urls)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.link, size: 21, color: context.colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        url.value,
                        style: TextStyle(
                          color: context.colors.ink,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            ScanButton(
              label: 'Lihat hasil contoh',
              icon: Icons.shield_outlined,
              onPressed: () {
                Navigator.of(context).pop();
                onViewResults();
              },
            ),
            const SizedBox(height: 8),
            ScanButton(
              label: 'Kembali',
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The phases follow local preparation work, not an animation's elapsed time.
class ScanProcessingScreen extends StatefulWidget {
  const ScanProcessingScreen({
    super.key,
    required this.urls,
    required this.preparePreview,
  });
  final List<String> urls;
  final FutureOr<PreviewResult> Function() preparePreview;
  @override
  State<ScanProcessingScreen> createState() => _ScanProcessingScreenState();
}

class _ScanProcessingScreenState extends State<ScanProcessingScreen> {
  int _stage = 0;
  bool _cancelled = false;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    for (var stage = 0; stage < 3; stage++) {
      // Give each completed phase a frame; never add a fake network delay.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _cancelled) return;
      setState(() {
        _stage = stage;
        _failed = false;
      });
      try {
        if (stage == 1) {
          final result = await widget.preparePreview();
          if (result.failure != null) {
            throw StateError('Preview preparation failed');
          }
        }
      } catch (_) {
        if (mounted && !_cancelled) setState(() => _failed = true);
        return;
      }
      if (!mounted || _cancelled) return;
    }
    if (mounted && !_cancelled && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: _failed
          ? ScanPage(
              children: [
                const Text(
                  'Pratinjau belum dapat disiapkan.',
                  style: sectionTitleStyle,
                ),
                const SizedBox(height: 20),
                ScanButton(
                  label: 'Coba lagi',
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    setState(() => _failed = false);
                    _prepare();
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Kembali'),
                ),
              ],
            )
          : ScanProcessingBody(
              urls: widget.urls,
              stage: _stage,
              onCancel: () {
                _cancelled = true;
                Navigator.of(context).pop(false);
              },
            ),
    ),
  );
}

class ScanProcessingBody extends StatelessWidget {
  const ScanProcessingBody({
    super.key,
    required this.urls,
    required this.stage,
    required this.onCancel,
  });
  final List<String> urls;
  final int stage;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) => ScanPage(
    children: [
      Row(
        children: [
          const Expanded(child: LinkGuardBrand(size: 19)),
          TextButton(onPressed: onCancel, child: const Text('Batalkan')),
        ],
      ),
      const SizedBox(height: 32),
      Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: context.colors.paleBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          Icons.crop_free_rounded,
          size: 34,
          color: context.colors.blue,
        ),
      ),
      const SizedBox(height: 24),
      const Text('Menyiapkan tautan.', style: pageTitleStyle),
      const SizedBox(height: 10),
      Text(
        'Sebentar, pratinjau Anda sedang disiapkan.',
        style: TextStyle(
          color: context.colors.muted,
          fontSize: 13,
          height: 1.6,
        ),
      ),
      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          urls.length == 1 ? urls.first : '${urls.length} tautan',
          style: const TextStyle(fontSize: 13),
        ),
      ),
      const SizedBox(height: 24),
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: stage == i && !MediaQuery.disableAnimationsOf(context)
                    ? SizedBox(
                        key: ValueKey('active-$i'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.blue,
                          semanticsLabel: const [
                            'Menyiapkan tautan',
                            'Memvalidasi format URL',
                            'Menyiapkan pratinjau',
                          ][i],
                        ),
                      )
                    : Icon(
                        key: ValueKey('stage-$i-${stage > i}'),
                        stage > i
                            ? Icons.check_circle_outline_rounded
                            : Icons.radio_button_checked_rounded,
                        color: stage >= i
                            ? context.colors.blue
                            : context.colors.line,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  const [
                    'Menyiapkan tautan',
                    'Memvalidasi format URL',
                    'Menyiapkan pratinjau',
                  ][i],
                  style: TextStyle(
                    fontSize: 13,
                    color: stage >= i
                        ? context.colors.ink
                        : context.colors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 20),
      const InfoNote('Pratinjau lokal, tanpa penilaian keamanan URL.'),
    ],
  );
}
