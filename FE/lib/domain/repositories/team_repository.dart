import '../entities/person.dart';
import '../entities/recorded_take.dart';
import '../entities/team.dart';

/// The contract the app depends on for ensemble data. Implementations may be
/// local-first (persisted on device), backed by the REST API, or both.
abstract class TeamRepository {
  /// All teams the current user belongs to. (GET /api/v1/teams)
  Future<List<Team>> fetchTeams();

  /// One team with its active tracks + sync offsets + timeline.
  /// (GET /api/v1/teams/{id}/stream)
  Future<Team> fetchTeam(String teamId);

  /// Create a team and seed [memberCount] open instrument slots.
  Future<Team> createTeam({
    required String name,
    required String song,
    required int bpm,
    required int memberCount,
    required Person creator,
  });

  /// Upload a recorded take into a track with its tuned sync offset, fill the
  /// slot, and append a versioned commit. (POST /api/v1/teams/{id}/record)
  Future<Team> uploadTake({
    required String teamId,
    required String trackId,
    required RecordedTake take,
    required int syncOffsetMs,
    required Person member,
    String? note,
  });
}
