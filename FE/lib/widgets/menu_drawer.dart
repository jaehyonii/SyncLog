import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
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
/// bottom tab bar is gone. Items are visual mockups that close the drawer on
/// tap (no account header — the home screen already shows the profile).
class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  static const _items = [
    _MenuItem(SLIcons.listMusic, '둘러보기', sub: '다른 팀의 합주 영상'),
    _MenuItem(SLIcons.archive, '보관함', sub: '내가 올린 take · 완성본'),
    _MenuItem(SLIcons.bell, '알림', badge: '3'),
    _MenuItem(SLIcons.userPlus, '초대 관리', sub: '받은 초대 1개'),
    _MenuItem(SLIcons.settings, '설정', sub: '카메라 · 알림 · 계정'),
  ];

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
                  children: [for (final it in _items) _row(context, it)],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: SL.borderSoft)),
                ),
                child: Column(
                  children: [
                    _row(context, const _MenuItem(SLIcons.helpCircle, '도움말')),
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
