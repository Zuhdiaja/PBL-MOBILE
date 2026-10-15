import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const pageTitleStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.w600,
  letterSpacing: -.8,
  height: 1.25,
);
const sectionTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  letterSpacing: -.4,
  height: 1.4,
);
const bodyStyle = TextStyle(fontSize: 14, height: 1.6);

class ScanPage extends StatelessWidget {
  const ScanPage({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: constraints.maxWidth.clamp(0, 640),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            constraints.maxWidth < 360 ? 18 : 22,
            24,
            constraints.maxWidth < 360 ? 18 : 22,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class LinkGuardBrand extends StatelessWidget {
  const LinkGuardBrand({super.key, this.size = 22});
  final double size;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: size + 2,
          color: context.colors.blue,
        ),
        const SizedBox(width: 9),
        Text(
          'LinkGuard',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
            color: context.colors.ink,
          ),
        ),
      ],
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
      child: ScanPage(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Kembali',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
              ),
              const SizedBox(width: 4),
              Expanded(child: Text(title, style: sectionTitleStyle)),
            ],
          ),
          const SizedBox(height: 28),
          ...children,
        ],
      ),
    ),
  );
}

class PreviewBadge extends StatelessWidget {
  const PreviewBadge(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(color: context.colors.muted, fontSize: 11, height: 1.5),
  );
}

class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Icon(
          Icons.info_outline_rounded,
          color: context.colors.muted,
          size: 16,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: context.colors.muted,
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
      iconAlignment: IconAlignment.end,
      icon: Icon(icon, size: 19),
      label: Text(label, textAlign: TextAlign.center),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    style: TextStyle(color: context.colors.ink, fontSize: 15),
    decoration: InputDecoration(
      hintText: 'https://contoh.com',
      labelText: label,
      prefixIcon: Icon(
        Icons.link_rounded,
        color: context.colors.muted,
        size: 22,
      ),
      suffixIcon: TextButton(onPressed: onPaste, child: const Text('Tempel')),
    ),
  );
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge(this.category, {super.key});
  final String category;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: context.colors.statusBackground(category),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      categoryLabel(category),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: context.colors.status(category),
      ),
    ),
  );
}

String categoryLabel(String category) => switch (category) {
  'Benign' => 'Aman',
  'Defacement' => 'Perusakan situs',
  'Exploit' => 'Eksploitasi',
  _ => category,
};
IconData categoryIcon(String category) => switch (category) {
  'Aman' || 'Benign' => Icons.verified_user_outlined,
  'Malware' => Icons.bug_report_outlined,
  'Spam' => Icons.mail_outline_rounded,
  'Defacement' => Icons.web_asset_off_rounded,
  'Exploit' => Icons.security_rounded,
  _ => Icons.warning_amber_rounded,
};
String displayHost(String url) =>
    Uri.tryParse(url)?.host.isNotEmpty == true ? Uri.parse(url).host : url;

class MethodRow extends StatelessWidget {
  const MethodRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 12,
        leading: Icon(icon, color: context.colors.blue, size: 24),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: context.colors.muted,
            height: 1.7,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: context.colors.muted,
        ),
        onTap: onTap,
      ),
      Divider(height: 1, color: context.colors.line),
    ],
  );
}

void showScanMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

String displayTime(String time) =>
    RegExp(r'\d{1,2}:\d{2}').firstMatch(time)?.group(0) ?? time;
