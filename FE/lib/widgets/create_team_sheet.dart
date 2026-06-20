import 'package:flutter/material.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'pressable.dart';
import 'sync_app_bar.dart';
import 'sync_button.dart';

/// Inputs collected when creating a team.
class CreateTeamData {
  final String name;
  final String song;
  final int memberCount;
  final int bpm;
  const CreateTeamData({
    required this.name,
    required this.song,
    required this.memberCount,
    required this.bpm,
  });
}

/// The "합주 팀 만들기" bottom sheet — team name, target song, member-count
/// stepper, a manager-set BPM, and a copyable invite link.
class CreateTeamSheet extends StatefulWidget {
  final Future<void> Function(CreateTeamData data) onCreate;

  const CreateTeamSheet({super.key, required this.onCreate});

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(CreateTeamData data) onCreate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: SL.overlay,
      builder: (_) => CreateTeamSheet(onCreate: onCreate),
    );
  }

  @override
  State<CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends State<CreateTeamSheet> {
  final _name = TextEditingController();
  final _song = TextEditingController();
  int _count = 4;
  int _bpm = 90;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _song.dispose();
    super.dispose();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: SL.space2),
        child: Text(text,
            style: SLType.sans(size: SLType.sm, weight: FontWeight.w500, color: SL.textSecondary)),
      );

  Widget _field({required String label, required TextEditingController controller, required String hint, IconData? leading}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: SL.surfaceCard,
            border: Border.all(color: SL.border),
            borderRadius: BorderRadius.circular(SL.radiusSm),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                Icon(leading, size: 18, color: SL.textSecondary),
                const SizedBox(width: SL.space2),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  style: SLType.sans(size: SLType.md, color: SL.textPrimary),
                  cursorColor: SL.rec,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: SLType.sans(size: SLType.md, color: SL.textPlaceholder),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepperRow({
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    Widget stepBtn(IconData i, VoidCallback t, String l) => Pressable(
          onTap: t,
          semanticLabel: l,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SL.surfaceMuted,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(i, size: 18, color: SL.textPrimary),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
          height: 46,
          padding: const EdgeInsets.only(left: 16, right: 8),
          decoration: BoxDecoration(
            color: SL.surfaceCard,
            border: Border.all(color: SL.border),
            borderRadius: BorderRadius.circular(SL.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: SLType.sans(size: SLType.md, weight: FontWeight.w500)),
              Row(
                children: [
                  stepBtn(SLIcons.minus, onMinus, '$label 줄이기'),
                  const SizedBox(width: 6),
                  stepBtn(SLIcons.plus, onPlus, '$label 늘리기'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await widget.onCreate(CreateTeamData(
      name: _name.text,
      song: _song.text,
      memberCount: _count,
      bpm: _bpm,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: SL.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(SL.radiusLg)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                  decoration: BoxDecoration(
                    color: SL.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('합주 팀 만들기',
                      style: SLType.sans(size: SLType.xl, weight: FontWeight.w700, color: SL.textPrimary)),
                  SLIconButton(icon: SLIcons.close, label: '닫기', onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 20),
              _field(label: '팀 이름', controller: _name, hint: '예: 회전목마 합주단'),
              const SizedBox(height: 18),
              _field(label: '연습할 곡', controller: _song, hint: '예: 인생의 회전목마', leading: SLIcons.music),
              const SizedBox(height: 18),
              _stepperRow(
                label: '팀원 수',
                value: '$_count명',
                onMinus: () => setState(() => _count = (_count - 1).clamp(2, 8)),
                onPlus: () => setState(() => _count = (_count + 1).clamp(2, 8)),
              ),
              const SizedBox(height: 18),
              _stepperRow(
                label: '메트로놈 (BPM)',
                value: '$_bpm BPM',
                onMinus: () => setState(() => _bpm = (_bpm - 1).clamp(40, 240)),
                onPlus: () => setState(() => _bpm = (_bpm + 1).clamp(40, 240)),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: SL.surfaceMuted,
                  borderRadius: BorderRadius.circular(SL.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(SLIcons.link, size: 16, color: SL.textSecondary),
                    const SizedBox(width: SL.space2),
                    Expanded(
                      child: Text('팀을 만들면 초대 코드가 발급돼요. 팀 화면에서 코드를 공유해 팀원을 초대하세요.',
                          style: SLType.sans(size: 12, color: SL.textSecondary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SyncButton(
                label: _submitting ? '만드는 중…' : '팀 만들기',
                variant: SLButtonVariant.primary,
                size: SLButtonSize.lg,
                fullWidth: true,
                icon: SLIcons.plus,
                onTap: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
