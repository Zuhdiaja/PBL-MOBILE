import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/prediction_report.dart';
import '../controllers/report_prediction_controller.dart';
import '../widgets/scan_result_visuals.dart';

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
  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    final failure = widget.controller.submit();
    if (failure != null) {
      showScanMessage(context, failure);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Laporan berhasil dikirim. Terima kasih atas masukan Anda!',
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
  Widget build(BuildContext context) {
    final result = widget.controller.result;
    final color = ScanResultVisuals.statusColor(result);
    final background = ScanResultVisuals.statusBackground(result);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => ScanSubpage(
        title: 'Lapor hasil prediksi',
        onNavigate: widget.onNavigate,
        selectedIndex: 2,
        children: [
          const Text(
            'Bantu perbaiki kualitas klasifikasi dengan memberi koreksi pada hasil ini.',
            style: bodyStyle,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'URL yang dilaporkan',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.url,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.category,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Jenis laporan',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ReportTypeCard(
                  title: 'False Positive',
                  subtitle: 'Ditandai berbahaya, padahal aman.',
                  icon: Icons.check_circle_outline_rounded,
                  isSelected:
                      widget.controller.type == ReportType.falsePositive,
                  onTap: () =>
                      widget.controller.selectType(ReportType.falsePositive),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReportTypeCard(
                  title: 'False Negative',
                  subtitle: 'Ditandai aman, padahal berbahaya.',
                  icon: Icons.warning_amber_rounded,
                  isSelected:
                      widget.controller.type == ReportType.falseNegative,
                  onTap: () =>
                      widget.controller.selectType(ReportType.falseNegative),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Kategori yang benar',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: widget.controller.category.isEmpty
                ? null
                : widget.controller.category,
            hint: const Text(
              'Pilih kategori',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.blue),
              ),
            ),
            items: widget.controller.categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: widget.controller.selectCategory,
          ),
          const SizedBox(height: 6),
          const Text(
            'Pilih kategori menurut penilaian Anda.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 24),
          const Text(
            'Catatan laporan',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: widget.controller.notes,
            maxLines: 4,
            style: const TextStyle(color: AppColors.ink, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Jelaskan alasan atau informasi pendukung...',
              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.blue),
              ),
            ),
          ),
          const SizedBox(height: 28),
          ScanButton(
            label: 'Kirim laporan',
            icon: Icons.arrow_forward_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _ReportTypeCard extends StatelessWidget {
  const _ReportTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.paleBlue : Colors.white,
        border: Border.all(
          color: isSelected ? AppColors.blue : AppColors.line,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.blue : AppColors.muted,
            size: 22,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.blue : AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}
