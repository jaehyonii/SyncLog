import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// A track to stack on the shared timeline: a playable source and the sync
/// offset (ms) its owner tuned against the metronome downbeat.
@immutable
class PlayableTrack {
  final String id;
  final String? url; // remote source (file playback is an extension point)
  final int offsetMs;
  const PlayableTrack({required this.id, required this.url, required this.offsetMs});
}

@immutable
class PlaybackState {
  final bool isPlaying;
  final double fraction; // 0..1
  final Duration total;
  const PlaybackState({
    required this.isPlaying,
    required this.fraction,
    required this.total,
  });

  static const idle = PlaybackState(isPlaying: false, fraction: 0, total: Duration.zero);

  PlaybackState copyWith({bool? isPlaying, double? fraction, Duration? total}) =>
      PlaybackState(
        isPlaying: isPlaying ?? this.isPlaying,
        fraction: fraction ?? this.fraction,
        total: total ?? this.total,
      );
}

/// Plays several member takes in sync, delaying each by its sync offset so the
/// stack lines up on the beat.
abstract class MultiTrackPlayer {
  ValueListenable<PlaybackState> get state;
  Future<void> load(List<PlayableTrack> tracks);
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();

  /// Real network-backed playback when every track has a URL and the platform
  /// supports it; otherwise a simulated player that advances a progress bar
  /// (used for the design's dark-placeholder takes).
  factory MultiTrackPlayer.forTracks(List<PlayableTrack> tracks, {Duration fallbackTotal = const Duration(minutes: 3, seconds: 45)}) {
    final allRemote = tracks.isNotEmpty && tracks.every((t) => t.url != null && t.url!.startsWith('http'));
    if (allRemote && !kIsWeb) {
      return VideoMultiTrackPlayer();
    }
    return SimulatedMultiTrackPlayer(total: fallbackTotal);
  }
}

/// Network-backed synced playback via `video_player`.
class VideoMultiTrackPlayer implements MultiTrackPlayer {
  final _state = ValueNotifier<PlaybackState>(PlaybackState.idle);
  final List<VideoPlayerController> _controllers = [];
  List<PlayableTrack> _tracks = const [];
  VideoPlayerController? _master;
  Timer? _ticker;

  @override
  ValueListenable<PlaybackState> get state => _state;

  @override
  Future<void> load(List<PlayableTrack> tracks) async {
    await _disposeControllers();
    _tracks = tracks;
    for (final t in tracks) {
      final c = VideoPlayerController.networkUrl(Uri.parse(t.url!));
      await c.initialize();
      _controllers.add(c);
    }
    // Master = longest take, so progress reflects the full stack.
    if (_controllers.isNotEmpty) {
      _master = _controllers.reduce(
        (a, b) => a.value.duration >= b.value.duration ? a : b,
      );
      _state.value = _state.value.copyWith(total: _master!.value.duration);
    }
  }

  @override
  Future<void> play() async {
    if (_controllers.isEmpty) return;
    final minOffset = _tracks.map((t) => t.offsetMs).reduce((a, b) => a < b ? a : b);
    for (var i = 0; i < _controllers.length; i++) {
      final delay = _tracks[i].offsetMs - minOffset;
      Future.delayed(Duration(milliseconds: delay), () {
        if (_state.value.isPlaying) _controllers[i].play();
      });
    }
    _state.value = _state.value.copyWith(isPlaying: true);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final m = _master;
      if (m == null) return;
      final total = m.value.duration.inMilliseconds;
      final pos = m.value.position.inMilliseconds;
      _state.value = _state.value.copyWith(
        fraction: total == 0 ? 0 : (pos / total).clamp(0.0, 1.0),
      );
    });
  }

  @override
  Future<void> pause() async {
    for (final c in _controllers) {
      await c.pause();
    }
    _ticker?.cancel();
    _state.value = _state.value.copyWith(isPlaying: false);
  }

  Future<void> _disposeControllers() async {
    _ticker?.cancel();
    for (final c in _controllers) {
      await c.dispose();
    }
    _controllers.clear();
    _master = null;
  }

  @override
  Future<void> dispose() async {
    await _disposeControllers();
    _state.dispose();
  }
}

/// Simulated playback: advances a progress fraction on a timer. Used for the
/// honest dark-placeholder takes (no real media), mirroring the design kit.
class SimulatedMultiTrackPlayer implements MultiTrackPlayer {
  final Duration total;
  final _state = ValueNotifier<PlaybackState>(PlaybackState.idle);
  Timer? _ticker;

  SimulatedMultiTrackPlayer({required this.total});

  @override
  ValueListenable<PlaybackState> get state => _state;

  @override
  Future<void> load(List<PlayableTrack> tracks) async {
    _state.value = PlaybackState(isPlaying: false, fraction: 0.28, total: total);
  }

  @override
  Future<void> play() async {
    _state.value = _state.value.copyWith(isPlaying: true);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 180), (_) {
      final next = _state.value.fraction + 0.01;
      _state.value = _state.value.copyWith(fraction: next >= 1 ? 0 : next);
    });
  }

  @override
  Future<void> pause() async {
    _ticker?.cancel();
    _state.value = _state.value.copyWith(isPlaying: false);
  }

  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    _state.dispose();
  }
}
