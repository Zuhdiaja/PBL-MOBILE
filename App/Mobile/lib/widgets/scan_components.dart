import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/scan_result_screen.dart';
import '../theme/app_colors.dart';
import 'app_bottom_navigation.dart';

const pageTitleStyle = TextStyle(
  color: AppColors.ink,
  fontSize: 26,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.8,
  height: 1.2,
);

const sectionTitleStyle = TextStyle(
  color: AppColors.ink,
  fontSize: 20,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.6,
);

const bodyStyle = TextStyle(color: AppColors.muted, fontSize: 14, height: 1.6);

class ScanPage extends StatelessWidget {
  const ScanPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        constraints.maxWidth < 360 ? 20 : 24,
        24,
        constraints.maxWidth < 360 ? 20 : 24,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

class ScanSubpage extends StatelessWidget {
  const ScanSubpage({
    super.key,
    required this.title,
    this.onNavigate,
    this.selectedIndex = 1,
    required this.children,
  });

  final String title;
  final ValueChanged<int>? onNavigate;
  final int selectedIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: ScanPage(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Kembali',
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: AppColors.softSurface,
                  foregroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: pageTitleStyle.copyWith(fontSize: 23),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    ),
    bottomNavigationBar: onNavigate != null
        ? AppBottomNavigation(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              Navigator.of(context).pop();
              onNavigate!(index);
            },
          )
        : null,
  );
}

class PreviewBadge extends StatelessWidget {
  const PreviewBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.paleBlue,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.blue,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(
          Icons.info_outline_rounded,
          color: AppColors.muted,
          size: 16,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            height: 1.6,
          ),
        ),
      ),
    ],
  );
}

class ScanButton extends StatelessWidget {
  const ScanButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.crop_free_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 21),
      label: Text(label, textAlign: TextAlign.center),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.softSurface,
        disabledForegroundColor: AppColors.muted,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
  );
}

class UrlField extends StatelessWidget {
  const UrlField({
    super.key,
    required this.controller,
    required this.onPaste,
    this.validator,
    this.onChanged,
    this.label,
  });

  final TextEditingController controller;
  final VoidCallback onPaste;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    onChanged: onChanged,
    keyboardType: TextInputType.url,
    textInputAction: TextInputAction.done,
    autocorrect: false,
    enableSuggestions: false,
    style: const TextStyle(color: AppColors.ink, fontSize: 16),
    decoration: InputDecoration(
      hintText: 'https://contoh.com',
      labelText: label,
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 16),
      errorStyle: const TextStyle(fontSize: 12, height: 1.4),
      errorMaxLines: 3,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      prefixIcon: const Icon(
        Icons.link_rounded,
        color: AppColors.muted,
        size: 22,
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.all(5),
        child: TextButton(
          onPressed: onPaste,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.softSurface,
            foregroundColor: AppColors.blue,
            minimumSize: const Size(56, 48),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Tempel'),
        ),
      ),
      enabledBorder: _border(AppColors.line),
      focusedBorder: _border(AppColors.blue),
      errorBorder: _border(AppColors.danger),
      focusedErrorBorder: _border(AppColors.danger),
    ),
  );

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: BorderSide(color: color),
  );
}

/// Local input validation only; this makes no assessment of a URL's safety.
String? validateUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Masukkan URL yang ingin diperiksa.';
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
      uri.host.isEmpty ||
      !uri.host.contains('.') ||
      RegExp(r'\s').hasMatch(text)) {
    return 'Gunakan URL lengkap, misalnya https://contoh.com.';
  }
  return null;
}

Future<String?> readClipboardUrl(BuildContext context) async {
  try {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!context.mounted) return null;
    if (text.isNotEmpty) return text;
    showScanMessage(
      context,
      'Belum ada teks untuk ditempel. Salin URL dahulu.',
    );
  } on PlatformException {
    if (context.mounted) {
      showScanMessage(
        context,
        'Teks belum bisa ditempel. Masukkan URL manual.',
      );
    }
  }
  return null;
}

void showScanMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Future<void> showScanPreview(BuildContext context, List<String> urls) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pratinjau pemeriksaan', style: sectionTitleStyle),
            const SizedBox(height: 8),
            const Text(
              'Tautan siap diperiksa. Belum ada penilaian keamanan pada pratinjau ini.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),
            for (final url in urls)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.link, size: 21, color: AppColors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        url,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            ScanButton(
              label: 'Lihat Hasil Scan',
              icon: Icons.shield_outlined,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ScanResultScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            ScanButton(
              label: 'Kembali',
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}
