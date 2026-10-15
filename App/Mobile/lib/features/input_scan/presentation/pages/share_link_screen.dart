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
      preparePreview: _state.preparePreview,
      onViewResults: widget.onViewResults,
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _state,
    builder: (context, _) => ScanSubpage(
      title: 'Bagikan ke LinkGuard',
      onNavigate: widget.onNavigate,
      children: [
        Text(
          'Saat menerima tautan dari WhatsApp, Telegram, atau email, pilih LinkGuard pada menu Bagikan.',
          style: TextStyle(
            fontSize: 13,
            color: context.colors.muted,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.share_outlined, color: context.colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tautan dari aplikasi lain',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tempel tautan yang ingin diperiksa.',
                    style: TextStyle(fontSize: 12, color: context.colors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Divider(color: context.colors.line),
        const SizedBox(height: 18),
        const Text(
          'URL yang dibagikan',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
          onPressed: _state.url.isEmpty ? null : _scan,
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _useExample,
          icon: const Icon(Icons.link_rounded, size: 18),
          label: const Text(
            'Gunakan tautan contoh',
            style: TextStyle(fontSize: 12),
          ),
        ),
        if (_state.url.isEmpty)
          Text(
            'Belum ada tautan',
            style: TextStyle(color: context.colors.muted, fontSize: 11),
          ),
        const SizedBox(height: 20),
        const InfoNote(
          'Ini pratinjau alur berbagi. Penerimaan tautan dari aplikasi lain belum terhubung.',
        ),
      ],
    ),
  );
}
