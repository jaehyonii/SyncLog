import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import '../domain/entities/person.dart';
import '../domain/entities/recorded_take.dart';
import '../domain/entities/team.dart';
import '../domain/repositories/team_repository.dart';
import '../util/app_exception.dart';
import '../util/async_value.dart';

/// The app's central team store and single source of truth. Screens read teams
/// from here and mutate through it, so a create/upload anywhere reflects
/// everywhere (home list, detail, timeline) without manual plumbing.
class TeamsController extends ChangeNotifier {
  final TeamRepository _repo;
  final Person currentUser;

  AsyncValue<List<Team>> _teams = const AsyncLoading();
  AsyncValue<List<Team>> get teams => _teams;

  TeamsController(this._repo, {required this.currentUser});

  Team? teamById(String id) =>
      _teams.valueOrNull?.firstWhereOrNull((t) => t.id == id);

  Future<void> load() async {
    _teams = const AsyncLoading();
    notifyListeners();
    await _refresh();
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
    required int memberCount,
  }) async {
    final team = await _repo.createTeam(
      name: name,
      song: song,
      bpm: bpm,
      memberCount: memberCount,
      creator: currentUser,
    );
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
