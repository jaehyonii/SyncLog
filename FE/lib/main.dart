import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/notifications_controller.dart';
import 'controllers/social_controller.dart';
import 'controllers/teams_controller.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/notifications_remote_datasource.dart';
import 'data/datasources/social_remote_datasource.dart';
import 'data/datasources/team_local_datasource.dart';
import 'data/datasources/team_remote_datasource.dart';
import 'data/repositories/team_repository_impl.dart';
import 'services/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---- Composition root: wire config → data sources → repository → state ----
  final config = AppConfig.fromEnvironment();
  final prefs = await SharedPreferences.getInstance();

  // Auth: when a backend is configured, sign-up/log-in hit the API and we cache
  // its JWT; otherwise auth is on-device. Restore any persisted session
  // synchronously so the first route is decided without a logged-out flash.
  final authController = AuthController(
    AuthLocalDataSource(prefs),
    remote: config.useRemote
        ? HttpAuthRemoteDataSource(baseUrl: config.apiBaseUrl)
        : null,
  )..restore();

  final local = TeamLocalDataSource(prefs);
  final remote = config.useRemote
      ? HttpTeamRemoteDataSource(
          baseUrl: config.apiBaseUrl,
          // Attach the signed-in user's bearer token to every team request.
          tokenProvider: () => authController.token,
        )
      : null;
  final repository = TeamRepositoryImpl(local: local, remote: remote);
  // Scope the store to the restored user (null → default local profile) before
  // the first load, so each account only ever sees its own teams.
  repository.setActiveUser(authController.currentUser?.id);

  // Until a user signs in, fall back to the default local profile (also keeps
  // seed data attribution stable); app.dart re-points this on login.
  final teamsController = TeamsController(
    repository,
    currentUser: authController.currentUser ?? Session.local().currentUser,
  )..load();

  // The activity feed is a server feature; in local-first mode it stays empty.
  final notificationsController = NotificationsController(
    remote: config.useRemote
        ? HttpNotificationsRemoteDataSource(
            baseUrl: config.apiBaseUrl,
            tokenProvider: () => authController.token,
          )
        : null,
  )..load();

  // The SNS feed/follow graph is likewise server-only.
  final socialController = SocialController(
    remote: config.useRemote
        ? HttpSocialRemoteDataSource(
            baseUrl: config.apiBaseUrl,
            tokenProvider: () => authController.token,
          )
        : null,
  )..loadHomeFeed();

  runApp(SyncLogApp(
    authController: authController,
    teamsController: teamsController,
    notificationsController: notificationsController,
    socialController: socialController,
  ));
}
