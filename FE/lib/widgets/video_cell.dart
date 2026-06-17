import 'package:flutter/material.dart';
import '../domain/entities/track.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'pressable.dart';
import 'sync_tag.dart';

/// One cell of the multitrack grid on the dark stage. A `ready` track shows the
/// member's take (instrument glyph on a near-black vignette); an `open` cell is
/// a tappable join slot with a "참여 +" pill.
///
/// Camera & video are honest dark placeholders — drop in the real Flutter
/// camera preview / track thumbnails (or wire `videoUrl`) for production.
class VideoCell extends StatelessWidget {
  final Track track;
  final VoidCallback? onJoin;
  final bool playing;

  const VideoCell({
    super.key,
    required this.track,
    this.onJoin,
    this.playing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (track.isOpen) {
      return Pressable(
        onTap: onJoin,
        semanticLabel: '${track.part} 참여',
        child: Container(
          color: SL.dark1,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(SLIcons.circlePlus, size: 30, color: SL.textOnDarkDim),
                    const SizedBox(height: 12),
                    Text(
                      'PENDING',
                      style: SLType.mono(
                        size: SLType.xs,
                        color: SL.textOnDarkDim,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: SyncTag('${track.part} 참여 +', tone: SLTagTone.onDark),
              ),
            ],
          ),
        ),
      );
    }

    // ready track — dark stage placeholder with instrument glyph
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
        children: [
          Center(
            child: Icon(
              SLIcons.instrument(track.instrument),
              size: 56,
              color: const Color(0xFFF4F3EF).withValues(alpha: 0.16),
            ),
          ),
          if (playing)
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
            child: SyncTag(track.part, tone: SLTagTone.onDark),
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
