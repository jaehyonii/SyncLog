import 'package:flutter/material.dart';
import 'person.dart';

/// Render lifecycle of a day's ensemble video. Mirrors the backend's
/// `EnsembleStatus`.
enum EnsembleStatus {
  rendering,
  ready,
  failed;

  /// Tolerant parse — unknown/newer server values fall back to [rendering] so an
  /// older client still renders the post as "준비 중" instead of throwing.
  static EnsembleStatus parse(String? name) {
    for (final s in EnsembleStatus.values) {
      if (s.name == name) return s;
    }
    return EnsembleStatus.rendering;
  }
}

/// A team's daily "post": the server-composited ensemble video for one calendar
/// day, shown in the SNS feed. Read-only on the client. Matches the backend's
/// `ensembleToJson`.
@immutable
class Ensemble {
  final String id;
  final String teamId;
  final String teamName;
  final String song;
  final Color coverColor;

  /// Calendar day key 'YYYY-MM-DD' (server timezone).
  final String day;

  final EnsembleStatus status;

  /// Public URL of the composited MP4; null until the render finishes.
  final String? videoUrl;
  final String? thumbnailUrl;

  /// Roster snapshot at render time.
  final List<Person> members;
  final DateTime createdAt;

  const Ensemble({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.song,
    required this.coverColor,
    required this.day,
    required this.status,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.members,
    required this.createdAt,
  });

  bool get isReady => status == EnsembleStatus.ready && videoUrl != null;

  factory Ensemble.fromJson(Map<String, dynamic> json) => Ensemble(
        id: json['id'] as String,
        teamId: json['teamId'] as String,
        teamName: json['teamName'] as String? ?? '',
        song: json['song'] as String? ?? '',
        coverColor: Color(json['coverColor'] as int? ?? 0xFFE6DDCF),
        day: json['day'] as String? ?? '',
        status: EnsembleStatus.parse(json['status'] as String?),
        videoUrl: json['videoUrl'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        members: (json['members'] as List? ?? [])
            .map((m) => Person.fromJson((m as Map).cast<String, dynamic>()))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
