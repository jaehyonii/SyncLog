import 'package:flutter/foundation.dart';
import '../domain/entities/team.dart';
import '../domain/entities/track.dart';
import '../services/playback_service.dart';

/// Owns multitrack playback for one team's detail screen: builds the player from
/// the team's ready tracks (applying each track's sync offset) and exposes a
/// single play/pause toggle.
class TeamDetailController extends ChangeNotifier {
  MultiTrackPlayer? _player;
  bool _loaded = false;
  final ValueNotifier<PlaybackState> _idle = ValueNotifier(PlaybackState.idle);

  ValueListenable<PlaybackState> get playback => _player?.state ?? _idle;

  /// (Re)build the player when the team's ready tracks change.
  Future<void> bind(Team team) async {
    final sources = team.tracks
        .where((t) => t.isReady)
        .map((t) => PlayableTrack(id: t.id, url: t.videoUrl, offsetMs: t.syncOffsetMs))
        .toList();
    if (sources.isEmpty) {
      _loaded = false;
      return;
    }
    await _player?.dispose();
    _player = MultiTrackPlayer.forTracks(sources);
    await _player!.load(sources);
    _loaded = true;
    notifyListeners();
  }

  bool get canPlay => _loaded;

  Future<void> toggle() async {
    final p = _player;
    if (p == null) return;
    if (p.state.value.isPlaying) {
      await p.pause();
    } else {
      await p.play();
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    _idle.dispose();
    super.dispose();
  }
}

/// Whether a team currently has anything to play.
extension TeamPlayable on Team {
  bool get hasReadyTracks => tracks.any((t) => t.status == TrackStatus.ready);
}
