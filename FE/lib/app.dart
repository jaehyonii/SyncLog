import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/teams_controller.dart';
import 'router.dart';
import 'services/permission_service.dart';
import 'theme/app_theme.dart';

/// SyncLog — an async ensemble-recording app. A team picks one target song and
/// a fixed tempo; each member films their part to a metronome, micro-tunes how
/// their take sits against the beat, and stacks it onto a shared multitrack
/// timeline that grows like a Git history.
class SyncLogApp extends StatefulWidget {
  final AuthController authController;
  final TeamsController teamsController;

  const SyncLogApp({
    super.key,
    required this.authController,
    required this.teamsController,
  });

  @override
  State<SyncLogApp> createState() => _SyncLogAppState();
}

class _SyncLogAppState extends State<SyncLogApp> {
  late final _router = buildRouter(widget.authController);

  // Tracks who the team store is currently pointed at, so we only react to an
  // actual change of signed-in user (not every auth notification).
  late String? _lastUserId = widget.authController.currentUser?.id;

  @override
  void initState() {
    super.initState();
    // main() already pointed the team store at the restored user and called
    // load(); from here on, react only when the signed-in user changes.
    widget.authController.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final user = widget.authController.currentUser;
    if (user == null) {
      _lastUserId = null; // signed out
      return;
    }
    if (user.id == _lastUserId) return;
    _lastUserId = user.id;
    // Attribute teams/takes to the new user, and refetch their teams (in remote
    // mode this pulls the signed-in user's teams from the server).
    widget.teamsController.setCurrentUser(user);
    widget.teamsController.load();
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: widget.authController),
        ChangeNotifierProvider<TeamsController>.value(value: widget.teamsController),
        Provider<PermissionService>.value(value: PermissionService.platform()),
      ],
      child: MaterialApp.router(
        title: 'SyncLog',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: _router,
      ),
    );
  }
}
