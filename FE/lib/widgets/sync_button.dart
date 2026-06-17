import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

enum SLButtonVariant { primary, record, soft, outline, ghost }

enum SLButtonSize { sm, md, lg }

/// The primary call to action. Ink-black `primary` for the dominant confirm on
/// a screen, `record` (red) for record/destructive actions, `soft` for
/// secondary. Icons sit left (`icon`) or right (`iconRight`).
class SyncButton extends StatelessWidget {
  final String label;
  final SLButtonVariant variant;
  final SLButtonSize size;
  final IconData? icon;
  final IconData? iconRight;
  final bool fullWidth;
  final bool pill;
  final VoidCallback? onTap;

  const SyncButton({
    super.key,
    required this.label,
    this.variant = SLButtonVariant.primary,
    this.size = SLButtonSize.md,
    this.icon,
    this.iconRight,
    this.fullWidth = false,
    this.pill = false,
    this.onTap,
  });

  ({Color bg, Color fg, Color border}) get _colors {
    switch (variant) {
      case SLButtonVariant.primary:
        return (bg: SL.ink, fg: SL.textOnInk, border: SL.ink);
      case SLButtonVariant.record:
        return (bg: SL.rec, fg: SL.textOnRec, border: SL.rec);
      case SLButtonVariant.soft:
        return (bg: SL.surfaceMuted, fg: SL.textPrimary, border: SL.surfaceMuted);
      case SLButtonVariant.outline:
        return (bg: Colors.transparent, fg: SL.textPrimary, border: SL.border);
      case SLButtonVariant.ghost:
        return (bg: Colors.transparent, fg: SL.textPrimary, border: Colors.transparent);
    }
  }

  ({double height, double padH, double fontSize, double gap}) get _metrics {
    switch (size) {
      case SLButtonSize.sm:
        return (height: 36, padH: 14, fontSize: SLType.sm, gap: 6);
      case SLButtonSize.md:
        return (height: 44, padH: 18, fontSize: SLType.base, gap: 8);
      case SLButtonSize.lg:
        return (height: 50, padH: 22, fontSize: SLType.md, gap: 8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    final m = _metrics;
    final glyph = (m.height * 0.42).roundToDouble();

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: glyph, color: c.fg),
          SizedBox(width: m.gap),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SLType.sans(size: m.fontSize, weight: FontWeight.w700, color: c.fg),
          ),
        ),
        if (iconRight != null) ...[
          SizedBox(width: m.gap),
          Icon(iconRight, size: glyph, color: c.fg),
        ],
      ],
    );

    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: m.height,
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: m.padH),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.bg,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(pill ? SL.radiusPill : SL.radiusSm),
        ),
        child: content,
      ),
    );
  }
}
