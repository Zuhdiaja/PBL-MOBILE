import 'package:flutter/material.dart';

import '../data/scan_result.dart';
import '../theme/app_colors.dart';
import '../widgets/scan_components.dart';

enum ReportType { falsePositive, falseNegative }

class ReportPredictionScreen extends StatefulWidget {
  const ReportPredictionScreen({
    super.key,
    this.item,
    this.onNavigate,
  });

  final ScanResultItem? item;
  final ValueChanged<int>? onNavigate;

  @override
  State<ReportPredictionScreen> createState() =>
      _ReportPredictionScreenState();
}

class _ReportPredictionScreenState extends State<ReportPredictionScreen> {
  ReportType _selectedType = ReportType.falsePositive;
  String? _selectedCategory;
  final _notesController = TextEditingController();

  final List<String> _categories = [
    'Aman / Benign',
    'Phishing',
    'Malware',
    'Spam',
    'Lainnya',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitReport() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_selectedCategory == null) {
      showScanMessage(context, 'Pilih kategori yang benar terlebih dahulu.');
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
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item ?? demoScanResults.first;
    final badgeColor = item.isSafe ? AppColors.success : AppColors.danger;
    final badgeBackground =
        item.isSafe ? AppColors.paleSuccess : AppColors.paleDanger;

    return ScanSubpage(
      title: 'Lapor hasil prediksi',
      onNavigate: widget.onNavigate,
      selectedIndex: 2,
      children: [
        const Text(
          'Bantu perbaiki kualitas klasifikasi dengan memberi koreksi pada hasil ini.',
          style: bodyStyle,
        ),
        const SizedBox(height: 20),

        // URL Info Card
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
                item.url,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Section: Jenis Laporan
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
                isSelected: _selectedType == ReportType.falsePositive,
                onTap: () =>
                    setState(() => _selectedType = ReportType.falsePositive),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReportTypeCard(
                title: 'False Negative',
                subtitle: 'Ditandai aman, padahal berbahaya.',
                icon: Icons.warning_amber_rounded,
                isSelected: _selectedType == ReportType.falseNegative,
                onTap: () =>
                    setState(() => _selectedType = ReportType.falseNegative),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Section: Kategori yang benar
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
          initialValue: _selectedCategory,
          hint: const Text(
            'Pilih kategori',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.ink),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.blue),
            ),
          ),
          items: _categories
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c,
                      style: const TextStyle(
                          color: AppColors.ink, fontSize: 14),
                    ),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pilih kategori menurut penilaian Anda.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),

        const SizedBox(height: 24),

        // Section: Catatan laporan
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
          controller: _notesController,
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

        // Submit Button
        ScanButton(
          label: 'Kirim laporan',
          icon: Icons.arrow_forward_rounded,
          onPressed: _submitReport,
        ),
      ],
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
