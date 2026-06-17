import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/team.dart';
import '../../util/app_exception.dart';

/// Persists the full team list locally as JSON. This is the source of truth in
/// the app's local-first mode.
class TeamLocalDataSource {
  static const _key = 'synclog.teams.v1';
  final SharedPreferences _prefs;

  TeamLocalDataSource(this._prefs);

  bool get hasData => _prefs.containsKey(_key);

  List<Team>? loadTeams() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Team.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw AppException.storage(e);
    }
  }

  Future<void> saveTeams(List<Team> teams) async {
    try {
      final raw = jsonEncode(teams.map((t) => t.toJson()).toList());
      await _prefs.setString(_key, raw);
    } catch (e) {
      throw AppException.storage(e);
    }
  }

  Future<void> clear() => _prefs.remove(_key);
}
