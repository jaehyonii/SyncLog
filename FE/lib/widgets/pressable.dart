import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Press feedback for a touch product: a `scale(0.97)` + `opacity 0.7` dip on
/// tap. No bounce, no overshoot — a short linear fade with a tiny press dip.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1.0,
          duration: SL.durationFast,
          curve: SL.easeStandard,
          child: AnimatedOpacity(
            opacity: enabled && _down ? 0.7 : 1.0,
            duration: SL.durationFast,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
