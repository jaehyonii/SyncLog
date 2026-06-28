import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/notifications_controller.dart';
import '../domain/entities/notification.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../util/time_format.dart';
import '../widgets/member_avatar.dart';
import '../widgets/pressable.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_app_bar.dart';

/// The 알림 (activity feed) screen: who joined a team you're in, and who stacked
/// a new take. Opening it refreshes the feed and marks everything read (clearing
/// the drawer badge). Tapping a notification jumps to its team.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh, then mark read once the latest feed is in.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<NotificationsController>();
      await controller.load();
      await controller.markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationsController>();
    final items = controller.items;

    return Scaffold(
      backgroundColor: SL.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SyncAppBar(
              left: SLIconButton(icon: SLIcons.arrowLeft, label: '뒤로', onTap: () => context.pop()),
              title: const Text('알림'),
            ),
            Expanded(
              child: !controller.isRemote
                  ? const EmptyView(
                      icon: SLIcons.bell,
                      title: '알림이 없어요',
                      message: '서버에 연결되면 팀 활동 알림을 여기서 볼 수 있어요.',
                    )
                  : controller.isLoading && items.isEmpty
                      ? const LoadingView()
                      : items.isEmpty
                          ? const EmptyView(
                              icon: SLIcons.bell,
                              title: '알림이 없어요',
                              message: '팀에 새 멤버가 들어오거나\n새 take가 올라오면 여기에 표시돼요.',
                            )
                          : RefreshIndicator(
                              color: SL.ink,
                              onRefresh: controller.load,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: items.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1, color: SL.borderSoft),
                                itemBuilder: (_, i) => _NotificationRow(item: items[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification item;
  const _NotificationRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: item.teamId == null ? null : () => context.go('/teams/${item.teamId}'),
      semanticLabel: item.title,
      child: Container(
        color: item.read ? Colors.transparent : SL.recSoft.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: SL.gutter, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MemberAvatar(person: item.actor, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        item.type == NotificationType.join
                            ? SLIcons.userPlus
                            : SLIcons.gitCommit,
                        size: 14,
                        color: SL.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SLType.sans(size: SLType.sm, weight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Text(relativeTime(item.createdAt),
                          style: SLType.sans(size: 11, color: SL.textPlaceholder)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SLType.sans(size: SLType.sm, color: SL.textSecondary, height: 1.4)),
                ],
              ),
            ),
            if (!item.read) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: SL.rec, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
