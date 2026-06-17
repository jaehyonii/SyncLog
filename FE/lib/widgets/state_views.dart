import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'sync_button.dart';

/// Centered loading spinner in the brand ink.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: SL.ink),
      ),
    );
  }
}

/// A retryable error state.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SL.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 44, color: SL.textPlaceholder),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: SLType.sans(size: SLType.md, color: SL.textSecondary)),
            const SizedBox(height: 18),
            SyncButton(
              label: '다시 시도',
              variant: SLButtonVariant.soft,
              size: SLButtonSize.md,
              icon: Icons.refresh,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// An empty state with an icon, title, message and an optional primary action.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SL.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: SL.textPlaceholder),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: SLType.sans(size: SLType.lg, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: SLType.sans(size: SLType.sm, color: SL.textSecondary, height: 1.5)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SyncButton(
                label: actionLabel!,
                variant: SLButtonVariant.primary,
                size: SLButtonSize.md,
                icon: actionIcon,
                onTap: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
