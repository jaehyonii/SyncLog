import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/entities/team.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../util/app_exception.dart';
import 'sync_app_bar.dart';
import 'sync_button.dart';

/// The "코드로 팀 참여" bottom sheet — enter a team's invite code to join its
/// roster. Returns the joined [Team] (so the caller can navigate to it), or null
/// if dismissed.
class JoinTeamSheet extends StatefulWidget {
  /// Performs the join (typically `TeamsController.joinTeam`). Throws an
  /// [AppException] with a user-facing message on an invalid code / offline.
  final Future<Team> Function(String code) onJoin;

  const JoinTeamSheet({super.key, required this.onJoin});

  static Future<Team?> show(
    BuildContext context, {
    required Future<Team> Function(String code) onJoin,
  }) {
    return showModalBottomSheet<Team>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: SL.overlay,
      builder: (_) => JoinTeamSheet(onJoin: onJoin),
    );
  }

  @override
  State<JoinTeamSheet> createState() => _JoinTeamSheetState();
}

class _JoinTeamSheetState extends State<JoinTeamSheet> {
  final _code = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = '초대 코드를 입력해 주세요.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final team = await widget.onJoin(code);
      if (mounted) Navigator.of(context).pop(team);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '참여하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity,
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
                  Text('코드로 팀 참여',
                      style: SLType.sans(size: SLType.xl, weight: FontWeight.w700)),
                  SLIconButton(
                      icon: SLIcons.close, label: '닫기', onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 6),
              Text('초대받은 합주 팀의 코드를 입력하면 바로 합류해요.',
                  style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
              const SizedBox(height: 20),
              Text('초대 코드',
                  style: SLType.sans(
                      size: SLType.sm, weight: FontWeight.w500, color: SL.textSecondary)),
              const SizedBox(height: SL.space2),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: SL.surfaceCard,
                  border: Border.all(color: _error != null ? SL.rec : SL.border),
                  borderRadius: BorderRadius.circular(SL.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(SLIcons.link, size: 18, color: SL.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _code,
                        autofocus: true,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _submit(),
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                        ],
                        style: SLType.mono(size: SLType.lg, weight: FontWeight.w700, letterSpacing: 2),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '예: MERRYGO',
                          hintStyle: SLType.mono(size: SLType.lg, color: SL.textPlaceholder),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: SL.space2),
                Text(_error!, style: SLType.sans(size: SLType.sm, color: SL.rec)),
              ],
              const SizedBox(height: 22),
              SyncButton(
                label: _submitting ? '참여하는 중…' : '팀 참여하기',
                variant: SLButtonVariant.primary,
                size: SLButtonSize.lg,
                fullWidth: true,
                icon: SLIcons.userPlus,
                onTap: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Forces typed invite-code text to uppercase so it matches the stored code.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    return next.copyWith(text: next.text.toUpperCase());
  }
}
