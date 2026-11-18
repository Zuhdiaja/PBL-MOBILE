import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/scan_preview.dart';
import '../../domain/usecases/submit_scan.dart';
import '../controllers/scan_submission_controller.dart';

/// Runs the check and, when it finishes, summarises the outcome.
///
/// Returns the submission only when the user asks to see the results; closing
/// the summary leaves the caller on the input screen.
Future<ScanSubmission?> showScanPreview(
  BuildContext context,
  ScanPreview preview, {
  required ScanSubmissionController controller,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final submission = await Navigator.of(context).push<ScanSubmission>(
    MaterialPageRoute(
      builder: (_) => ScanProcessingScreen(
        urls: preview.urls.map((url) => url.value).toList(),
        controller: controller,
      ),
    ),
  );
  if (!context.mounted || submission == null) return null;

  final openResults = await showModalBottomSheet<bool>(
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
            const Text('Pemeriksaan selesai', style: sectionTitleStyle),
            const SizedBox(height: 8),
            Text(
              submission.failed == 0
                  ? '${submission.succeeded} tautan berhasil diperiksa.'
                  : '${submission.succeeded} tautan diperiksa, ${submission.failed} gagal.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),
            ScanButton(
              label: 'Lihat hasil',
              icon: Icons.shield_outlined,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 8),
            ScanButton(
              label: 'Kembali',
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
  return openResults == true ? submission : null;
}

/// Checks the URLs one by one and reports real progress.
class ScanProcessingScreen extends StatefulWidget {
  const ScanProcessingScreen({
    super.key,
    required this.urls,
    required this.controller,
  });
  final List<String> urls;
  final ScanSubmissionController controller;
  @override
  State<ScanProcessingScreen> createState() => _ScanProcessingScreenState();
}

class _ScanProcessingScreenState extends State<ScanProcessingScreen> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final submission = await widget.controller.submit(widget.urls);
    if (!mounted) return;
    if (submission != null && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop(submission);
    }
  }

  /// Stops after the URL in flight and leaves the processing page.
  void _cancel() {
    widget.controller.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      if (controller.stage == ScanSubmissionStage.failed) {
        return ScanProcessingFailure(
          message: controller.error ?? 'Tautan belum dapat diperiksa.',
          onRetry: _run,
          onCancel: _cancel,
        );
      }
      return ScanProcessingBody(
        urls: widget.urls,
        done: controller.done,
        total: controller.total,
        onCancel: _cancel,
      );
    },
  );
}

/// Shared frame for the processing states: a back-cancel header, the page
/// surface, and the scrolling body used by every other Input Scan page.
class _ProcessingFrame extends StatelessWidget {
  const _ProcessingFrame({required this.onCancel, required this.children});

  final VoidCallback onCancel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ScanPage(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Batalkan pemeriksaan',
                onPressed: onCancel,
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text('Pemeriksaan tautan', style: sectionTitleStyle),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    ),
  );
}

/// Surface card grouping the icon, headline, and supporting copy of a state.
class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.colors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _ProcessingIcon extends StatelessWidget {
  const _ProcessingIcon({required this.icon, this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: danger ? context.colors.paleDanger : context.colors.paleBlue,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(
      icon,
      size: 28,
      color: danger ? context.colors.danger : context.colors.blue,
    ),
  );
}

/// Progress while the model checks the links, one row per URL.
class ScanProcessingBody extends StatelessWidget {
  const ScanProcessingBody({
    super.key,
    required this.urls,
    required this.done,
    required this.total,
    required this.onCancel,
  });
  final List<String> urls;
  final int done;
  final int total;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final count = total == 0 ? urls.length : total;
    final progress = count == 0 ? 0.0 : (done / count).clamp(0.0, 1.0);
    final progressCopy = '$done dari $count tautan selesai';

    return _ProcessingFrame(
      onCancel: onCancel,
      children: [
        _ProcessingCard(
          children: [
            const _ProcessingIcon(icon: Icons.crop_free_rounded),
            const SizedBox(height: 18),
            const Text('Memeriksa tautan.', style: pageTitleStyle),
            const SizedBox(height: 8),
            Text(
              'Model memeriksa setiap URL satu per satu.',
              style: bodyStyle.copyWith(
                fontSize: 13,
                color: context.colors.muted,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Progres',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Semantics(
              label: 'Progres pemeriksaan',
              value: progressCopy,
              liveRegion: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: context.colors.line,
                  color: context.colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              progressCopy,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Tautan yang diperiksa',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < urls.length; index++) ...[
          _ProcessingUrlRow(
            url: urls[index],
            state: index < done
                ? _ProcessingUrlState.done
                : index == done
                ? _ProcessingUrlState.running
                : _ProcessingUrlState.waiting,
          ),
          if (index < urls.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 20),
        const InfoNote('Model berjalan di server LinkGuard.'),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onCancel,
            child: const Text('Batalkan'),
          ),
        ),
      ],
    );
  }
}

/// What the model is doing with one link, derived from the finished count.
enum _ProcessingUrlState { waiting, running, done }

class _ProcessingUrlRow extends StatelessWidget {
  const _ProcessingUrlRow({required this.url, required this.state});

  final String url;
  final _ProcessingUrlState state;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, background) = switch (state) {
      _ProcessingUrlState.done => (
        'Selesai',
        Icons.check_circle_rounded,
        context.colors.success,
        context.colors.paleSuccess,
      ),
      _ProcessingUrlState.running => (
        'Diperiksa',
        Icons.sync_rounded,
        context.colors.blue,
        context.colors.paleBlue,
      ),
      _ProcessingUrlState.waiting => (
        'Menunggu',
        Icons.schedule_rounded,
        context.colors.muted,
        context.colors.surface,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.softSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayHost(url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.colors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the submission failed, with the same frame as the progress page.
class ScanProcessingFailure extends StatelessWidget {
  const ScanProcessingFailure({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => _ProcessingFrame(
    onCancel: onCancel,
    children: [
      _ProcessingCard(
        children: [
          const _ProcessingIcon(
            icon: Icons.error_outline_rounded,
            danger: true,
          ),
          const SizedBox(height: 18),
          const Text('Pemeriksaan gagal', style: pageTitleStyle),
          const SizedBox(height: 8),
          Text(
            message,
            style: bodyStyle.copyWith(
              fontSize: 13,
              color: context.colors.muted,
            ),
          ),
          const SizedBox(height: 22),
          ScanButton(
            label: 'Coba lagi',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Kembali'),
            ),
          ),
        ],
      ),
    ],
  );
}
