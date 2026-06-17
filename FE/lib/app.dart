import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'controllers/teams_controller.dart';
import 'router.dart';
import 'services/permission_service.dart';
import 'theme/app_theme.dart';

/// SyncLog — an async ensemble-recording app. A team picks one target song and
/// a fixed tempo; each member films their part to a metronome, micro-tunes how
/// their take sits against the beat, and stacks it onto a shared multitrack
/// timeline that grows like a Git history.
class SyncLogApp extends StatefulWidget {
  final TeamsController teamsController;

  const SyncLogApp({super.key, required this.teamsController});

  @override
  State<SyncLogApp> createState() => _SyncLogAppState();
}

class _SyncLogAppState extends State<SyncLogApp> {
  late final _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return MultiProvider(
      providers: [
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
