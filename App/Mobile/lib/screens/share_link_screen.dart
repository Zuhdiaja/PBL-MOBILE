import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/scan_components.dart';

class ShareLinkScreen extends StatefulWidget {
  const ShareLinkScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<ShareLinkScreen> createState() => _ShareLinkScreenState();
}

class _ShareLinkScreenState extends State<ShareLinkScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _usingExample = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _useExample() {
    _formKey.currentState?.reset();
    _controller.text = 'https://contoh.com/artikel';
    setState(() => _usingExample = true);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _paste() async {
    final text = await readClipboardUrl(context);
    if (!mounted || text == null) return;
    _formKey.currentState?.reset();
    _controller.text = text;
    setState(() => _usingExample = false);
  }

  void _scan() {
    if (!_formKey.currentState!.validate()) return;
    showScanPreview(context, [_controller.text.trim()]);
  }

  @override
  Widget build(BuildContext context) {
    final url = _controller.text.trim();
    final valid = url.isNotEmpty && validateUrl(url) == null;
    final domain = valid ? Uri.parse(url).host : null;

    return ScanSubpage(
      title: 'Bagikan ke LinkGuard',
      onNavigate: widget.onNavigate,
      children: [
        const Text(
          'Terima tautan dari aplikasi lain, lalu periksa sebelum membukanya.',
          style: bodyStyle,
        ),
        const SizedBox(height: 24),
        const Text(
          'Cara membagikan tautan',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        const _ShareStep(
          number: '1',
          title: 'Pilih tautan',
          description: 'Dari WhatsApp, Telegram, browser, atau email.',
        ),
        const _ShareStep(
          number: '2',
          title: 'Bagikan ke LinkGuard',
          description: 'Ketuk Bagikan, lalu pilih aplikasi LinkGuard.',
        ),
        const _ShareStep(
          number: '3',
          title: 'Tinjau dan periksa',
          description: 'Pastikan URL sesuai, lalu ketuk Periksa URL.',
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.paleBlue,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      size: 22,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain ?? 'Belum ada tautan',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _usingExample
                              ? 'Contoh tautan dari aplikasi lain'
                              : url.isNotEmpty
                              ? 'Tautan yang kamu masukkan'
                              : 'Coba pratinjau tautan yang diterima.',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _useExample,
                icon: const Icon(Icons.link_rounded, size: 19),
                label: const Text('Gunakan tautan contoh'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'URL yang dibagikan',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Form(
          key: _formKey,
          child: UrlField(
            controller: _controller,
            onPaste: _paste,
            validator: validateUrl,
            onChanged: (_) => setState(() => _usingExample = false),
          ),
        ),
        const SizedBox(height: 16),
        ScanButton(label: 'Periksa URL', onPressed: url.isEmpty ? null : _scan),
        const SizedBox(height: 18),
        const InfoNote(
          'Ini pratinjau alur berbagi. Penerimaan tautan dari aplikasi lain belum terhubung.',
        ),
      ],
    );
  }
}

class _ShareStep extends StatelessWidget {
  const _ShareStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.paleBlue,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
