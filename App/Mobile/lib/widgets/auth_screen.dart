import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AuthField {
  const AuthField({
    required this.label,
    required this.hint,
    this.obscure = false,
    this.controller,
  });

  final String label;
  final String hint;
  final bool obscure;
  final TextEditingController? controller;
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.actionLabel,
    required this.footerPrompt,
    required this.footerAction,
    required this.onFooterTap,
    required this.onSubmit,
  });

  final String title;
  final String subtitle;
  final List<AuthField> fields;
  final String actionLabel;
  final String footerPrompt;
  final String footerAction;
  final VoidCallback onFooterTap;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Brand(),
              const SizedBox(height: 22),
              const _ShieldArtwork(),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 22),
              for (final field in fields) ...[
                _LabeledField(field: field),
                const SizedBox(height: 11),
              ],
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: onSubmit,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                  label: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    elevation: 5,
                    shadowColor: AppColors.blue.withValues(alpha: 0.25),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      footerPrompt,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    TextButton(
                      onPressed: onFooterTap,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        footerAction,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Center(
                child: Text(
                  'Login dan password hanya simulasi. Data contoh tersimpan di browser ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: Color(0xFFA5B0C1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'linkguard',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '.',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldArtwork extends StatelessWidget {
  const _ShieldArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final diameter in [150.0, 110.0, 70.0])
            Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC9DBFB)),
              ),
            ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.field});

  final AuthField field;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 43,
          child: TextField(
            controller: field.controller,
            obscureText: field.obscure,
            decoration: InputDecoration(
              hintText: field.hint,
              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppColors.blue),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
