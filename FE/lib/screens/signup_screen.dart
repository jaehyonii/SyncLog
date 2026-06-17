import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/icons.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/sync_button.dart';
import '../widgets/sync_text_field.dart';
import '../widgets/sync_app_bar.dart';
import '../util/app_exception.dart';

/// SIGN-UP — create a local account. Name + email + password (with a confirm
/// field checked client-side). On success the new account is signed in and the
/// router redirect lands on home, so no manual navigation here either.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    if (auth.busy) return;
    FocusScope.of(context).unfocus();
    if (_password.text != _confirm.text) {
      setState(() => _error = '비밀번호가 일치하지 않아요.');
      return;
    }
    setState(() => _error = null);
    try {
      await auth.signUp(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
      // Signed in — the router's redirect takes it from here.
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '가입하지 못했어요. 다시 시도해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().busy;
    return AuthScaffold(
      leading: SLIconButton(
        icon: SLIcons.arrowLeft,
        label: '뒤로',
        onTap: busy ? null : () => context.pop(),
      ),
      title: '계정 만들기',
      subtitle: '합주 팀을 만들고 함께 녹음하려면 가입하세요.',
      children: [
        SyncTextField(
          label: '이름',
          hint: '예: 김준호',
          controller: _name,
          leading: SLIcons.userRound,
          keyboardType: TextInputType.name,
          autofillHints: const [AutofillHints.name],
          enabled: !busy,
          onChanged: (_) => _clearError(),
        ),
        const SizedBox(height: 18),
        SyncTextField(
          label: '이메일',
          hint: 'you@synclog.app',
          controller: _email,
          leading: SLIcons.mail,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          enabled: !busy,
          onChanged: (_) => _clearError(),
        ),
        const SizedBox(height: 18),
        SyncTextField(
          label: '비밀번호',
          hint: '6자 이상',
          controller: _password,
          leading: SLIcons.lock,
          obscure: true,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !busy,
          onChanged: (_) => _clearError(),
        ),
        const SizedBox(height: 18),
        SyncTextField(
          label: '비밀번호 확인',
          hint: '비밀번호를 다시 입력하세요',
          controller: _confirm,
          leading: SLIcons.lock,
          obscure: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !busy,
          onChanged: (_) => _clearError(),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          AuthErrorBanner(message: _error!),
        ],
        const SizedBox(height: 24),
        SyncButton(
          label: busy ? '가입 중…' : '회원가입',
          variant: SLButtonVariant.primary,
          size: SLButtonSize.lg,
          fullWidth: true,
          onTap: busy ? null : _submit,
        ),
        const SizedBox(height: 18),
        AuthFooterLink(
          lead: '이미 계정이 있으신가요?',
          action: '로그인',
          onTap: busy ? null : () => context.pop(),
        ),
      ],
    );
  }
}
