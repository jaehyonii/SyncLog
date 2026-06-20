import 'package:flutter/material.dart';
import '../domain/entities/person.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'member_avatar.dart';
import 'sync_app_bar.dart';
import 'sync_button.dart';

/// A centered profile popup for the signed-in user — large avatar, name, email
/// and a quick readout of how many ensemble teams they're in. Opened from the
/// home screen's top-right avatar.
class ProfileSheet extends StatelessWidget {
  final Person user;
  final int teamCount;
  final Future<void> Function() onLogout;

  const ProfileSheet({
    super.key,
    required this.user,
    required this.teamCount,
    required this.onLogout,
  });

  static Future<void> show(
    BuildContext context, {
    required Person user,
    required int teamCount,
    required Future<void> Function() onLogout,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: SL.overlay,
      builder: (_) => ProfileSheet(
        user: user,
        teamCount: teamCount,
        onLogout: onLogout,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: SL.space7),
      child: Container(
        padding: const EdgeInsets.fromLTRB(SL.space6, SL.space4, SL.space6, SL.space6),
        decoration: BoxDecoration(
          color: SL.paper,
          borderRadius: BorderRadius.circular(SL.radiusLg),
          boxShadow: SL.shadowCard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close (X) pinned to the top-right of the card.
            Align(
              alignment: Alignment.centerRight,
              child: SLIconButton(
                icon: SLIcons.close,
                label: '닫기',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            MemberAvatar(person: user, size: 76),
            const SizedBox(height: SL.space4),
            Text(
              user.name,
              style: SLType.sans(size: SLType.xl2, weight: FontWeight.w700, letterSpacing: -0.5),
            ),
            if (user.email != null && user.email!.isNotEmpty) ...[
              const SizedBox(height: SL.space2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(SLIcons.mail, size: 15, color: SL.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    user.email!,
                    style: SLType.sans(size: SLType.sm, color: SL.textSecondary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: SL.space5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: SL.space4, vertical: SL.space3),
              decoration: BoxDecoration(
                color: SL.surfaceMuted,
                borderRadius: BorderRadius.circular(SL.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(SLIcons.disc3, size: 18, color: SL.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('활동 중인 합주 팀',
                        style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
                  ),
                  Text('$teamCount',
                      style: SLType.mono(size: SLType.md, weight: FontWeight.w700)),
                  Text('개', style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: SL.space5),
            SyncButton(
              label: '로그아웃',
              variant: SLButtonVariant.outline,
              fullWidth: true,
              icon: SLIcons.logOut,
              onTap: () async {
                Navigator.of(context).pop();
                await onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
