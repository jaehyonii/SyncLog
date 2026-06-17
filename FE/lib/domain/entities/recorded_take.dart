import 'package:flutter/foundation.dart';

/// A freshly captured video take handed from the recording screen to the
/// micro-sync editor, then to the repository for upload.
@immutable
class RecordedTake {
  /// Local file path of the captured video. Null when the recording service is
  /// a fake (no camera available) — the rest of the flow still works.
  final String? filePath;

  /// Recorded duration.
  final Duration duration;

  /// BPM the take was recorded against (fixed by the team manager).
  final int bpm;

  const RecordedTake({
    required this.filePath,
    required this.duration,
    required this.bpm,
  });

  bool get isReal => filePath != null;
}
