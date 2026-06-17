import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// The metronome's visual beat indicator — four dots, the active one steps on
/// the quarter-note with a sharp attack and a red glow. Idle (`active < 0`)
/// shows all dots dark.
class BeatDots extends StatelessWidget {
  final int count;
  final int active;
  final double size;

  const BeatDots({
    super.key,
    this.count = 4,
    this.active = -1,
    this.size = 9,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final on = i == active;
        final dot = on ? size + 1 : size;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: AnimatedScale(
            scale: on ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 90),
            curve: SL.easeBeat,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: on ? SL.rec : SL.dark3,
                shape: BoxShape.circle,
                boxShadow: on
                    ? [
                        BoxShadow(
                          color: SL.rec.withValues(alpha: 0.7),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
