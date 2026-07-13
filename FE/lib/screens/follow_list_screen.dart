import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/social_controller.dart';
import '../domain/entities/person.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/member_avatar.dart';
import '../widgets/pressable.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_app_bar.dart';

/// A followers / following list. Each row opens that person's profile.
class FollowListScreen extends StatefulWidget {
  final String userId;
  final bool showFollowers;
  const FollowListScreen({
    super.key,
    required this.userId,
    required this.showFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late Future<List<Person>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Person>> _load() {
    final social = context.read<SocialController>();
    return widget.showFollowers
        ? social.fetchFollowers(widget.userId)
        : social.fetchFollowing(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SyncAppBar(
              left: SLIconButton(
                  icon: SLIcons.arrowLeft, label: '뒤로', onTap: () => context.pop()),
              title: Text(widget.showFollowers ? '팔로워' : '팔로잉'),
            ),
            Expanded(
              child: FutureBuilder<List<Person>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const LoadingView();
                  }
                  if (snap.hasError) {
                    return ErrorView(
                      message: '목록을 불러오지 못했어요.',
                      onRetry: () => setState(() => _future = _load()),
                    );
                  }
                  final people = snap.data ?? const [];
                  if (people.isEmpty) {
                    return EmptyView(
                      icon: SLIcons.userRound,
                      title: widget.showFollowers ? '아직 팔로워가 없어요' : '아직 팔로우한 사람이 없어요',
                      message: '합주 영상을 공유하며\n서로 팔로우해 보세요.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: people.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: SL.borderSoft),
                    itemBuilder: (_, i) => _PersonRow(person: people[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final Person person;
  const _PersonRow({required this.person});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.push('/users/${person.id}'),
      semanticLabel: '${person.name} 프로필',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SL.gutter, vertical: 12),
        child: Row(
          children: [
            MemberAvatar(person: person, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SLType.sans(size: SLType.md, weight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right, size: 20, color: SL.textPlaceholder),
          ],
        ),
      ),
    );
  }
}
