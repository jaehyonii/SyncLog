import 'package:flutter/foundation.dart';
import 'ensemble.dart';
import 'person.dart';

/// A user's public profile: their [Person] fields plus social counts, whether
/// the viewer follows them, and their ensemble posts. Matches the backend's
/// `profileToJson`.
@immutable
class UserProfile {
  final Person person;
  final int followerCount;
  final int followingCount;
  final bool isFollowing;
  final List<Ensemble> ensembles;

  const UserProfile({
    required this.person,
    required this.followerCount,
    required this.followingCount,
    required this.isFollowing,
    required this.ensembles,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        // The profile JSON spreads a Person at the top level.
        person: Person.fromJson(json),
        followerCount: json['followerCount'] as int? ?? 0,
        followingCount: json['followingCount'] as int? ?? 0,
        isFollowing: json['isFollowing'] as bool? ?? false,
        ensembles: (json['ensembles'] as List? ?? [])
            .map((e) => Ensemble.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  /// For optimistic follow toggles: flip the flag and nudge the follower count.
  UserProfile copyWith({bool? isFollowing, int? followerCount}) => UserProfile(
        person: person,
        followerCount: followerCount ?? this.followerCount,
        followingCount: followingCount,
        isFollowing: isFollowing ?? this.isFollowing,
        ensembles: ensembles,
      );
}
