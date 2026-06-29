import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/entities/track.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'sync_app_bar.dart';
import 'sync_button.dart';

/// Shows one part's own invite code so the leader can hand it to the exact
/// person who should play that part. They join (and claim the part) by entering
/// it in the "코드로 팀 참여" sheet.
class PartInviteDialog extends StatefulWidget {
  final String teamName;
  final Track track;
  const PartInviteDialog({super.key, required this.teamName, required this.track});

  static Future<void> show(BuildContext context, String teamName, Track track) {
    return showDialog<void>(
      context: context,
      barrierColor: SL.overlay,
      builder: (_) => PartInviteDialog(teamName: teamName, track: track),
    );
  }

  @override
  State<PartInviteDialog> createState() => _PartInviteDialogState();
}

class _PartInviteDialogState extends State<PartInviteDialog> {
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
    final code = widget.track.inviteCode;
    final part = widget.track.partKo;
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
            Text('‘$part’ 파트 초대',
                textAlign: TextAlign.center,
                style: SLType.sans(size: SLType.xl, weight: FontWeight.w700, letterSpacing: -0.4)),
            const SizedBox(height: SL.space2),
            Text('이 코드를 받은 사람은 ‘${widget.teamName}’의 ‘$part’ 파트를 맡게 돼요.',
                textAlign: TextAlign.center,
                style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
            const SizedBox(height: SL.space5),
            if (code == null)
              Text('이 파트의 초대 코드를 불러오지 못했어요.',
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
