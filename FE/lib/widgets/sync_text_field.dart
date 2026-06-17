import 'package:flutter/material.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// A labelled form input matching the SyncLog field style (the same 46px
/// bordered shell used in the create-team sheet), with the extras auth screens
/// need: a leading icon, a password obscure toggle, and an inline error row
/// that turns the border red. Kept generic so login and sign-up share one
/// field implementation.
class SyncTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? leading;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SyncTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.leading,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<SyncTextField> createState() => _SyncTextFieldState();
}

class _SyncTextFieldState extends State<SyncTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: SL.space2),
          child: Text(widget.label,
              style: SLType.sans(
                  size: SLType.sm, weight: FontWeight.w500, color: SL.textSecondary)),
        ),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: SL.surfaceCard,
            border: Border.all(color: hasError ? SL.rec : SL.border),
            borderRadius: BorderRadius.circular(SL.radiusSm),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                Icon(widget.leading, size: 18, color: SL.textSecondary),
                const SizedBox(width: SL.space2),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  obscureText: _hidden,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: SLType.sans(size: SLType.md, color: SL.textPrimary),
                  cursorColor: SL.rec,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle:
                        SLType.sans(size: SLType.md, color: SL.textPlaceholder),
                  ),
                ),
              ),
              if (widget.obscure)
                Pressable(
                  onTap: () => setState(() => _hidden = !_hidden),
                  semanticLabel: _hidden ? '비밀번호 보기' : '비밀번호 숨기기',
                  child: Padding(
                    padding: const EdgeInsets.only(left: SL.space2),
                    child: Icon(_hidden ? SLIcons.eye : SLIcons.eyeOff,
                        size: 18, color: SL.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(widget.errorText!,
                style: SLType.sans(size: SLType.xs, color: SL.rec)),
          ),
      ],
    );
  }
}
