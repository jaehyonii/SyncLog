import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/entities/team.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'sync_app_bar.dart';
import 'sync_button.dart';

/// A popup that shows a team's shareable invite code so a member can copy it and
/// hand it to someone. They join by entering it in the "코드로 팀 참여" sheet.
class InviteCodeDialog extends StatefulWidget {
  final Team team;
  const InviteCodeDialog({super.key, required this.team});

  static Future<void> show(BuildContext context, Team team) {
    return showDialog<void>(
      context: context,
      barrierColor: SL.overlay,
      builder: (_) => InviteCodeDialog(team: team),
    );
  }

  @override
  State<InviteCodeDialog> createState() => _InviteCodeDialogState();
}

class _InviteCodeDialogState extends State<InviteCodeDialog> {
  bool _copied = false;

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.team.inviteCode;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SLIconButton(
                icon: SLIcons.close,
                label: '닫기',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Text('팀에 초대하기',
                textAlign: TextAlign.center,
                style: SLType.sans(size: SLType.xl, weight: FontWeight.w700, letterSpacing: -0.4)),
            const SizedBox(height: SL.space2),
            Text('이 코드를 공유하면 누구나 ‘${widget.team.name}’에 합류할 수 있어요.',
                textAlign: TextAlign.center,
                style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
            const SizedBox(height: SL.space5),
            if (code == null)
              Text('초대 코드를 불러오지 못했어요.',
                  textAlign: TextAlign.center,
                  style: SLType.sans(size: SLType.sm, color: SL.rec))
            else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: SL.space4),
                decoration: BoxDecoration(
                  color: SL.surfaceMuted,
                  borderRadius: BorderRadius.circular(SL.radiusSm),
                  border: Border.all(color: SL.border),
                ),
                alignment: Alignment.center,
                child: Text(code,
                    style: SLType.mono(size: SLType.xl2, weight: FontWeight.w700, letterSpacing: 6)),
              ),
              const SizedBox(height: SL.space4),
              SyncButton(
                label: _copied ? '복사됨' : '코드 복사',
                variant: _copied ? SLButtonVariant.soft : SLButtonVariant.primary,
                size: SLButtonSize.lg,
                fullWidth: true,
                icon: _copied ? SLIcons.check : SLIcons.copy,
                onTap: () => _copy(code),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
