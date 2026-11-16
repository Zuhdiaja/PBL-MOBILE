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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      if (controller.stage == ScanSubmissionStage.failed) {
        return Scaffold(
          body: SafeArea(
            child: ScanPage(
              children: [
                const Text('Pemeriksaan gagal', style: sectionTitleStyle),
                const SizedBox(height: 12),
                Text(
                  controller.error ?? 'Tautan belum dapat diperiksa.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 20),
                ScanButton(
                  label: 'Coba lagi',
                  icon: Icons.refresh_rounded,
                  onPressed: _run,
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        );
      }
      return ScanProcessingBody(
        urls: widget.urls,
        done: controller.done,
        total: controller.total,
        onCancel: () {
          controller.cancel();
          Navigator.of(context).pop();
        },
      );
    },
  );
}

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
    return ScanPage(
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
        const Text('Memeriksa tautan.', style: pageTitleStyle),
        const SizedBox(height: 10),
        Text(
          'Model memeriksa setiap URL satu per satu.',
          style: TextStyle(
            color: context.colors.muted,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: count == 0 ? null : done / count,
            minHeight: 6,
            backgroundColor: context.colors.line,
            color: context.colors.blue,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$done dari $count tautan selesai',
          style: TextStyle(fontSize: 11, color: context.colors.muted),
        ),
        const SizedBox(height: 20),
        for (var index = 0; index < urls.length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  index < done
                      ? Icons.check_circle_outline_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: index < done
                      ? context.colors.success
                      : context.colors.muted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    urls[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: index < done
                          ? context.colors.ink
                          : context.colors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const InfoNote('Model berjalan di server LinkGuard.'),
      ],
    );
  }
}
