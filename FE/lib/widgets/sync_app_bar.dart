import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// A single tappable icon — app-bar actions, transport, nav.
class SLIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? label;
  final Color? color;
  final double box;

  const SLIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.label,
    this.color,
    this.box = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: SizedBox(
        width: box,
        height: box,
        child: Icon(icon, size: (box * 0.62).roundToDouble(), color: color ?? SL.textPrimary),
      ),
    );
  }
}

/// The 56px top app bar: a leading slot, a centered title, and a single
/// trailing action. `transparent`/`dark` variants drop the hairline and recolor
/// the title for the camera/video stages.
class SyncAppBar extends StatelessWidget {
  final Widget? left;
  final Widget title;
  final Widget? right;
  final bool dark;
  final bool transparent;

  const SyncAppBar({
    super.key,
    this.left,
    required this.title,
    this.right,
    this.dark = false,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    final col = dark ? SL.textOnDark : SL.textPrimary;
    final showLine = !transparent && !dark;
    return Container(
      height: SL.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: transparent || dark ? Colors.transparent : SL.paper,
        border: showLine
            ? const Border(bottom: BorderSide(color: SL.borderSoft))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Align(alignment: Alignment.centerLeft, child: left),
          ),
          Expanded(
            child: Center(
              child: DefaultTextStyle(
                style: SLType.sans(
                  size: SLType.xl,
                  weight: FontWeight.w700,
                  color: col,
                  letterSpacing: -0.2,
                ),
                child: title,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Align(alignment: Alignment.centerRight, child: right),
          ),
        ],
      ),
    );
  }
}
