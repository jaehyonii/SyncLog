import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/team_detail_controller.dart';
import '../controllers/teams_controller.dart';
import '../domain/entities/commit.dart';
import '../domain/entities/team.dart';
import '../services/playback_service.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../util/time_format.dart';
import '../widgets/invite_code_dialog.dart';
import '../widgets/member_avatar.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_app_bar.dart';
import '../widgets/sync_button.dart';
import '../widgets/sync_tag.dart';
import '../widgets/video_cell.dart';

/// 2. ENSEMBLE DETAIL & ARCHIVE. Top: a multitrack grid on the dark stage with a
/// scrubber + transport (synced playback applies each track's sync offset).
/// Bottom: a Git-style practice timeline. A sticky 내 파트 녹화하기 CTA records
/// into an open slot.
class TeamDetailScreen extends StatefulWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final _detail = TeamDetailController();
  String? _boundSignature;
  bool _refreshed = false;

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  String _signatureOf(Team t) =>
      t.tracks.where((x) => x.isReady).map((x) => '${x.id}:${x.syncOffsetMs}:${x.videoUrl}').join(',');

  void _rebindIfNeeded(Team team) {
    final sig = _signatureOf(team);
    if (sig == _boundSignature) return;
    _boundSignature = sig;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _detail.bind(team);
    });
  }

  void _recordInto(Team team, String? trackId) {
    final tid = trackId ?? team.firstOpenTrack?.id;
    final q = tid != null ? '?trackId=$tid' : '';
    context.push('/teams/${team.id}/record$q');
  }

  @override
  Widget build(BuildContext context) {
    final teams = context.watch<TeamsController>();
    final team = teams.teamById(widget.teamId);

    // Pull this team's latest server state once on open (no-op in local mode),
    // so others' takes/joins show up without a full list reload.
    if (!_refreshed) {
      _refreshed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<TeamsController>().refreshTeam(widget.teamId);
      });
    }

    // While the list is still loading we may not have the team yet.
    if (team == null) {
      return Scaffold(
        backgroundColor: SL.paper,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SyncAppBar(
                left: SLIconButton(icon: SLIcons.arrowLeft, label: '뒤로', onTap: () => context.pop()),
                title: const Text('합주 히스토리'),
              ),
              Expanded(
                child: teams.teams.isLoading
                    ? const LoadingView()
                    : EmptyView(
                        icon: Icons.search_off,
                        title: '팀을 찾을 수 없어요',
                        message: '이 합주 팀이 삭제되었거나 접근할 수 없어요.',
                        actionLabel: '홈으로',
                        actionIcon: Icons.home_outlined,
                        onAction: () => context.go('/'),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    _rebindIfNeeded(team);
    final hasOpen = team.firstOpenTrack != null;

    return ChangeNotifierProvider.value(
      value: _detail,
      child: Scaffold(
        backgroundColor: SL.paper,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  SyncAppBar(
                    left: SLIconButton(icon: SLIcons.arrowLeft, label: '뒤로', onTap: () => context.pop()),
                    title: const Text('합주 히스토리'),
                    right: SLIconButton(
                      icon: SLIcons.userPlus,
                      label: '팀에 초대',
                      onTap: () => InviteCodeDialog.show(context, team),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _MultitrackGrid(team: team, onJoin: (id) => _recordInto(team, id)),
                        const _Scrubber(),
                        _HistoryTimeline(team: team),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(SL.gutter, 14, SL.gutter, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [SL.paper, SL.paper, Color(0x00F6F5F1)],
                      stops: [0.0, 0.72, 1.0],
                    ),
                  ),
                  child: SyncButton(
                    label: hasOpen ? '내 파트 녹화하기' : '모든 파트가 찼어요',
                    variant: hasOpen ? SLButtonVariant.primary : SLButtonVariant.soft,
                    size: SLButtonSize.lg,
                    fullWidth: true,
                    icon: hasOpen ? SLIcons.circle : SLIcons.check,
                    onTap: hasOpen ? () => _recordInto(team, null) : null,
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

class _MultitrackGrid extends StatelessWidget {
  final Team team;
  final void Function(String trackId) onJoin;
  const _MultitrackGrid({required this.team, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<TeamDetailController>();
    final cols = team.tracks.length <= 1 ? 1 : 2;
    return Stack(
      children: [
        Container(
          color: SL.dark3,
          child: ValueListenableBuilder<PlaybackState>(
            valueListenable: detail.playback,
            builder: (context, state, _) => GridView.count(
              crossAxisCount: cols,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: (390 / cols - 1) / 150,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final tr in team.tracks)
                  VideoCell(
                    track: tr,
                    onJoin: () => onJoin(tr.id),
                    playing: state.isPlaying && tr.isReady,
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: SL.scrimLabel,
              borderRadius: BorderRadius.circular(SL.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: SL.rec, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                Text("TODAY'S SESSION · ${team.bpm} BPM",
                    style: SLType.sans(
                        size: SLType.xs,
                        weight: FontWeight.w700,
                        color: SL.textOnDark,
                        letterSpacing: 0.7)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Scrubber extends StatelessWidget {
  const _Scrubber();

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<TeamDetailController>();
    return ValueListenableBuilder<PlaybackState>(
      valueListenable: detail.playback,
      builder: (context, state, _) {
        final canPlay = detail.canPlay;
        final totalSec = state.total == Duration.zero ? 225 : state.total.inSeconds;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: SL.gutter, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: SL.borderSoft)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 12,
                child: LayoutBuilder(builder: (context, c) {
                  final frac = state.fraction.clamp(0.0, 1.0);
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                            color: SL.waveformTrack, borderRadius: BorderRadius.circular(2)),
                      ),
                      Container(
                        height: 4,
                        width: c.maxWidth * frac,
                        decoration: BoxDecoration(color: SL.rec, borderRadius: BorderRadius.circular(2)),
                      ),
                      Positioned(
                        left: (c.maxWidth * frac) - 6,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: canPlay ? SL.rec : SL.gray400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(fmtTime(state.fraction * totalSec),
                      style: SLType.mono(size: 13, color: SL.textSecondary)),
                  Row(
                    children: [
                      SLIconButton(
                        icon: SLIcons.skipBack,
                        label: '5초 뒤로',
                        color: canPlay ? null : SL.gray400,
                        onTap: canPlay ? detail.skipBack : null,
                      ),
                      const SizedBox(width: 8),
                      Opacity(
                        opacity: canPlay ? 1 : 0.4,
                        child: GestureDetector(
                          onTap: canPlay ? detail.toggle : null,
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: SL.ink, width: 2),
                            ),
                            child: Icon(state.isPlaying ? SLIcons.pause : SLIcons.play,
                                size: 26, color: SL.ink),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SLIconButton(
                        icon: SLIcons.skipForward,
                        label: '5초 앞으로',
                        color: canPlay ? null : SL.gray400,
                        onTap: canPlay ? detail.skipForward : null,
                      ),
                    ],
                  ),
                  Text(fmtTime(totalSec), style: SLType.mono(size: 13, color: SL.textSecondary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  final Team team;
  const _HistoryTimeline({required this.team});

  @override
  Widget build(BuildContext context) {
    final timeline = team.timeline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(SL.gutter, 16, SL.gutter, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('연습 히스토리',
              style: SLType.sans(
                  size: SLType.xs,
                  weight: FontWeight.w700,
                  color: SL.textPlaceholder,
                  letterSpacing: 1.1)),
          const SizedBox(height: 16),
          if (timeline.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('아직 기록이 없어요. 첫 파트를 녹화해 보세요.',
                  style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
            )
          else
            Stack(
              children: [
                Positioned(
                  left: 11,
                  top: 4,
                  bottom: 14,
                  child: Container(width: 2, color: SL.border),
                ),
                Column(
                  children: [
                    for (var i = 0; i < timeline.length; i++)
                      _CommitRow(commit: timeline[i], last: i == timeline.length - 1),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CommitRow extends StatelessWidget {
  final Commit commit;
  final bool last;
  const _CommitRow({required this.commit, required this.last});

  @override
  Widget build(BuildContext context) {
    final c = commit;
    return Padding(
      padding: EdgeInsets.only(left: 30, bottom: last ? 0 : 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -30, top: 1, child: MemberAvatar(person: c.member, size: 24)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(c.member.name, style: SLType.sans(size: SLType.sm, weight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(color: SL.recSoft, borderRadius: BorderRadius.circular(6)),
                    child: Text(c.version,
                        style: SLType.mono(size: SLType.xs, weight: FontWeight.w700, color: SL.rec)),
                  ),
                  if (c.part != null) ...[
                    const SizedBox(width: 8),
                    SyncTag(c.part!, tone: SLTagTone.neutral),
                  ],
                  const Spacer(),
                  Text(relativeTime(c.createdAt),
                      style: SLType.sans(size: 12, color: SL.textPlaceholder)),
                ],
              ),
              const SizedBox(height: 4),
              Text(c.note, style: SLType.sans(size: SLType.sm, color: SL.textSecondary, height: 1.5)),
            ],
          ),
        ],
      ),
    );
  }
}
