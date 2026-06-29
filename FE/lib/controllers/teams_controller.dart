import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import '../domain/entities/person.dart';
import '../domain/entities/recorded_take.dart';
import '../domain/entities/team.dart';
import '../domain/entities/track.dart';
import '../domain/repositories/team_repository.dart';
import '../util/app_exception.dart';
import '../util/async_value.dart';

/// The app's central team store and single source of truth. Screens read teams
/// from here and mutate through it, so a create/upload anywhere reflects
/// everywhere (home list, detail, timeline) without manual plumbing.
class TeamsController extends ChangeNotifier {
  final TeamRepository _repo;

  /// The signed-in user, used to attribute created teams and uploaded takes.
  /// Updated by [setCurrentUser] when auth state changes (login/logout).
  Person currentUser;

  AsyncValue<List<Team>> _teams = const AsyncLoading();
  AsyncValue<List<Team>> get teams => _teams;

  TeamsController(this._repo, {required this.currentUser});

  /// Point attribution at a newly signed-in user. No-op if unchanged.
  void setCurrentUser(Person user) {
    if (currentUser.id == user.id && currentUser.name == user.name) return;
    currentUser = user;
    // Re-scope the store to this account so the next load() pulls their teams.
    _repo.setActiveUser(user.id);
    notifyListeners();
  }

  Team? teamById(String id) =>
      _teams.valueOrNull?.firstWhereOrNull((t) => t.id == id);

  Future<void> load() async {
    _teams = const AsyncLoading();
    notifyListeners();
    await _refresh();
  }

  /// Other teams' public takes the user can browse but isn't a member of.
  /// Empty in local-first mode. Surfaced by the 둘러보기 screen.
  Future<List<Team>> discoverTeams() => _repo.discoverTeams();

  /// Re-pull one team's latest state from the server (in remote mode) and patch
  /// it into the list, so the detail screen reflects others' takes/joins.
  /// Best-effort: keeps the cached copy on failure.
  Future<void> refreshTeam(String id) async {
    final list = _teams.valueOrNull;
    if (list == null) return;
    try {
      final fresh = await _repo.fetchTeam(id);
      final i = list.indexWhere((t) => t.id == id);
      final next = [...list];
      if (i == -1) {
        next.insert(0, fresh);
      } else {
        next[i] = fresh;
      }
      _teams = AsyncValue.data(next);
      notifyListeners();
    } catch (_) {
      // Keep the cached copy; the detail screen still renders.
    }
  }

  Future<void> _refresh() async {
    try {
      final list = await _repo.fetchTeams();
      _teams = AsyncValue.data(list);
    } on AppException catch (e) {
      _teams = AsyncValue.error(e, e.message);
    } catch (e) {
      _teams = AsyncValue.error(e, '팀을 불러오지 못했어요.');
    }
    notifyListeners();
  }

  /// Create a team and surface it at the top of the list.
  Future<Team> createTeam({
    required String name,
    required String song,
    required int bpm,
    required List<PartDraft> parts,
  }) async {
    final team = await _repo.createTeam(
      name: name,
      song: song,
      bpm: bpm,
      parts: parts,
      creator: currentUser,
    );
    await _refresh();
    return team;
  }

  /// Join a team by its invite code, then refresh the list to include it.
  Future<Team> joinTeam(String code) async {
    final team = await _repo.joinTeam(code);
    await _refresh();
    return team;
  }

  /// Upload a recorded take into a track and refresh the affected team.
  Future<Team> uploadTake({
    required String teamId,
    required String trackId,
    required RecordedTake take,
    required int syncOffsetMs,
    String? note,
  }) async {
    final updated = await _repo.uploadTake(
      teamId: teamId,
      trackId: trackId,
      take: take,
      syncOffsetMs: syncOffsetMs,
      member: currentUser,
      note: note,
    );
    await _refresh();
    return updated;
  }
}
