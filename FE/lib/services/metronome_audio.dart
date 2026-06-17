/// The audible side of the metronome. The visual beat indicator and count-in
/// are driven by the recording controller's timers; this hook is where a real
/// click sound plugs in (e.g. an audio plugin playing a short "tick" sample).
///
/// A silent default ships so the app builds and runs with no audio asset; swap
/// in [_SilentMetronomeAudio] for a real implementation in production.
abstract class MetronomeAudio {
  /// A regular beat tick.
  void tick();

  /// The accented downbeat (beat 1) or the count-in "Start!".
  void accent();

  factory MetronomeAudio.silent() => const _SilentMetronomeAudio();
}

class _SilentMetronomeAudio implements MetronomeAudio {
  const _SilentMetronomeAudio();

  @override
  void tick() {}

  @override
  void accent() {}
}
