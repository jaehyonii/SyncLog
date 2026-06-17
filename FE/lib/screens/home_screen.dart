import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/teams_controller.dart';
import '../domain/entities/team.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../util/async_value.dart';
import '../widgets/create_team_sheet.dart';
import '../widgets/member_avatar.dart';
import '../widgets/menu_drawer.dart';
import '../widgets/pressable.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_app_bar.dart';

/// 1. HOME — My Ensemble Teams. Your 합주 팀 as cards; the `+` FAB opens the
/// create-team sheet; the ☰ menu opens the left drawer. Renders loading, error
/// and empty states explicitly.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _createTeam(BuildContext context, CreateTeamData data) async {
    final controller = context.read<TeamsController>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final team = await controller.createTeam(
        name: data.name,
        song: data.song,
        bpm: data.bpm,
        memberCount: data.memberCount,
      );
      messenger.showSnackBar(SnackBar(content: Text('‘${team.name}’ 팀을 만들었어요')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('팀을 만들지 못했어요. 다시 시도해 주세요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TeamsController>();

    return Scaffold(
      backgroundColor: SL.paper,
      drawer: const Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        width: 296,
        child: MenuDrawer(),
      ),
      body: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) => Stack(
            children: [
              Column(
                children: [
                  SyncAppBar(
                    left: SLIconButton(
                      icon: SLIcons.menu,
                      label: '메뉴',
                      onTap: () => Scaffold.of(context).openDrawer(),
                    ),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: SL.rec, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 7),
                        Text('SyncLog',
                            style: SLType.sans(
                                size: SLType.xl, weight: FontWeight.w700, letterSpacing: -0.4)),
                      ],
                    ),
                    right: MemberAvatar(person: controller.currentUser, size: 32),
                  ),
                  Expanded(
                    child: controller.teams.view(
                      onRetry: controller.load,
                      loading: () => const LoadingView(),
                      error: (msg, retry) => ErrorView(message: msg, onRetry: retry),
                      data: (teams) => _TeamList(teams: teams),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 18,
                bottom: 28,
                child: Pressable(
                  semanticLabel: '새 합주 팀',
                  onTap: () => CreateTeamSheet.show(context,
                      onCreate: (data) => _createTeam(context, data)),
                  child: Container(
                    width: SL.fabSize,
                    height: SL.fabSize,
                    decoration: BoxDecoration(
                      color: SL.ink,
                      shape: BoxShape.circle,
                      boxShadow: SL.shadowFab,
                    ),
                    child: const Icon(SLIcons.plus, size: 26, color: SL.textOnInk),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamList extends StatelessWidget {
  final List<Team> teams;
  const _TeamList({required this.teams});

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return const EmptyView(
        icon: Icons.groups_outlined,
        title: '아직 합주 팀이 없어요',
        message: '오른쪽 아래 + 버튼으로\n첫 합주 팀을 만들어 보세요.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(SL.gutter),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('합주 팀',
                style: SLType.sans(size: SLType.xl2, weight: FontWeight.w700, letterSpacing: -0.5)),
            Text('${teams.length}개 활동 중',
                style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
          ],
        ),
        const SizedBox(height: 16),
        for (final t in teams) ...[
          _TeamCard(team: t, onTap: () => context.push('/teams/${t.id}')),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const _TeamCard({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
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
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.6),
                  radius: 1.2,
                  colors: [team.coverColor, const Color(0xFFCFCCC3)],
                ),
                borderRadius: BorderRadius.circular(SL.radiusSm),
              ),
              child: Icon(SLIcons.disc3, size: 30, color: SL.ink.withValues(alpha: 0.4)),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 9),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MemberStack(members: team.members, size: 26),
                      _Readout(team: team),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  final Team team;
  const _Readout({required this.team});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${team.tracksReady}/${team.tracksTotal} ',
            style: SLType.mono(size: 12, color: SL.textSecondary)),
        Text('• ', style: SLType.mono(size: 12, weight: FontWeight.w700, color: SL.rec)),
        Text('${team.bpm}', style: SLType.mono(size: 12, color: SL.textSecondary)),
        Text('BPM', style: SLType.mono(size: 9, color: SL.textSecondary)),
      ],
    );
  }
}
