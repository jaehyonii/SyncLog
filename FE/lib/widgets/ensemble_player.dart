import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../domain/entities/ensemble.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// Plays a team's daily ensemble MP4 — a single server-composited video (grid +
/// mixed audio), so unlike the multitrack `VideoCell` this is ONE controller and
/// is NOT muted. Lazily initialized on first tap (feeds can be long); shows the
/// thumbnail as a poster until then, and a "준비 중"/실패 placeholder for
/// ensembles that aren't ready.
class EnsemblePlayer extends StatefulWidget {
  final Ensemble ensemble;
  const EnsemblePlayer({super.key, required this.ensemble});

  @override
  State<EnsemblePlayer> createState() => _EnsemblePlayerState();
}

class _EnsemblePlayerState extends State<EnsemblePlayer> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;

  Future<void> _onTap() async {
    final c = _controller;
    if (c != null) {
      setState(() => c.value.isPlaying ? c.pause() : c.play());
      return;
    }
    if (_loading) return;
    final url = widget.ensemble.videoUrl;
    if (url == null) return;
    setState(() => _loading = true);
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_tick);
      setState(() {
        _controller = controller;
        _loading = false;
      });
      await controller.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_tick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.ensemble;
    final c = _controller;
    final ready = c != null && c.value.isInitialized && !_failed;
    final playing = ready && c.value.isPlaying;

    return AspectRatio(
      aspectRatio: ready ? c.value.aspectRatio : 1,
      child: Pressable(
        onTap: e.isReady ? _onTap : null,
        child: Container(
          color: SL.dark0,
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
              else if (e.thumbnailUrl != null)
                Image.network(
                  e.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _poster(e),
                )
              else
                _poster(e),

              // Non-ready states get an explanatory badge.
              if (e.status == EnsembleStatus.rendering)
                _centerLabel(SLIcons.disc3, '합주 영상 준비 중'),
              if (e.status == EnsembleStatus.failed)
                _centerLabel(Icons.error_outline, '합주 영상을 만들지 못했어요'),

              // Play affordance while ready-but-paused (or spinner while loading).
              if (e.isReady && !playing)
                Center(
                  child: _loading
                      ? const SizedBox(
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: SL.overlay,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(SLIcons.play,
                              size: 30, color: Colors.white),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _poster(Ensemble e) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.0,
            colors: [Color(0xFF2B2926), Color(0xFF141311)],
          ),
        ),
        child: Center(
          child: Icon(SLIcons.disc3,
              size: 56, color: SL.textOnDark.withValues(alpha: 0.18)),
        ),
      );

  Widget _centerLabel(IconData icon, String text) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: SL.textOnDarkDim),
            const SizedBox(height: 10),
            Text(text,
                style: SLType.sans(
                    size: SLType.sm, color: SL.textOnDarkDim, weight: FontWeight.w600)),
          ],
        ),
      );
}
