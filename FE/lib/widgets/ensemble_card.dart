import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../domain/entities/ensemble.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../util/time_format.dart';
import 'ensemble_player.dart';
import 'member_avatar.dart';
import 'pressable.dart';

/// One post in the SNS feed: a team's daily ensemble video with a header (cover,
/// team, song, date) and a row of tappable member avatars that open each
/// member's profile. Used by both the home feed and explore.
class EnsembleCard extends StatelessWidget {
  final Ensemble ensemble;
  const EnsembleCard({super.key, required this.ensemble});

  @override
  Widget build(BuildContext context) {
    final e = ensemble;
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: SL.surfaceCard,
        border: Border.all(color: SL.borderSoft),
        borderRadius: BorderRadius.circular(SL.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- header ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.6),
                      radius: 1.2,
                      colors: [e.coverColor, const Color(0xFFCFCCC3)],
                    ),
                    borderRadius: BorderRadius.circular(SL.radiusSm),
                  ),
                  child: Icon(SLIcons.disc3,
                      size: 20, color: SL.ink.withValues(alpha: 0.4)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.teamName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SLType.sans(
                              size: SLType.md, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(SLIcons.target, size: 12, color: SL.textSecondary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(e.song,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SLType.sans(
                                    size: SLType.sm, color: SL.textSecondary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(relativeTime(e.createdAt),
                    style: SLType.sans(size: 11, color: SL.textPlaceholder)),
              ],
            ),
          ),

          // --- the ensemble video ---
          EnsemblePlayer(ensemble: e),

          // --- member avatars (tap → profile) ---
          if (e.members.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final m in e.members)
                    Pressable(
                      onTap: () => context.push('/users/${m.id}'),
                      semanticLabel: '${m.name} 프로필',
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
                        decoration: BoxDecoration(
                          color: SL.surfaceMuted,
                          borderRadius: BorderRadius.circular(SL.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MemberAvatar(person: m, size: 22),
                            const SizedBox(width: 6),
                            Text(m.name,
                                style: SLType.sans(
                                    size: SLType.xs, weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
