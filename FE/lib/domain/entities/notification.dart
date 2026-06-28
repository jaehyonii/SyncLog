import 'package:flutter/foundation.dart';
import 'person.dart';

/// What an activity notification is about: someone joined a team you're in, or
/// someone stacked a new take onto a shared timeline.
enum NotificationType { join, take }

/// One entry in the user's activity feed (the 알림 screen). Server-issued; the
/// app is read-only over it (fetch + mark-all-read). Matches the backend's
/// `notificationToJson`.
@immutable
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;

  /// The team it relates to (may be null if the team was since deleted).
  final String? teamId;
  final String teamName;

  /// Who triggered it (the joiner / the recorder).
  final Person actor;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.teamId,
    required this.teamName,
    required this.actor,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: NotificationType.values.byName(json['type'] as String? ?? 'take'),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        teamId: json['teamId'] as String?,
        teamName: json['teamName'] as String? ?? '',
        actor: Person.fromJson((json['actor'] as Map).cast<String, dynamic>()),
        read: json['read'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
