import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';

class AuthField {
  const AuthField({
    required this.label,
    required this.hint,
    this.obscure = false,
    this.controller,
    this.keyboardType,
  });
  final String label, hint;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
}

class AuthForm extends StatelessWidget {
  const AuthForm({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.actionLabel,
    required this.footerPrompt,
    required this.footerAction,
    required this.onFooterTap,
    required this.onSubmit,
    this.errorMessage,
    this.isSubmitting = false,
    this.onGoogleSignIn,
    this.googleCaption,
  });
  final String title, subtitle, actionLabel, footerPrompt, footerAction;
  final List<AuthField> fields;
  final VoidCallback onFooterTap, onSubmit;
  final String? errorMessage;
  final bool isSubmitting;

  /// Enables the Google button. Null keeps it disabled.
  final VoidCallback? onGoogleSignIn;

  /// Explains why Google is unavailable; hidden once the button works.
  final String? googleCaption;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LinkGuardBrand(size: 23),
                  const SizedBox(height: 36),
                  Text(title, style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: context.colors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isSubmitting ? null : onGoogleSignIn,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        children: [
                          Image.asset(
                            'assets/images/google-g.png',
                            width: 20,
                            height: 20,
                            excludeFromSemantics: true,
                          ),
                          Text(
                            actionLabel == 'Daftar'
                                ? 'Daftar dengan Google'
                                : 'Lanjutkan dengan Google',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (googleCaption != null)
                    Text(
                      googleCaption!,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.muted,
                      ),
                    ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) => Row(
                      children: [
                        Expanded(child: Divider(color: context.colors.line)),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * .7,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'atau dengan email',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.colors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: context.colors.line)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final field in fields) ...[
                    _LabeledField(
                      key: ValueKey(field.label),
                      field: field,
                      onSubmitted: onSubmit,
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (errorMessage != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.paleDanger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: context.colors.danger,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  ScanButton(
                    label: isSubmitting ? 'Memproses…' : actionLabel,
                    onPressed: isSubmitting ? null : onSubmit,
                    icon: Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 3,
                      children: [
                        Text(
                          footerPrompt,
                          style: TextStyle(
                            color: context.colors.muted,
                            fontSize: 12,
                          ),
                        ),
                        TextButton(
                          onPressed: onFooterTap,
                          child: Text(
                            footerAction,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _LabeledField extends StatefulWidget {
  const _LabeledField({
    super.key,
    required this.field,
    required this.onSubmitted,
  });
  final AuthField field;
  final VoidCallback onSubmitted;
  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  bool _visible = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.field.label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: widget.field.controller,
        obscureText: widget.field.obscure && !_visible,
        keyboardType: widget.field.keyboardType,
        textInputAction: widget.field.obscure
            ? TextInputAction.done
            : TextInputAction.next,
        onSubmitted: widget.field.obscure ? (_) => widget.onSubmitted() : null,
        autofillHints: widget.field.obscure
            ? const [AutofillHints.password]
            : widget.field.keyboardType == TextInputType.emailAddress
            ? const [AutofillHints.email]
            : const [AutofillHints.name],
        style: TextStyle(fontSize: 15, color: context.colors.ink),
        decoration: InputDecoration(
          hintText: widget.field.hint,
          suffixIcon: widget.field.obscure
              ? IconButton(
                  tooltip: _visible
                      ? 'Sembunyikan kata sandi'
                      : 'Tampilkan kata sandi',
                  onPressed: () => setState(() => _visible = !_visible),
                  icon: Icon(
                    _visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 21,
                    color: context.colors.muted,
                  ),
                )
              : null,
        ),
      ),
    ],
  );
}
