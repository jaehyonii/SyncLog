import 'package:flutter/foundation.dart';
import '../data/datasources/social_remote_datasource.dart';
import '../domain/entities/ensemble.dart';
import '../domain/entities/person.dart';
import '../domain/entities/user_profile.dart';
import '../util/async_value.dart';

/// The SNS store: the home feed (ensembles from teams whose members I follow),
/// the explore feed (all public ensembles), user profiles, and the follow
/// graph. Like [NotificationsController], the SNS is inherently a server feature
/// (it's about *other* people), so in local-first mode everything is empty and
/// follow actions are no-ops.
class SocialController extends ChangeNotifier {
  final SocialRemoteDataSource? _remote;

  SocialController({SocialRemoteDataSource? remote}) : _remote = remote;

  bool get isRemote => _remote != null;

  AsyncValue<List<Ensemble>> _homeFeed = const AsyncData([]);
  AsyncValue<List<Ensemble>> _exploreFeed = const AsyncData([]);
  final Map<String, AsyncValue<UserProfile>> _profiles = {};

  AsyncValue<List<Ensemble>> get homeFeed => _homeFeed;
  AsyncValue<List<Ensemble>> get exploreFeed => _exploreFeed;

  /// The cached profile state for [userId], if it's been loaded.
  AsyncValue<UserProfile>? profileFor(String userId) => _profiles[userId];

  /// Pull the home feed. In local mode it stays empty.
  Future<void> loadHomeFeed() async {
    final remote = _remote;
    if (remote == null) {
      _homeFeed = const AsyncData([]);
      notifyListeners();
      return;
    }
    _homeFeed = const AsyncLoading();
    notifyListeners();
    try {
      _homeFeed = AsyncData(await remote.homeFeed());
    } catch (e) {
      _homeFeed = AsyncError(e, '피드를 불러오지 못했어요.');
    }
    notifyListeners();
  }

  /// Pull the explore feed (all public ensembles).
  Future<void> loadExplore() async {
    final remote = _remote;
    if (remote == null) {
      _exploreFeed = const AsyncData([]);
      notifyListeners();
      return;
    }
    _exploreFeed = const AsyncLoading();
    notifyListeners();
    try {
      _exploreFeed = AsyncData(await remote.explore());
    } catch (e) {
      _exploreFeed = AsyncError(e, '합주 영상을 불러오지 못했어요.');
    }
    notifyListeners();
  }

  /// Load (or refresh) a user's profile into the cache.
  Future<void> loadProfile(String userId) async {
    final remote = _remote;
    if (remote == null) return;
    _profiles[userId] = const AsyncLoading();
    notifyListeners();
    try {
      _profiles[userId] = AsyncData(await remote.profile(userId));
    } catch (e) {
      _profiles[userId] = AsyncError(e, '프로필을 불러오지 못했어요.');
    }
    notifyListeners();
  }

  /// Follow / unfollow [userId], optimistically flipping the cached profile so
  /// the button reacts instantly; reverts on failure. A new follow can change
  /// the home feed, so it's refreshed on success.
  Future<void> toggleFollow(String userId, bool currentlyFollowing) async {
    final remote = _remote;
    if (remote == null) return;

    final before = _profiles[userId];
    if (before is AsyncData<UserProfile>) {
      final p = before.value;
      var nextCount = p.followerCount + (currentlyFollowing ? -1 : 1);
      if (nextCount < 0) nextCount = 0;
      _profiles[userId] = AsyncData(
        p.copyWith(isFollowing: !currentlyFollowing, followerCount: nextCount),
      );
      notifyListeners();
    }

    try {
      final res = currentlyFollowing
          ? await remote.unfollow(userId)
          : await remote.follow(userId);
      final now = _profiles[userId];
      if (now is AsyncData<UserProfile>) {
        _profiles[userId] = AsyncData(now.value.copyWith(
          isFollowing: res.isFollowing,
          followerCount: res.followerCount,
        ));
        notifyListeners();
      }
      await loadHomeFeed();
    } catch (_) {
      // Revert the optimistic flip.
      if (before != null) {
        _profiles[userId] = before;
        notifyListeners();
      }
    }
  }

  /// One-shot fetch of a user's followers (for the follow-list screen).
  Future<List<Person>> fetchFollowers(String userId) async =>
      _remote == null ? const [] : _remote.followers(userId);

  /// One-shot fetch of who a user follows.
  Future<List<Person>> fetchFollowing(String userId) async =>
      _remote == null ? const [] : _remote.following(userId);

  /// Drop all cached feeds/profiles (on sign-out).
  void clear() {
    _homeFeed = const AsyncData([]);
    _exploreFeed = const AsyncData([]);
    _profiles.clear();
    notifyListeners();
  }
}
