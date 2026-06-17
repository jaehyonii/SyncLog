import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum SLTagTone { rec, neutral, solid, danger, onDark }

/// A small rounded label for counts, states and version tags. `onDark` is the
/// black scrim pill used on top of video/camera frames.
class SyncTag extends StatelessWidget {
  final String label;
  final SLTagTone tone;
  final Color? colorOverride;
  final Color? bgOverride;

  const SyncTag(
    this.label, {
    super.key,
    this.tone = SLTagTone.neutral,
    this.colorOverride,
    this.bgOverride,
  });

  ({Color bg, Color fg}) get _tone {
    switch (tone) {
      case SLTagTone.rec:
        return (bg: SL.recSoft, fg: SL.recPressed);
      case SLTagTone.neutral:
        return (bg: SL.surfaceMuted, fg: SL.textSecondary);
      case SLTagTone.solid:
        return (bg: SL.ink, fg: SL.textOnInk);
      case SLTagTone.danger:
        return (bg: SL.recSoft, fg: SL.rec);
      case SLTagTone.onDark:
        return (bg: SL.scrimLabel, fg: SL.textOnDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _tone;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgOverride ?? t.bg,
        borderRadius: BorderRadius.circular(SL.radiusPill),
      ),
      child: Text(
        label,
        style: SLType.sans(
          size: SLType.xs,
          weight: FontWeight.w700,
          color: colorOverride ?? t.fg,
          height: 1.4,
        ),
      ),
    );
  }
}
