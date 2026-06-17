import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../widgets/state_views.dart';

/// Shown for unknown routes or missing resources.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.paper,
      body: SafeArea(
        child: EmptyView(
          icon: Icons.error_outline,
          title: '찾을 수 없어요',
          message: '요청한 화면이 없거나 이동할 수 없어요.',
          actionLabel: '홈으로',
          actionIcon: Icons.home_outlined,
          onAction: () => context.go('/'),
        ),
      ),
    );
  }
}
