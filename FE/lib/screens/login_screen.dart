import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/icons.dart';
import '../util/app_exception.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/sync_button.dart';
import '../widgets/sync_text_field.dart';

/// LOGIN — the gate into the app. Email + password against the local account
/// store; on success the router redirect drops the user straight onto home, so
/// this screen never navigates itself. A footer link crosses to sign-up.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    if (auth.busy) return;
    setState(() => _error = null);
    FocusScope.of(context).unfocus();
    try {
      await auth.logIn(email: _email.text, password: _password.text);
      // Authenticated — the router's redirect takes it from here.
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '로그인하지 못했어요. 다시 시도해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().busy;
    return AuthScaffold(
      title: '다시 오신 걸 환영해요',
      subtitle: '합주 팀과 이어서 작업하려면 로그인하세요.',
      children: [
        SyncTextField(
          label: '이메일',
          hint: 'you@synclog.app',
          controller: _email,
          leading: SLIcons.mail,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          enabled: !busy,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 18),
        SyncTextField(
          label: '비밀번호',
          hint: '비밀번호를 입력하세요',
          controller: _password,
          leading: SLIcons.lock,
          obscure: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          enabled: !busy,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          AuthErrorBanner(message: _error!),
        ],
        const SizedBox(height: 24),
        SyncButton(
          label: busy ? '로그인 중…' : '로그인',
          variant: SLButtonVariant.primary,
          size: SLButtonSize.lg,
          fullWidth: true,
          onTap: busy ? null : _submit,
        ),
        const SizedBox(height: 18),
        AuthFooterLink(
          lead: '아직 계정이 없으신가요?',
          action: '회원가입',
          onTap: busy ? null : () => context.push('/signup'),
        ),
      ],
    );
  }
}
