import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// A static audio waveform — 56 deterministic bars; the played portion is
/// tinted (record-red by default). Used in the micro-sync editor.
class Waveform extends StatelessWidget {
  final double progress;
  final Color tint;
  final double height;
  final bool dark;

  const Waveform({
    super.key,
    this.progress = 0.4,
    this.tint = SL.rec,
    this.height = 64,
    this.dark = false,
  });

  /// Deterministic pseudo-random bar heights — the exact LCG the kit uses, so
  /// the waveform reads identically.
  static final List<double> _bars = () {
    final arr = <double>[];
    var s = 7;
    for (var i = 0; i < 56; i++) {
      s = (s * 9301 + 49297) % 233280;
      arr.add(0.22 + (s / 233280) * 0.78);
    }
    return arr;
  }();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_bars.length, (i) {
          final played = i / _bars.length <= progress;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FractionallySizedBox(
                heightFactor: _bars[i],
                child: Container(
                  decoration: BoxDecoration(
                    color: played ? tint : (dark ? SL.dark3 : SL.waveformTrack),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
