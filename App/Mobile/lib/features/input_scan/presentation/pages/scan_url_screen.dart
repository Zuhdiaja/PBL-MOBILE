import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/url_input.dart';
import '../controllers/scan_url_controller.dart';
import '../widgets/scan_preview_sheet.dart';

class ScanUrlScreen extends StatefulWidget {
  const ScanUrlScreen({
    super.key,
    required this.controller,
    required this.onQr,
    required this.onShare,
    required this.onViewResults,
  });

  final ScanUrlController controller;
  final VoidCallback onViewResults;
  final VoidCallback onQr;
  final VoidCallback onShare;

  @override
  State<ScanUrlScreen> createState() => _ScanUrlScreenState();
}

class _ScanUrlScreenState extends State<ScanUrlScreen> {
  final _formKey = GlobalKey<FormState>();
  List<TextEditingController> get _controllers => widget.controller.fields;

  Future<void> _paste(TextEditingController field) async {
    final message = await widget.controller.paste(field);
    if (mounted && message != null) showScanMessage(context, message);
  }

  void _scan() {
    if (!_formKey.currentState!.validate()) return;
    final result = widget.controller.preparePreview();
    if (result.failure != null) {
      showScanMessage(context, result.failure!.message);
      return;
    }
    showScanPreview(
      context,
      result.preview!,
      preparePreview: widget.controller.preparePreview,
      onViewResults: widget.onViewResults,
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => ScanPage(
      children: [
        const Text('Pindai URL', style: pageTitleStyle),
        const SizedBox(height: 6),
        Text(
          'Periksa satu atau beberapa tautan.',
          style: bodyStyle.copyWith(color: context.colors.muted),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'URL yang ingin diperiksa',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_controllers.length}/${widget.controller.maxUrls} URL',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < _controllers.length; i++) ...[
                  if (_controllers.length > 1)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'URL ${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.muted,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hapus URL ${i + 1}',
                          onPressed: () => widget.controller.removeUrl(i),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ],
                    ),
                  UrlField(
                    key: ObjectKey(_controllers[i]),
                    controller: _controllers[i],
                    label: _controllers.length > 1 ? 'URL ${i + 1}' : null,
                    validator: validateUrl,
                    onPaste: () => _paste(_controllers[i]),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: widget.controller.canAddUrl
                        ? widget.controller.addUrl
                        : null,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      widget.controller.canAddUrl
                          ? 'Tambah URL'
                          : 'Maksimal ${widget.controller.maxUrls} URL',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ScanButton(label: 'Periksa URL', onPressed: _scan),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text('Metode lainnya', style: sectionTitleStyle),
        const SizedBox(height: 10),
        MethodRow(
          icon: Icons.qr_code_rounded,
          title: 'Pindai kode QR',
          subtitle: 'Tanpa membuka tautan',
          onTap: widget.onQr,
        ),
        MethodRow(
          icon: Icons.share_outlined,
          title: 'Dari aplikasi lain',
          subtitle: 'Periksa tautan yang dibagikan',
          onTap: widget.onShare,
        ),
        const SizedBox(height: 16),
        const InfoNote('Maksimal 5 URL per pemindaian.'),
        const SizedBox(height: 10),
        Text(
          'Mode pratinjau. Hasil pemeriksaan keamanan belum tersedia.',
          style: TextStyle(color: context.colors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}
