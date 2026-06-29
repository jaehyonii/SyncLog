import 'package:flutter/material.dart';
import 'commit.dart';
import 'person.dart';
import 'track.dart';

/// A 합주 팀 (ensemble team): one target song, a fixed tempo, a roster, a
/// multitrack of instrument parts, and a practice timeline that grows like a
/// Git history.
@immutable
class Team {
  final String id;
  final String name;
  final String song;
  final String artist;
  final int bpm;
  final List<Person> members;
  final Color coverColor;
  final List<Track> tracks;
  final List<Commit> timeline;

  /// Shareable code others enter to join this team (server-issued; null in
  /// local-first mode or before the server assigns one).
  final String? inviteCode;

  const Team({
    required this.id,
    required this.name,
    required this.song,
    required this.artist,
    required this.bpm,
    required this.members,
    required this.coverColor,
    required this.tracks,
    required this.timeline,
    this.inviteCode,
  });

  int get tracksTotal => tracks.length;
  int get tracksReady => tracks.where((t) => t.isReady).length;
  bool get hasSong => song.trim().isNotEmpty && song != '곡 미정';

  /// The latest version tag on the timeline, if any.
  String? get latestVersion => timeline.isEmpty ? null : timeline.first.version;

  /// The first open slot a member can record into, if any.
  Track? get firstOpenTrack {
    for (final t in tracks) {
      if (t.isOpen) return t;
    }
    return null;
  }

  /// The part owned by [userId] (their fixed slot), if any.
  Track? myTrack(String? userId) {
    if (userId == null) return null;
    for (final t in tracks) {
      if (t.member?.id == userId) return t;
    }
    return null;
  }

  Track? trackById(String trackId) {
    for (final t in tracks) {
      if (t.id == trackId) return t;
    }
    return null;
  }

  Team copyWith({
    String? name,
    String? song,
    String? artist,
    int? bpm,
    List<Person>? members,
    Color? coverColor,
    List<Track>? tracks,
    List<Commit>? timeline,
    String? inviteCode,
  }) =>
      Team(
        id: id,
        name: name ?? this.name,
        song: song ?? this.song,
        artist: artist ?? this.artist,
        bpm: bpm ?? this.bpm,
        members: members ?? this.members,
        coverColor: coverColor ?? this.coverColor,
        tracks: tracks ?? this.tracks,
        timeline: timeline ?? this.timeline,
        inviteCode: inviteCode ?? this.inviteCode,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'song': song,
        'artist': artist,
        'bpm': bpm,
        'members': members.map((m) => m.toJson()).toList(),
        'coverColor': coverColor.toARGB32(),
        'tracks': tracks.map((t) => t.toJson()).toList(),
        'timeline': timeline.map((c) => c.toJson()).toList(),
        if (inviteCode != null) 'inviteCode': inviteCode,
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: json['name'] as String,
        song: json['song'] as String,
        artist: json['artist'] as String? ?? '',
        bpm: json['bpm'] as int? ?? 90,
        members: (json['members'] as List? ?? [])
            .map((m) => Person.fromJson((m as Map).cast<String, dynamic>()))
            .toList(),
        coverColor: Color(json['coverColor'] as int? ?? 0xFFE6DDCF),
        tracks: (json['tracks'] as List? ?? [])
            .map((t) => Track.fromJson((t as Map).cast<String, dynamic>()))
            .toList(),
        timeline: (json['timeline'] as List? ?? [])
            .map((c) => Commit.fromJson((c as Map).cast<String, dynamic>()))
            .toList(),
        inviteCode: json['inviteCode'] as String?,
      );
}
