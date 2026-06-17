// Smoke test: the SyncLog app boots, loads seeded teams, and shows Home.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synclog/app.dart';
import 'package:synclog/controllers/teams_controller.dart';
import 'package:synclog/data/datasources/seed_data.dart';
import 'package:synclog/data/datasources/team_local_datasource.dart';
import 'package:synclog/data/repositories/team_repository_impl.dart';

void main() {
  testWidgets('boots to the 합주 팀 home screen with seeded teams', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = TeamRepositoryImpl(local: TeamLocalDataSource(prefs));
    final controller = TeamsController(repo, currentUser: SeedData.me)..load();

    await tester.pumpWidget(SyncLogApp(teamsController: controller));
    await tester.pumpAndSettle();

    expect(find.text('SyncLog'), findsOneWidget);
    expect(find.text('합주 팀'), findsOneWidget);
    expect(find.text('회전목마 합주단'), findsOneWidget);
  });
}
