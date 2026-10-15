import '../../../../widgets/loading_states.dart';

import 'dart:async';

import '../../../../widgets/load_view.dart';
import '../controllers/scan_detail_controller.dart';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/scan_result.dart';

class ScanDetailScreen extends StatefulWidget {
  const ScanDetailScreen({
    super.key,
    required this.result,
    required this.onReport,
    this.onNavigate,
    this.loadResult,
  });
  final ScanResult result;
  final ValueChanged<ScanResult> onReport;
  final ValueChanged<int>? onNavigate;
  final FutureOr<ScanResult> Function()? loadResult;
  @override
  State<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  late final controller = ScanDetailController(
    widget.loadResult ?? () => widget.result,
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LoadView(
    controller: controller,
    kind: 'detail',
    subpage: true,
    loadingBuilder: (context) =>
        LoadingScreen(kind: 'detail', url: widget.result.url),
    builder: (context) {
      final result = controller.result!;
      final color = context.colors.status(result.category);
      return ScanSubpage(
        title: 'Detail hasil',
        onNavigate: widget.onNavigate,
        selectedIndex: 2,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: context.colors.statusBackground(result.category),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  categoryIcon(result.category),
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  categoryLabel(result.category),
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SelectableText(
            result.url,
            style: TextStyle(
              color: context.colors.muted,
              fontSize: 13,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: context.colors.line),
          const SizedBox(height: 18),
          const Text(
            'Saran keamanan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            result.resolvedRecommendation,
            style: TextStyle(
              fontSize: 13,
              color: context.colors.muted,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tingkat risiko',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.riskLevel,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keyakinan model',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${result.confidence}%',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Arti keyakinan model',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Persentase ini menunjukkan keyakinan model terhadap kategori hasil. Angka ini bukan persentase keamanan atau jaminan bahwa tautan aman.',
            style: TextStyle(
              color: context.colors.muted,
              fontSize: 12,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Rincian pemeriksaan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (final indicator in result.resolvedIndicators)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    result.isSafe
                        ? Icons.check_rounded
                        : Icons.warning_amber_rounded,
                    size: 17,
                    color: color,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      indicator,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.muted,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Divider(color: context.colors.line),
          const SizedBox(height: 16),
          _MetaRow(label: 'Waktu pemindaian', value: result.scanTime),
          const SizedBox(height: 10),
          _MetaRow(label: 'Model', value: result.modelName),
          const SizedBox(height: 10),
          _MetaRow(label: 'Metode', value: result.method),
          const SizedBox(height: 22),
          ScanButton(
            label: 'Koreksi hasil',
            icon: Icons.flag_outlined,
            onPressed: () => widget.onReport(result),
          ),
          const SizedBox(height: 18),
          const InfoNote('Hasil simulasi dari data contoh.'),
        ],
      );
    },
  );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: context.colors.muted),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        flex: 2,
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}
