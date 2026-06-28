import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/notifications_controller.dart';
import '../services/permission_service.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/member_avatar.dart';
import '../widgets/pressable.dart';
import '../widgets/sync_app_bar.dart';
import '../widgets/sync_button.dart';

/// 설정 — account, notifications and camera. Account edits go through
/// [EditProfileSheet]; the camera row requests OS permissions; notifications
/// links to the activity feed.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editProfile(BuildContext context) async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final updated = await EditProfileSheet.show(context, auth, user);
    if (updated != null) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 저장했어요')));
    }
  }

  Future<void> _requestCamera(BuildContext context) async {
    final permissions = context.read<PermissionService>();
    final messenger = ScaffoldMessenger.of(context);
    final granted = await permissions.ensureCameraAndMic();
    messenger.showSnackBar(SnackBar(
      content: Text(granted ? '카메라·마이크 권한이 허용됐어요' : '권한이 거부됐어요. 설정에서 허용해 주세요.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final notifications = context.watch<NotificationsController>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: SL.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SyncAppBar(
              left: SLIconButton(icon: SLIcons.arrowLeft, label: '뒤로', onTap: () => context.pop()),
              title: const Text('설정'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(SL.gutter),
                children: [
                  // ---- Account ----
                  const _SectionLabel('계정'),
                  const SizedBox(height: 12),
                  if (user != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: SL.surfaceCard,
                        border: Border.all(color: SL.borderSoft),
                        borderRadius: BorderRadius.circular(SL.radiusMd),
                      ),
                      child: Row(
                        children: [
                          MemberAvatar(person: user, size: 48),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name,
                                    style: SLType.sans(size: SLType.lg, weight: FontWeight.w700)),
                                if (user.email != null && user.email!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(user.email!,
                                      style:
                                          SLType.sans(size: SLType.sm, color: SL.textSecondary)),
                                ],
                              ],
                            ),
                          ),
                          SLIconButton(
                            icon: SLIcons.moreVertical,
                            label: '프로필 편집',
                            onTap: () => _editProfile(context),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  _SettingsRow(
                    icon: SLIcons.userRound,
                    title: '프로필 편집',
                    subtitle: '이름 · 이메일 · 비밀번호',
                    onTap: () => _editProfile(context),
                  ),

                  const SizedBox(height: 24),
                  // ---- Notifications ----
                  const _SectionLabel('알림'),
                  const SizedBox(height: 12),
                  _SettingsRow(
                    icon: SLIcons.bell,
                    title: '알림',
                    subtitle: notifications.unreadCount > 0
                        ? '안 읽은 알림 ${notifications.unreadCount}개'
                        : '팀 활동 알림 보기',
                    badge: notifications.unreadCount > 0 ? '${notifications.unreadCount}' : null,
                    onTap: () => context.push('/notifications'),
                  ),

                  const SizedBox(height: 24),
                  // ---- Camera ----
                  const _SectionLabel('카메라'),
                  const SizedBox(height: 12),
                  _SettingsRow(
                    icon: SLIcons.userRound,
                    title: '카메라 · 마이크 권한',
                    subtitle: '녹화에 필요한 권한을 확인해요',
                    onTap: () => _requestCamera(context),
                  ),

                  const SizedBox(height: 28),
                  if (user != null)
                    SyncButton(
                      label: '로그아웃',
                      variant: SLButtonVariant.outline,
                      size: SLButtonSize.lg,
                      fullWidth: true,
                      icon: SLIcons.logOut,
                      onTap: () async {
                        await context.read<AuthController>().logOut();
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: SL.surfaceCard,
          border: Border.all(color: SL.borderSoft),
          borderRadius: BorderRadius.circular(SL.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: SL.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: SLType.sans(size: SLType.md, weight: FontWeight.w500)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: SLType.sans(size: 12, color: SL.textSecondary)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SL.rec,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!,
                    style: SLType.sans(
                        size: SLType.xs, weight: FontWeight.w700, color: Colors.white)),
              ),
            const SizedBox(width: 4),
            Icon(SLIcons.chevronRight, size: 20, color: SL.textPlaceholder),
          ],
        ),
      ),
    );
  }
}
