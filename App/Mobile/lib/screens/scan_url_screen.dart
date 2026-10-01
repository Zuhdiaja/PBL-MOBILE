import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/scan_components.dart';

class ScanUrlScreen extends StatefulWidget {
  const ScanUrlScreen({super.key, required this.onQr, required this.onShare});

  final VoidCallback onQr;
  final VoidCallback onShare;

  @override
  State<ScanUrlScreen> createState() => ScanUrlScreenState();
}

class ScanUrlScreenState extends State<ScanUrlScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = [TextEditingController()];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> pasteIntoFirstField() => _paste(_controllers.first);

  Future<void> _paste(TextEditingController controller) async {
    final text = await readClipboardUrl(context);
    if (!mounted || text == null || !_controllers.contains(controller)) return;
    controller.text = text;
  }

  void _addUrl() {
    if (_controllers.length >= 5) return;
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeUrl(int index) {
    final controller = _controllers[index];
    setState(() => _controllers.removeAt(index));
    // Let the field unmount before disposing its controller.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }

  void _scan() {
    if (!_formKey.currentState!.validate()) return;
    showScanPreview(context, _controllers.map((c) => c.text.trim()).toList());
  }

  @override
  Widget build(BuildContext context) => ScanPage(
    children: [
      const Text('Scan URL', style: pageTitleStyle),
      const SizedBox(height: 6),
      const Text('Periksa satu atau beberapa tautan', style: bodyStyle),
      const SizedBox(height: 22),
      const PreviewBadge('MODE PRATINJAU'),
      const SizedBox(height: 14),
      const Text(
        'Masukkan tautan yang ingin diperiksa. Maksimal 5 URL dalam satu scan.',
        style: bodyStyle,
      ),
      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(18),
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
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_controllers.length}/5 URL',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hapus URL ${i + 1}',
                        onPressed: () => _removeUrl(i),
                        icon: const Icon(Icons.close_rounded, size: 19),
                        color: AppColors.muted,
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
                child: OutlinedButton.icon(
                  onPressed: _controllers.length < 5 ? _addUrl : null,
                  icon: const Icon(Icons.add_rounded, size: 21),
                  label: Text(
                    _controllers.length < 5 ? 'Tambah URL' : 'Maksimal 5 URL',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    foregroundColor: AppColors.blue,
                    backgroundColor: const Color(0xFFF8FAFF),
                    side: const BorderSide(color: Color(0xFFBBCBEC)),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ScanButton(label: 'Periksa URL', onPressed: _scan),
            ],
          ),
        ),
      ),
      const SizedBox(height: 28),
      const Text('Metode lainnya', style: sectionTitleStyle),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final methods = [
            _ScanMethod(
              icon: Icons.qr_code_rounded,
              title: 'Scan QR Code',
              subtitle: 'Tanpa buka tautan',
              onTap: widget.onQr,
            ),
            _ScanMethod(
              icon: Icons.share_outlined,
              title: 'Dari aplikasi lain',
              subtitle: 'Bagikan ke LinkGuard',
              onTap: widget.onShare,
            ),
          ];
          if (constraints.maxWidth < 330 ||
              MediaQuery.textScalerOf(context).scale(14) > 17) {
            return Column(
              children: [methods[0], const SizedBox(height: 10), methods[1]],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: methods[0]),
                const SizedBox(width: 10),
                Expanded(child: methods[1]),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 20),
      const InfoNote(
        'Tampilan pratinjau. Hasil pemeriksaan keamanan belum tersedia.',
      ),
    ],
  );
}

class _ScanMethod extends StatelessWidget {
  const _ScanMethod({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.paleBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.blue, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
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
          ],
        ),
      ),
    ),
  );
}
