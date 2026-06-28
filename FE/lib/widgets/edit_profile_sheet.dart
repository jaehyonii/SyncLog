import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../domain/entities/person.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../util/app_exception.dart';
import 'sync_app_bar.dart';
import 'sync_button.dart';
import 'sync_text_field.dart';

/// Edit-profile dialog: change name / email, and optionally set a new password.
/// Calls [AuthController.updateProfile] (remote API or on-device store) and pops
/// with the updated [Person] on success.
class EditProfileSheet extends StatefulWidget {
  final AuthController auth;
  final Person user;

  const EditProfileSheet({super.key, required this.auth, required this.user});

  static Future<Person?> show(BuildContext context, AuthController auth, Person user) {
    return showDialog<Person>(
      context: context,
      barrierColor: SL.overlay,
      builder: (_) => EditProfileSheet(auth: auth, user: user),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final _name = TextEditingController(text: widget.user.name);
  late final _email = TextEditingController(text: widget.user.email ?? '');
  final _password = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    try {
      final updated = await widget.auth.updateProfile(
        name: _name.text,
        email: _email.text,
        password: _password.text.isEmpty ? null : _password.text,
      );
      navigator.pop(updated);
    } on AppException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = '저장하지 못했어요. 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: SL.space6),
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
            Text('프로필 편집',
                textAlign: TextAlign.center,
                style: SLType.sans(size: SLType.xl, weight: FontWeight.w700, letterSpacing: -0.4)),
            const SizedBox(height: SL.space5),
            SyncTextField(
              label: '이름',
              hint: '이름',
              controller: _name,
              leading: SLIcons.userRound,
              enabled: !_saving,
            ),
            const SizedBox(height: SL.space4),
            SyncTextField(
              label: '이메일',
              hint: 'you@example.com',
              controller: _email,
              leading: SLIcons.mail,
              keyboardType: TextInputType.emailAddress,
              enabled: !_saving,
            ),
            const SizedBox(height: SL.space4),
            SyncTextField(
              label: '새 비밀번호 (선택)',
              hint: '변경하려면 입력하세요',
              controller: _password,
              leading: SLIcons.lock,
              obscure: true,
              textInputAction: TextInputAction.done,
              enabled: !_saving,
              onSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: SL.space3),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: SLType.sans(size: SLType.sm, color: SL.rec)),
            ],
            const SizedBox(height: SL.space5),
            SyncButton(
              label: _saving ? '저장 중…' : '저장',
              variant: SLButtonVariant.primary,
              size: SLButtonSize.lg,
              fullWidth: true,
              icon: SLIcons.check,
              onTap: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
