import 'package:flutter/foundation.dart';
import 'person.dart';

/// Whether a multitrack cell is filled with a member's take, or an open slot a
/// member can claim.
enum TrackStatus { ready, open }

/// One cell of a team's multitrack — a single instrument part. A `ready` track
/// carries a member's video take and the sync offset they tuned; an `open`
/// track is an empty slot any member can record into.
@immutable
class Track {
  final String id;
  final String part; // English part name, e.g. "Drums"
  final String partKo; // Korean, e.g. "드럼"
  final String instrument; // glyph key: drum / bass / guitar / keys / ...
  final TrackStatus status;
  final Person? member;

  /// Sync offset in milliseconds relative to the metronome downbeat. Applied as
  /// a playback delay when stacking tracks on the shared timeline.
  final int syncOffsetMs;

  /// Remote video URL of the take (null for open slots / local-only takes).
  final String? videoUrl;

  /// Local file path of a freshly recorded take, before/after upload.
  final String? localPath;

  final String? note;

  /// Per-part invite code. Present (server-issued) only for an unclaimed part
  /// the viewer is allowed to invite to; null once the part has an owner.
  final String? inviteCode;

  /// When the owner last uploaded to this part. Drives the once-per-day rule.
  final DateTime? lastUploadedAt;

  const Track({
    required this.id,
    required this.part,
    required this.partKo,
    required this.instrument,
    required this.status,
    this.member,
    this.syncOffsetMs = 0,
    this.videoUrl,
    this.localPath,
    this.note,
    this.inviteCode,
    this.lastUploadedAt,
  });

  bool get isReady => status == TrackStatus.ready;
  bool get isOpen => status == TrackStatus.open;

  /// A member has claimed this part (leader-assigned or joined by code).
  bool get isClaimed => member != null;

  /// This part belongs to [userId].
  bool isMine(String? userId) => userId != null && member?.id == userId;

  /// True if the owner already uploaded today (one-upload-per-day guard).
  bool get uploadedToday {
    final at = lastUploadedAt;
    if (at == null) return false;
    final now = DateTime.now();
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }

  /// A playable source exists (remote or local).
  bool get hasSource => videoUrl != null || localPath != null;

  Track copyWith({
    TrackStatus? status,
    Person? member,
    int? syncOffsetMs,
    String? videoUrl,
    String? localPath,
    String? note,
    String? inviteCode,
    DateTime? lastUploadedAt,
  }) =>
      Track(
        id: id,
        part: part,
        partKo: partKo,
        instrument: instrument,
        status: status ?? this.status,
        member: member ?? this.member,
        syncOffsetMs: syncOffsetMs ?? this.syncOffsetMs,
        videoUrl: videoUrl ?? this.videoUrl,
        localPath: localPath ?? this.localPath,
        note: note ?? this.note,
        inviteCode: inviteCode ?? this.inviteCode,
        lastUploadedAt: lastUploadedAt ?? this.lastUploadedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'part': part,
        'partKo': partKo,
        'instrument': instrument,
        'status': status.name,
        'member': member?.toJson(),
        'syncOffsetMs': syncOffsetMs,
        'videoUrl': videoUrl,
        'localPath': localPath,
        'note': note,
        'inviteCode': inviteCode,
        'lastUploadedAt': lastUploadedAt?.toIso8601String(),
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        part: json['part'] as String,
        partKo: json['partKo'] as String,
        instrument: json['instrument'] as String? ?? 'audio-lines',
        status: TrackStatus.values.byName(json['status'] as String? ?? 'open'),
        member: json['member'] == null
            ? null
            : Person.fromJson((json['member'] as Map).cast<String, dynamic>()),
        syncOffsetMs: json['syncOffsetMs'] as int? ?? 0,
        videoUrl: json['videoUrl'] as String?,
        localPath: json['localPath'] as String?,
        note: json['note'] as String?,
        inviteCode: json['inviteCode'] as String?,
        lastUploadedAt: json['lastUploadedAt'] == null
            ? null
            : DateTime.tryParse(json['lastUploadedAt'] as String),
      );
}

/// One part the leader defines when creating a team: a display name (preset or
/// custom), the glyph for its icon, and whether it's the leader's own part.
typedef PartDraft = ({String name, String instrument, bool mine});

/// The default instrument lineup used to seed a new team's open slots.
class InstrumentPreset {
  final String part;
  final String partKo;
  final String glyph;
  const InstrumentPreset(this.part, this.partKo, this.glyph);

  static const lineup = [
    InstrumentPreset('Drums', '드럼', 'drum'),
    InstrumentPreset('Bass', '베이스', 'audio-lines'),
    InstrumentPreset('Guitar', '기타', 'guitar'),
    InstrumentPreset('Keys', '건반', 'piano'),
    InstrumentPreset('Vocal', '보컬', 'audio-lines'),
    InstrumentPreset('Synth', '신스', 'piano'),
    InstrumentPreset('Perc', '퍼커션', 'drum'),
    InstrumentPreset('Strings', '스트링', 'audio-lines'),
  ];

  /// The glyph for a part name, matching a preset by Korean name (custom names
  /// fall back to the generic waveform glyph).
  static String glyphFor(String name) {
    final n = name.trim();
    for (final p in lineup) {
      if (p.partKo == n) return p.glyph;
    }
    return 'audio-lines';
  }
}
