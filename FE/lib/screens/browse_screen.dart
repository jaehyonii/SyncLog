import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/teams_controller.dart';
import '../domain/entities/team.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/member_avatar.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_app_bar.dart';
import '../widgets/sync_tag.dart';

/// 둘러보기 — a browse-only feed of other teams' ensembles (teams the user isn't
/// in that already have takes). Server-only; in local-first mode it's empty.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  late Future<List<Team>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<TeamsController>().discoverTeams();
  }

  void _reload() {
    setState(() => _future = context.read<TeamsController>().discoverTeams());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SyncAppBar(
              left: SLIconButton(icon: SLIcons.arrowLeft, label: '뒤로', onTap: () => context.pop()),
              title: const Text('둘러보기'),
            ),
            Expanded(
              child: FutureBuilder<List<Team>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const LoadingView();
                  }
                  if (snap.hasError) {
                    return ErrorView(message: '합주 영상을 불러오지 못했어요.', onRetry: _reload);
                  }
                  final teams = snap.data ?? const [];
                  if (teams.isEmpty) {
                    return const EmptyView(
                      icon: SLIcons.listMusic,
                      title: '둘러볼 합주가 아직 없어요',
                      message: '다른 팀이 take를 올리면\n여기에서 감상할 수 있어요.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(SL.gutter),
                    children: [
                      Text('다른 팀의 합주',
                          style: SLType.sans(
                              size: SLType.xl2, weight: FontWeight.w700, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('${teams.length}개의 공개된 합주',
                          style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
                      const SizedBox(height: 16),
                      for (final t in teams) ...[
                        _BrowseCard(team: t),
                        const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseCard extends StatelessWidget {
  final Team team;
  const _BrowseCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SL.surfaceCard,
        border: Border.all(color: SL.borderSoft),
        borderRadius: BorderRadius.circular(SL.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.6),
                    radius: 1.2,
                    colors: [team.coverColor, const Color(0xFFCFCCC3)],
                  ),
                  borderRadius: BorderRadius.circular(SL.radiusSm),
                ),
                child: Icon(SLIcons.disc3, size: 24, color: SL.ink.withValues(alpha: 0.4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SLType.sans(size: SLType.lg, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(SLIcons.target, size: 13, color: SL.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(team.song,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MemberStack(members: team.members, size: 26),
              SyncTag('${team.tracksReady}개 파트 · ${team.bpm} BPM', tone: SLTagTone.neutral),
            ],
          ),
        ],
      ),
    );
  }
}
