import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/teams_controller.dart';
import '../domain/entities/team.dart';
import '../domain/entities/track.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/pressable.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_app_bar.dart';
import '../widgets/sync_tag.dart';

/// 보관함 — the user's own contributions, derived from their teams: every take
/// they've recorded, plus the ensembles that are now fully stacked (완성본).
class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TeamsController>();
    final meId = controller.currentUser.id;
    final teams = controller.teams.valueOrNull ?? const <Team>[];

    // My recorded takes (ready tracks I own), with the team they belong to.
    final myTakes = <({Team team, Track track})>[];
    for (final t in teams) {
      for (final tr in t.tracks) {
        if (tr.isReady && tr.member?.id == meId) {
          myTakes.add((team: t, track: tr));
        }
      }
    }
    // Ensembles where every slot is filled.
    final finished =
        teams.where((t) => t.tracksTotal > 0 && t.tracksReady == t.tracksTotal).toList();

    return Scaffold(
      backgroundColor: SL.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SyncAppBar(
              left: SLIconButton(icon: SLIcons.arrowLeft, label: '뒤로', onTap: () => context.pop()),
              title: const Text('보관함'),
            ),
            Expanded(
              child: controller.teams.isLoading
                  ? const LoadingView()
                  : (myTakes.isEmpty && finished.isEmpty)
                      ? const EmptyView(
                          icon: SLIcons.archive,
                          title: '보관함이 비어 있어요',
                          message: '파트를 녹화하면 내가 올린 take가\n여기에 모여요.',
                        )
                      : ListView(
                          padding: const EdgeInsets.all(SL.gutter),
                          children: [
                            _SectionLabel('내가 올린 take · ${myTakes.length}'),
                            const SizedBox(height: 12),
                            if (myTakes.isEmpty)
                              _emptyHint('아직 올린 take가 없어요.')
                            else
                              for (final e in myTakes) ...[
                                _TakeRow(team: e.team, track: e.track),
                                const SizedBox(height: 10),
                              ],
                            const SizedBox(height: 24),
                            _SectionLabel('완성된 합주 · ${finished.length}'),
                            const SizedBox(height: 12),
                            if (finished.isEmpty)
                              _emptyHint('아직 완성된 합주가 없어요.')
                            else
                              for (final t in finished) ...[
                                _FinishedRow(team: t),
                                const SizedBox(height: 10),
                              ],
                            const SizedBox(height: 40),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: SLType.sans(size: SLType.sm, color: SL.textPlaceholder)),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(label,
      style: SLType.sans(
          size: SLType.xs,
          weight: FontWeight.w700,
          color: SL.textPlaceholder,
          letterSpacing: 1.1));
}

class _TakeRow extends StatelessWidget {
  final Team team;
  final Track track;
  const _TakeRow({required this.team, required this.track});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.go('/teams/${team.id}'),
      semanticLabel: '${team.name} ${track.partKo}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SL.surfaceCard,
          border: Border.all(color: SL.borderSoft),
          borderRadius: BorderRadius.circular(SL.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SL.surfaceMuted,
                borderRadius: BorderRadius.circular(SL.radiusSm),
              ),
              child: Icon(SLIcons.instrument(track.instrument), size: 22, color: SL.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(track.partKo,
                          style: SLType.sans(size: SLType.md, weight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      SyncTag(team.name, tone: SLTagTone.neutral),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(track.note ?? '${track.partKo} 파트',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
                ],
              ),
            ),
            Icon(SLIcons.chevronRight, size: 20, color: SL.textPlaceholder),
          ],
        ),
      ),
    );
  }
}

class _FinishedRow extends StatelessWidget {
  final Team team;
  const _FinishedRow({required this.team});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.go('/teams/${team.id}'),
      semanticLabel: team.name,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SL.surfaceCard,
          border: Border.all(color: SL.borderSoft),
          borderRadius: BorderRadius.circular(SL.radiusMd),
        ),
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
                  colors: [team.coverColor, const Color(0xFFCFCCC3)],
                ),
                borderRadius: BorderRadius.circular(SL.radiusSm),
              ),
              child: Icon(SLIcons.check, size: 22, color: SL.ink.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SLType.sans(size: SLType.md, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('${team.song} · ${team.tracksTotal}개 파트 완성',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
                ],
              ),
            ),
            Icon(SLIcons.chevronRight, size: 20, color: SL.textPlaceholder),
          ],
        ),
      ),
    );
  }
}
