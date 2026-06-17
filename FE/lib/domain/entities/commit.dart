import 'package:flutter/foundation.dart';
import 'person.dart';

/// One entry on a team's Git-style practice timeline — a versioned take with a
/// one-line "commit message" (연습 소감).
@immutable
class Commit {
  final String id;
  final Person member;
  final String version; // e.g. "v1.2"
  final String note;
  final String? part;
  final DateTime createdAt;

  const Commit({
    required this.id,
    required this.member,
    required this.version,
    required this.note,
    required this.createdAt,
    this.part,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'member': member.toJson(),
        'version': version,
        'note': note,
        'part': part,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Commit.fromJson(Map<String, dynamic> json) => Commit(
        id: json['id'] as String,
        member: Person.fromJson((json['member'] as Map).cast<String, dynamic>()),
        version: json['version'] as String,
        note: json['note'] as String,
        part: json['part'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
