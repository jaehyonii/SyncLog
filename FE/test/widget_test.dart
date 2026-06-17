// Smoke tests: the SyncLog app gates on auth, then boots to Home once signed in.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synclog/app.dart';
import 'package:synclog/controllers/auth_controller.dart';
import 'package:synclog/controllers/teams_controller.dart';
import 'package:synclog/data/datasources/auth_local_datasource.dart';
import 'package:synclog/data/datasources/team_local_datasource.dart';
import 'package:synclog/data/repositories/team_repository_impl.dart';
import 'package:synclog/services/session.dart';

Future<({AuthController auth, TeamsController teams})> _wire() async {
  final prefs = await SharedPreferences.getInstance();
  final auth = AuthController(AuthLocalDataSource(prefs))..restore();
  final repo = TeamRepositoryImpl(local: TeamLocalDataSource(prefs));
  final teams = TeamsController(
    repo,
    currentUser: auth.currentUser ?? Session.local().currentUser,
  )..load();
  return (auth: auth, teams: teams);
}

void main() {
  testWidgets('signed-out users land on the login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final w = await _wire();

    await tester.pumpWidget(SyncLogApp(authController: w.auth, teamsController: w.teams));
    await tester.pumpAndSettle();

    expect(find.text('로그인'), findsWidgets);
    expect(find.text('합주 팀'), findsNothing);
  });

  testWidgets('signed-in users boot to the 합주 팀 home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final w = await _wire();
    await w.auth.signUp(name: '준호', email: 'me@synclog.app', password: 'secret1');

    await tester.pumpWidget(SyncLogApp(authController: w.auth, teamsController: w.teams));
    await tester.pumpAndSettle();

    expect(find.text('SyncLog'), findsOneWidget);
    expect(find.text('합주 팀'), findsOneWidget);
    expect(find.text('회전목마 합주단'), findsOneWidget);
  });
}
