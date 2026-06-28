import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/notifications_controller.dart';
import '../controllers/teams_controller.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'join_team_sheet.dart';
import 'pressable.dart';

class _MenuItem {
  final IconData icon;
  final String label;
  final String? sub;
  final String? badge;
  final bool danger;
  const _MenuItem(this.icon, this.label, {this.sub, this.badge, this.danger = false});
}

/// The left navigation drawer — the only path to global navigation now that the
/// bottom tab bar is gone. Each item closes the drawer and pushes its screen.
class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  /// Close the drawer, then push [route].
  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.push(route);
  }

  /// Open the "join by code" sheet. On success the joined team is already in the
  /// list (the controller refreshes), so we just confirm and close the drawer.
  Future<void> _openJoin(BuildContext context) async {
    final teams = context.read<TeamsController>();
    final messenger = ScaffoldMessenger.of(context);
    final team = await JoinTeamSheet.show(context, onJoin: teams.joinTeam);
    if (!context.mounted) return;
    Navigator.of(context).pop(); // close the drawer
    if (team != null) {
      messenger.showSnackBar(SnackBar(content: Text('‘${team.name}’ 팀에 참여했어요')));
    }
  }

  /// Sign out, then let the router's redirect carry the user to /login. The
  /// controller is captured before popping the drawer so the read survives the
  /// dismissed subtree.
  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthController>();
    Navigator.of(context).pop();
    await auth.logOut();
  }

  Widget _row(BuildContext context, _MenuItem it, {VoidCallback? onTap}) {
    return Pressable(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      semanticLabel: it.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        child: Row(
          children: [
            Icon(it.icon, size: 22, color: it.danger ? SL.rec : SL.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.label,
                      style: SLType.sans(
                          size: SLType.md,
                          weight: FontWeight.w500,
                          color: it.danger ? SL.rec : SL.textPrimary)),
                  if (it.sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(it.sub!,
                          style: SLType.sans(size: 12, color: SL.textSecondary)),
                    ),
                ],
              ),
            ),
            if (it.badge != null)
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SL.rec,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(it.badge!,
                    style: SLType.sans(size: SLType.xs, weight: FontWeight.w700, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationsController>().unreadCount;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 296,
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
        height: double.infinity,
        decoration: BoxDecoration(color: SL.paper, boxShadow: SL.shadowCard),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  children: [
                    _row(
                      context,
                      const _MenuItem(SLIcons.userPlus, '코드로 팀 참여', sub: '초대 코드로 합주 팀 합류'),
                      onTap: () => _openJoin(context),
                    ),
                    _row(
                      context,
                      const _MenuItem(SLIcons.listMusic, '둘러보기', sub: '다른 팀의 합주 영상'),
                      onTap: () => _go(context, '/browse'),
                    ),
                    _row(
                      context,
                      const _MenuItem(SLIcons.archive, '보관함', sub: '내가 올린 take · 완성본'),
                      onTap: () => _go(context, '/archive'),
                    ),
                    _row(
                      context,
                      _MenuItem(SLIcons.bell, '알림',
                          badge: unread > 0 ? '$unread' : null),
                      onTap: () => _go(context, '/notifications'),
                    ),
                    _row(
                      context,
                      const _MenuItem(SLIcons.settings, '설정', sub: '카메라 · 알림 · 계정'),
                      onTap: () => _go(context, '/settings'),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: SL.borderSoft)),
                ),
                child: Column(
                  children: [
                    _row(context, const _MenuItem(SLIcons.helpCircle, '도움말'),
                        onTap: () => _go(context, '/help')),
                    _row(context, const _MenuItem(SLIcons.logOut, '로그아웃', danger: true),
                        onTap: () => _logout(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
