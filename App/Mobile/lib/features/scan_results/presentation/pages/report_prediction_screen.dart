import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/prediction_report.dart';
import '../controllers/report_prediction_controller.dart';

class ReportPredictionScreen extends StatefulWidget {
  const ReportPredictionScreen({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onNavigate,
  });

  final ReportPredictionController controller;

  /// Invoked after a report is accepted by the repository.
  final VoidCallback? onSubmitted;
  final ValueChanged<int>? onNavigate;

  @override
  State<ReportPredictionScreen> createState() => _ReportPredictionScreenState();
}

class _ReportPredictionScreenState extends State<ReportPredictionScreen> {
  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    c.selectType(
      c.result.isSafe ? ReportType.falseNegative : ReportType.falsePositive,
    );
    if (!c.result.isSafe && c.category.isEmpty) {
      c.selectCategory(
        c.categories.firstWhere(_isSafeCategory, orElse: () => ''),
      );
    }
  }

  static bool _isSafeCategory(String value) =>
      value == 'Benign' || value.startsWith('Aman');

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.controller.notes.text.trim().isEmpty) {
      showScanMessage(context, 'Tambahkan catatan untuk menjelaskan koreksi.');
      return;
    }
    final failure = await widget.controller.submit();
    if (!mounted) return;
    if (failure != null) {
      showScanMessage(context, failure);
      return;
    }
    final reportId = widget.controller.lastSubmitted?.id;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            reportId == null
                ? 'Laporan berhasil dikirim. Terima kasih atas masukan Anda!'
                : 'Laporan #$reportId berhasil dikirim. Terima kasih atas masukan Anda!',
          ),
        ),
      );
    final onSubmitted = widget.onSubmitted;
    if (onSubmitted != null) {
      onSubmitted();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      return ScanSubpage(
        title: 'Koreksi hasil',
        onNavigate: widget.onNavigate,
        selectedIndex: 2,
        children: [
          Text(
            c.result.url,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Text(
                'Hasil saat ini',
                style: TextStyle(fontSize: 13, color: context.colors.muted),
              ),
              CategoryBadge(c.result.category),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: context.colors.line),
          const SizedBox(height: 18),
          Text(
            c.type == ReportType.falsePositive
                ? 'Positif palsu'
                : 'Negatif palsu',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            c.type == ReportType.falsePositive
                ? 'Tautan ini seharusnya aman.'
                : 'Tautan ini seharusnya perlu perhatian.',
            style: TextStyle(fontSize: 13, color: context.colors.muted),
          ),
          const SizedBox(height: 24),
          const Text(
            'Kategori koreksi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (c.type == ReportType.falsePositive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: context.colors.paleSuccess,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: context.colors.success,
                    size: 23,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Aman',
                    style: TextStyle(
                      color: context.colors.success,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: c.category.isEmpty ? null : c.category,
              isExpanded: true,
              hint: const Text('Pilih kategori'),
              items: c.categories
                  .where((value) => !_isSafeCategory(value))
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        categoryLabel(value),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: c.selectCategory,
            ),
          const SizedBox(height: 24),
          const Text(
            'Catatan laporan (wajib)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: c.notes,
            maxLines: 4,
            style: TextStyle(fontSize: 14, color: context.colors.ink),
            decoration: const InputDecoration(
              hintText: 'Jelaskan alasan atau bukti pendukung…',
            ),
          ),
          const SizedBox(height: 24),
          ScanButton(
            label: c.isSubmitting ? 'Mengirim laporan…' : 'Kirim laporan',
            icon: c.isSubmitting
                ? Icons.hourglass_top_rounded
                : Icons.arrow_forward_rounded,
            onPressed: c.isSubmitting ? null : _submit,
          ),
        ],
      );
    },
  );
}
