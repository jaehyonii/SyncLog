import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config.dart';
import 'controllers/teams_controller.dart';
import 'data/datasources/team_local_datasource.dart';
import 'data/datasources/team_remote_datasource.dart';
import 'data/repositories/team_repository_impl.dart';
import 'services/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---- Composition root: wire config → data sources → repository → state ----
  final config = AppConfig.fromEnvironment();
  final prefs = await SharedPreferences.getInstance();
  final session = Session.local();

  final local = TeamLocalDataSource(prefs);
  final remote = config.useRemote
      ? HttpTeamRemoteDataSource(baseUrl: config.apiBaseUrl)
      : null;
  final repository = TeamRepositoryImpl(local: local, remote: remote);

  final teamsController = TeamsController(repository, currentUser: session.currentUser)
    ..load();

  runApp(SyncLogApp(teamsController: teamsController));
}
