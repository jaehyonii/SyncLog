import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Shared chrome for the login / sign-up screens: the SyncLog wordmark, a
/// title + subtitle, and a keyboard-safe centered column. Keeping it here means
/// both auth screens stay visually identical and only supply their own fields.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Optional leading widget (e.g. a back button) pinned to the top-left.
  final Widget? leading;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.paper,
      body: SafeArea(
        child: Stack(
          children: [
            if (leading != null)
              Positioned(left: 4, top: 4, child: leading!),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(SL.gutter, 40, SL.gutter, 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandMark(),
                      const SizedBox(height: 36),
                      Text(title,
                          style: SLType.sans(
                              size: SLType.xl2,
                              weight: FontWeight.w700,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Text(subtitle,
                          style: SLType.sans(
                              size: SLType.base, color: SL.textSecondary, height: 1.4)),
                      const SizedBox(height: 28),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The red-dot + "SyncLog" wordmark, matching the home app bar.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(color: SL.rec, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Text('SyncLog',
            style: SLType.sans(
                size: SLType.xl, weight: FontWeight.w700, letterSpacing: -0.4)),
      ],
    );
  }
}

/// A soft red inline banner for auth failures.
class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SL.recSoft,
        borderRadius: BorderRadius.circular(SL.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: SL.rec),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: SLType.sans(
                    size: SLType.sm, color: SL.rec, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

/// "아직 계정이 없으신가요? · 회원가입" style footer used on both auth screens.
class AuthFooterLink extends StatelessWidget {
  final String lead;
  final String action;
  final VoidCallback? onTap;
  const AuthFooterLink({
    super.key,
    required this.lead,
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(lead, style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onTap,
            child: Text(action,
                style: SLType.sans(
                    size: SLType.sm, weight: FontWeight.w700, color: SL.rec)),
          ),
        ],
      ),
    );
  }
}
