import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../domain/entities/track.dart';
import '../services/take_player_stub.dart'
    if (dart.library.io) '../services/take_player_io.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'pressable.dart';
import 'sync_tag.dart';

/// One cell of the multitrack grid on the dark stage.
///
/// A `ready` track shows the member's take (instrument glyph on a near-black
/// vignette — real video is wired in [VideoCell]'s ready branch). An `open`
/// cell renders by ownership: the viewer's own unfilled part is a record CTA;
/// an invitable part shows its per-part code; a part already claimed by someone
/// else shows a quiet "대기 중".
class VideoCell extends StatelessWidget {
  final Track track;

  /// The signed-in user, used to tell "my part" from others'.
  final String? currentUserId;

  /// Tap handler when this is the viewer's own open part (start recording).
  final VoidCallback? onRecord;

  /// Tap handler for an invitable part (show its invite code).
  final VoidCallback? onInvite;

  final bool playing;

  const VideoCell({
    super.key,
    required this.track,
    this.currentUserId,
    this.onRecord,
    this.onInvite,
    this.playing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (track.isOpen) return _openCell();
    return _ReadyTile(track: track, playing: playing);
  }

  /// An empty slot, rendered by who owns it.
  Widget _openCell() {
    final mine = track.isMine(currentUserId);

    // My own part, not yet recorded → record CTA.
    if (mine) {
      return _slot(
        onTap: onRecord,
        semantic: '${track.partKo} 녹화',
        icon: SLIcons.circlePlus,
        title: '내 파트 · 녹화',
        tag: '${track.partKo} · 내 파트',
      );
    }

    // Claimed by another member, awaiting their upload.
    if (track.member != null) {
      return _slot(
        onTap: null,
        semantic: '${track.partKo} 대기 중',
        icon: SLIcons.userRound,
        title: '대기 중',
        tag: track.partKo,
        memberInitial: track.member!.initial,
      );
    }

    // Invitable part — show its own code so the leader can hand it out.
    if (track.inviteCode != null) {
      return _slot(
        onTap: onInvite,
        semantic: '${track.partKo} 초대 코드',
        icon: SLIcons.userPlus,
        title: track.inviteCode!,
        titleMono: true,
        tag: '${track.partKo} 초대',
      );
    }

    // Legacy / unassigned slot.
    return _slot(
      onTap: onInvite,
      semantic: track.partKo,
      icon: SLIcons.circlePlus,
      title: 'PENDING',
      titleMono: true,
      tag: track.partKo,
    );
  }

  Widget _slot({
    required VoidCallback? onTap,
    required String semantic,
    required IconData icon,
    required String title,
    required String tag,
    bool titleMono = false,
    String? memberInitial,
  }) {
    return Pressable(
      onTap: onTap,
      semanticLabel: semantic,
      child: Container(
        color: SL.dark1,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 28, color: SL.textOnDarkDim),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: titleMono
                        ? SLType.mono(
                            size: SLType.sm,
                            weight: FontWeight.w700,
                            color: SL.textOnDark,
                            letterSpacing: 2)
                        : SLType.sans(
                            size: SLType.xs,
                            weight: FontWeight.w600,
                            color: SL.textOnDarkDim),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: SyncTag(tag, tone: SLTagTone.onDark),
            ),
            if (memberInitial != null)
              Positioned(
                right: 10,
                bottom: 12,
                child: Text(
                  memberInitial,
                  style: SLType.sans(
                      size: 13, weight: FontWeight.w700, color: SL.textOnDark),
                ),
              ),
          ],
        ),
      ),
    );
  }

}

/// A filled take that renders the member's actual video — a remote `videoUrl`
/// or a freshly-recorded local file. The clip is muted and looping here (the
/// synced multitrack player carries the ensemble audio); it shows the first
/// frame when idle and plays while the transport is playing. Falls back to the
/// dark instrument placeholder when there's no playable source or it fails.
class _ReadyTile extends StatefulWidget {
  final Track track;
  final bool playing;
  const _ReadyTile({required this.track, required this.playing});

  @override
  State<_ReadyTile> createState() => _ReadyTileState();
}

class _ReadyTileState extends State<_ReadyTile> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _ReadyTile old) {
    super.didUpdateWidget(old);
    // Source changed (e.g. the take was re-uploaded) → rebuild the controller.
    if (old.track.videoUrl != widget.track.videoUrl ||
        old.track.localPath != widget.track.localPath) {
      _disposeController();
      _failed = false;
      _init();
      return;
    }
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      if (widget.playing && !c.value.isPlaying) c.play();
      if (!widget.playing && c.value.isPlaying) c.pause();
    }
  }

  Future<void> _init() async {
    final t = widget.track;
    final url = t.videoUrl;
    try {
      VideoPlayerController c;
      if (url != null && url.startsWith('http')) {
        c = VideoPlayerController.networkUrl(Uri.parse(url));
      } else if (!kIsWeb && t.localPath != null) {
        c = createTakeController(t.localPath!);
      } else {
        return; // no playable source → keep the placeholder
      }
      await c.initialize();
      await c.setVolume(0); // visual only; audio comes from the synced player
      await c.setLooping(true);
      if (!mounted) {
        await c.dispose();
        return;
      }
      c.addListener(_tick);
      setState(() => _controller = c);
      if (widget.playing) await c.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  void _disposeController() {
    _controller?.removeListener(_tick);
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized && !_failed;
    final track = widget.track;
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.0,
          colors: [Color(0xFF2B2926), Color(0xFF161513), Color(0xFF0F0E0D)],
          stops: [0.0, 0.7, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            )
          else
            Center(
              child: Icon(
                SLIcons.instrument(track.instrument),
                size: 56,
                color: const Color(0xFFF4F3EF).withValues(alpha: 0.16),
              ),
            ),
          if (widget.playing)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: SL.rec,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: SL.rec, blurRadius: 8)],
                ),
              ),
            ),
          Positioned(
            left: 10,
            bottom: 10,
            child: SyncTag(track.partKo, tone: SLTagTone.onDark),
          ),
          if (track.member != null)
            Positioned(
              right: 10,
              bottom: 12,
              child: Text(
                track.member!.initial,
                style: SLType.sans(
                  size: 13,
                  weight: FontWeight.w700,
                  color: SL.textOnDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
