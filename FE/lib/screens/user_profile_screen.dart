import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/social_controller.dart';
import '../domain/entities/ensemble.dart';
import '../domain/entities/user_profile.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../util/async_value.dart';
import '../widgets/ensemble_card.dart';
import '../widgets/member_avatar.dart';
import '../widgets/pressable.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_app_bar.dart';
import '../widgets/sync_button.dart';

/// A user's public profile: avatar, follower/following counts, a follow button,
/// and a grid of their team ensembles. Server-only.
class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialController>().loadProfile(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialController>();
    final myId = context.read<AuthController>().currentUser?.id;
    final state = social.profileFor(widget.userId);

    return Scaffold(
      backgroundColor: SL.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SyncAppBar(
              left: SLIconButton(
                  icon: SLIcons.arrowLeft, label: '뒤로', onTap: () => context.pop()),
              title: const Text('프로필'),
            ),
            Expanded(
              child: !social.isRemote || state == null
                  ? const LoadingView()
                  : state.view(
                      onRetry: () => social.loadProfile(widget.userId),
                      loading: () => const LoadingView(),
                      error: (message, retry) =>
                          ErrorView(message: message, onRetry: retry),
                      data: (profile) => _ProfileBody(
                        profile: profile,
                        isSelf: myId == widget.userId,
                        onToggleFollow: () => social.toggleFollow(
                            widget.userId, profile.isFollowing),
                        onRefresh: () => social.loadProfile(widget.userId),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserProfile profile;
  final bool isSelf;
  final VoidCallback onToggleFollow;
  final Future<void> Function() onRefresh;

  const _ProfileBody({
    required this.profile,
    required this.isSelf,
    required this.onToggleFollow,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return RefreshIndicator(
      color: SL.ink,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(SL.gutter),
        children: [
          Row(
            children: [
              MemberAvatar(person: p.person, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.person.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SLType.sans(
                            size: SLType.xl, weight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Count(
                          label: '팔로워',
                          value: p.followerCount,
                          onTap: () =>
                              context.push('/users/${p.person.id}/followers'),
                        ),
                        const SizedBox(width: 18),
                        _Count(
                          label: '팔로잉',
                          value: p.followingCount,
                          onTap: () =>
                              context.push('/users/${p.person.id}/following'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isSelf) ...[
            const SizedBox(height: 16),
            SyncButton(
              label: p.isFollowing ? '팔로잉' : '팔로우',
              variant:
                  p.isFollowing ? SLButtonVariant.soft : SLButtonVariant.primary,
              size: SLButtonSize.md,
              icon: p.isFollowing ? SLIcons.check : SLIcons.userPlus,
              fullWidth: true,
              onTap: onToggleFollow,
            ),
          ],
          const SizedBox(height: 22),
          Text('합주 영상',
              style:
                  SLType.sans(size: SLType.md, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (p.ensembles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('아직 완성된 합주 영상이 없어요.',
                    style: SLType.sans(
                        size: SLType.sm, color: SL.textSecondary)),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: p.ensembles.length,
              itemBuilder: (_, i) => _EnsembleTile(ensemble: p.ensembles[i]),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onTap;
  const _Count({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label $value',
      child: Row(
        children: [
          Text('$value',
              style: SLType.sans(size: SLType.md, weight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(label,
              style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
        ],
      ),
    );
  }
}

/// A square ensemble thumbnail; tapping opens the full card (with the player).
class _EnsembleTile extends StatelessWidget {
  final Ensemble ensemble;
  const _EnsembleTile({required this.ensemble});

  void _open(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(SL.gutter),
        child: EnsembleCard(ensemble: ensemble),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thumb = ensemble.thumbnailUrl;
    return Pressable(
      onTap: ensemble.isReady ? () => _open(context) : null,
      semanticLabel: '${ensemble.teamName} 합주 영상',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SL.radiusSm),
        child: Container(
          color: SL.dark0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                Image.network(thumb, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder())
              else
                _placeholder(),
              if (ensemble.isReady)
                Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration:
                        BoxDecoration(color: SL.overlay, shape: BoxShape.circle),
                    child: const Icon(SLIcons.play, size: 22, color: Colors.white),
                  ),
                ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Text(ensemble.day,
                    style: SLType.mono(
                        size: 11, color: SL.textOnDark, weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Center(
        child: Icon(SLIcons.disc3,
            size: 32, color: SL.textOnDark.withValues(alpha: 0.18)),
      );
}
