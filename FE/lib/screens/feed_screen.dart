import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/social_controller.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../util/async_value.dart';
import '../widgets/ensemble_card.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_app_bar.dart';

/// 피드 — the SNS home feed: daily ensemble videos from teams whose members the
/// user follows, newest first. Server-only; in local-first mode it's empty.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialController>().loadHomeFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialController>();

    return Scaffold(
      backgroundColor: SL.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SyncAppBar(
              left: SLIconButton(
                  icon: SLIcons.arrowLeft, label: '뒤로', onTap: () => context.pop()),
              title: const Text('피드'),
            ),
            Expanded(
              child: !social.isRemote
                  ? const EmptyView(
                      icon: SLIcons.listMusic,
                      title: '피드가 비어 있어요',
                      message: '서버에 연결되면 팔로우한 사람들의\n합주 영상을 여기서 볼 수 있어요.',
                    )
                  : social.homeFeed.view(
                      onRetry: social.loadHomeFeed,
                      loading: () => const LoadingView(),
                      error: (message, retry) =>
                          ErrorView(message: message, onRetry: retry),
                      data: (feed) => feed.isEmpty
                          ? const EmptyView(
                              icon: SLIcons.userPlus,
                              title: '아직 피드가 조용해요',
                              message: '다른 사람을 팔로우하면\n그 팀의 합주 영상이 올라와요.',
                            )
                          : RefreshIndicator(
                              color: SL.ink,
                              onRefresh: social.loadHomeFeed,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(SL.gutter),
                                itemCount: feed.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (_, i) =>
                                    EnsembleCard(ensemble: feed[i]),
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
