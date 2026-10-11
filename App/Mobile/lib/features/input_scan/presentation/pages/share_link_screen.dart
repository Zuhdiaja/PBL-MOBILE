import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/url_input.dart';
import '../controllers/share_link_controller.dart';
import '../widgets/scan_preview_sheet.dart';

class ShareLinkScreen extends StatefulWidget {
  const ShareLinkScreen({
    super.key,
    required this.controller,
    required this.onNavigate,
    required this.onViewResults,
  });

  /// The route owns and disposes this controller.
  final ShareLinkController controller;
  final VoidCallback onViewResults;
  final ValueChanged<int> onNavigate;

  @override
  State<ShareLinkScreen> createState() => _ShareLinkScreenState();
}

class _ShareLinkScreenState extends State<ShareLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  ShareLinkController get _state => widget.controller;

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  void _useExample() {
    _formKey.currentState?.reset();
    _state.useExample();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _paste() async {
    final result = await _state.paste();
    if (!mounted || result == null) return;
    if (result.failure != null) {
      showScanMessage(context, result.failure!.message);
      return;
    }
    _formKey.currentState?.reset();
    _state.field.text = result.text!;
  }

  void _scan() {
    if (!_formKey.currentState!.validate()) return;
    final result = _state.preparePreview();
    if (result.failure != null) {
      showScanMessage(context, result.failure!.message);
      return;
    }
    showScanPreview(
      context,
      result.preview!,
      onViewResults: widget.onViewResults,
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _state,
    builder: (context, _) {
      final url = _state.url;
      final domain = _state.host;

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
                            _state.usingExample
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
              controller: _state.field,
              onPaste: _paste,
              validator: validateUrl,
              onChanged: (_) => _state.markEdited(),
            ),
          ),
          const SizedBox(height: 16),
          ScanButton(
            label: 'Periksa URL',
            onPressed: url.isEmpty ? null : _scan,
          ),
          const SizedBox(height: 18),
          const InfoNote(
            'Ini pratinjau alur berbagi. Penerimaan tautan dari aplikasi lain belum terhubung.',
          ),
        ],
      );
    },
  );
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
