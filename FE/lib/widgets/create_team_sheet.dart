import 'package:flutter/material.dart';
import '../domain/entities/track.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'pressable.dart';
import 'sync_app_bar.dart';
import 'sync_button.dart';

/// Inputs collected when creating a team.
class CreateTeamData {
  final String name;
  final String song;
  final int bpm;

  /// The parts (roles) the leader defined. Exactly one has `mine: true`.
  final List<PartDraft> parts;

  const CreateTeamData({
    required this.name,
    required this.song,
    required this.bpm,
    required this.parts,
  });
}

/// One editable part row in the sheet (a name field + a stable key for keying).
class _PartRow {
  final TextEditingController controller;
  _PartRow(String name) : controller = TextEditingController(text: name);
}

/// The "합주 팀 만들기" bottom sheet — team name, target song, a per-part role
/// editor (each part gets its own invite code; the leader picks their own
/// part), and a manager-set BPM.
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
  final List<_PartRow> _parts = [
    _PartRow('보컬'),
    _PartRow('기타'),
    _PartRow('베이스'),
    _PartRow('드럼'),
  ];
  int _mineIndex = 0;
  int _bpm = 90;
  bool _submitting = false;

  static const _maxParts = 8;
  static const _minParts = 2;

  @override
  void dispose() {
    _name.dispose();
    _song.dispose();
    for (final p in _parts) {
      p.controller.dispose();
    }
    super.dispose();
  }

  void _addPart(String name) {
    if (_parts.length >= _maxParts) return;
    setState(() => _parts.add(_PartRow(name)));
  }

  void _removePart(int i) {
    if (_parts.length <= _minParts) return;
    setState(() {
      _parts[i].controller.dispose();
      _parts.removeAt(i);
      if (_mineIndex >= _parts.length) _mineIndex = _parts.length - 1;
      if (_mineIndex == i) _mineIndex = 0;
    });
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

  /// One part row: its glyph, an editable name, a "내 파트" pick, and remove.
  Widget _partRow(int i) {
    final isMine = i == _mineIndex;
    final glyph = InstrumentPreset.glyphFor(_parts[i].controller.text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SL.surfaceMuted,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(SLIcons.instrument(glyph), size: 18, color: SL.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: SL.surfaceCard,
                border: Border.all(color: SL.border),
                borderRadius: BorderRadius.circular(SL.radiusSm),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _parts[i].controller,
                onChanged: (_) => setState(() {}), // refresh glyph
                style: SLType.sans(size: SLType.md, color: SL.textPrimary),
                cursorColor: SL.rec,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '파트 이름',
                  hintStyle: SLType.sans(size: SLType.md, color: SL.textPlaceholder),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Pressable(
            onTap: () => setState(() => _mineIndex = i),
            semanticLabel: '내 파트로 지정',
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isMine ? SL.rec : SL.surfaceMuted,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text('내 파트',
                  style: SLType.sans(
                      size: 12,
                      weight: FontWeight.w700,
                      color: isMine ? Colors.white : SL.textSecondary)),
            ),
          ),
          if (_parts.length > _minParts) ...[
            const SizedBox(width: 4),
            Pressable(
              onTap: () => _removePart(i),
              semanticLabel: '파트 삭제',
              child: SizedBox(
                width: 32,
                height: 44,
                child: Icon(SLIcons.close, size: 16, color: SL.textPlaceholder),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _presetChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final p in InstrumentPreset.lineup)
          Pressable(
            onTap: _parts.length >= _maxParts ? null : () => _addPart(p.partKo),
            semanticLabel: '${p.partKo} 추가',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: SL.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SL.borderSoft),
              ),
              child: Text('+ ${p.partKo}',
                  style: SLType.sans(size: 12, weight: FontWeight.w500, color: SL.textSecondary)),
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
    final parts = <PartDraft>[
      for (var i = 0; i < _parts.length; i++)
        if (_parts[i].controller.text.trim().isNotEmpty)
          (
            name: _parts[i].controller.text.trim(),
            instrument: InstrumentPreset.glyphFor(_parts[i].controller.text),
            mine: i == _mineIndex,
          ),
    ];
    if (parts.length < _minParts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파트를 2개 이상 입력해 주세요.')),
      );
      return;
    }
    // Guarantee one part is the leader's even if the picked row was left blank.
    if (!parts.any((p) => p.mine)) {
      parts[0] = (name: parts[0].name, instrument: parts[0].instrument, mine: true);
    }
    setState(() => _submitting = true);
    await widget.onCreate(CreateTeamData(
      name: _name.text,
      song: _song.text,
      bpm: _bpm,
      parts: parts,
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
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
              _label('파트 구성 · ‘내 파트’를 하나 정하세요'),
              for (var i = 0; i < _parts.length; i++) _partRow(i),
              const SizedBox(height: 6),
              _presetChips(),
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
                      child: Text('파트마다 다른 초대 코드가 발급돼요. 팀 화면에서 각 파트의 코드를 공유해 팀원을 초대하세요.',
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
