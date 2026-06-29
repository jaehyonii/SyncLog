import '../entities/person.dart';
import '../entities/recorded_take.dart';
import '../entities/team.dart';
import '../entities/track.dart';

/// The contract the app depends on for ensemble data. Implementations may be
/// local-first (persisted on device), backed by the REST API, or both.
abstract class TeamRepository {
  /// Point the store at [userId] (null = the default local profile) so each
  /// account reads and writes only its own teams. Clears any in-memory cache so
  /// the next [fetchTeams] reloads scoped to that user.
  void setActiveUser(String? userId);

  /// All teams the current user belongs to. (GET /api/v1/teams)
  Future<List<Team>> fetchTeams();

  /// Other teams' public takes the user can browse but isn't a member of.
  /// Empty in local-first mode (there is no shared catalog offline).
  /// (GET /api/v1/teams/discover)
  Future<List<Team>> discoverTeams();

  /// One team with its active tracks + sync offsets + timeline.
  /// (GET /api/v1/teams/{id}/stream)
  Future<Team> fetchTeam(String teamId);

  /// Create a team with the leader-defined [parts] (one is the creator's own;
  /// the rest become invite slots with their own per-part code).
  Future<Team> createTeam({
    required String name,
    required String song,
    required int bpm,
    required List<PartDraft> parts,
    required Person creator,
  });

  /// Join an existing team by its shareable invite code. (POST /teams/join)
  Future<Team> joinTeam(String code);

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
