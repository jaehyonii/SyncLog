import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/recording_controller.dart';
import 'controllers/teams_controller.dart';
import 'domain/entities/recorded_take.dart';
import 'screens/archive_screen.dart';
import 'screens/browse_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/follow_list_screen.dart';
import 'screens/help_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/recording_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/sync_editor_screen.dart';
import 'screens/team_detail_screen.dart';
import 'services/metronome_audio.dart';
import 'services/permission_service.dart';
import 'services/recording_service.dart';

/// Arguments handed to the micro-sync editor after a take is recorded.
class SyncEditorArgs {
  final String teamId;
  final String trackId;
  final RecordedTake take;
  const SyncEditorArgs({required this.teamId, required this.trackId, required this.take});
}

/// App routes. The record → micro-sync → archive sub-flow lives under a team,
/// so committing a take returns cleanly to that team's detail screen.
///
/// Auth gates everything: [auth] drives a redirect that bounces signed-out
/// users to `/login` and keeps signed-in users out of the auth screens. The
/// router refreshes whenever [auth] notifies, so logging in/out re-evaluates
/// the redirect and moves the user automatically.
GoRouter buildRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      // Wait for the (synchronous) session restore before deciding.
      if (auth.status == AuthStatus.unknown) return null;
      final atAuthScreen =
          state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      if (!auth.isAuthenticated) return atAuthScreen ? null : '/login';
      if (atAuthScreen) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(path: 'feed', builder: (context, state) => const FeedScreen()),
          GoRoute(path: 'browse', builder: (context, state) => const BrowseScreen()),
          GoRoute(path: 'archive', builder: (context, state) => const ArchiveScreen()),
          GoRoute(
            path: 'users/:id',
            builder: (context, state) =>
                UserProfileScreen(userId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'followers',
                builder: (context, state) => FollowListScreen(
                    userId: state.pathParameters['id']!, showFollowers: true),
              ),
              GoRoute(
                path: 'following',
                builder: (context, state) => FollowListScreen(
                    userId: state.pathParameters['id']!, showFollowers: false),
              ),
            ],
          ),
          GoRoute(
              path: 'notifications',
              builder: (context, state) => const NotificationsScreen()),
          GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
          GoRoute(path: 'help', builder: (context, state) => const HelpScreen()),
          GoRoute(
            path: 'teams/:id',
            builder: (context, state) =>
                TeamDetailScreen(teamId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'record',
                builder: (context, state) {
                  final teamId = state.pathParameters['id']!;
                  final trackId = state.uri.queryParameters['trackId'];
                  final team = context.read<TeamsController>().teamById(teamId);
                  final bpm = team?.bpm ?? 90;
                  return ChangeNotifierProvider(
                    create: (ctx) => RecordingController(
                      service: RecordingService.platform(ctx.read<PermissionService>()),
                      audio: MetronomeAudio.silent(),
                      bpm: bpm,
                    )..initialize(),
                    child: RecordingScreen(teamId: teamId, trackId: trackId),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'sync',
                    builder: (context, state) {
                      final args = state.extra as SyncEditorArgs?;
                      if (args == null) return const NotFoundScreen();
                      return SyncEditorScreen(args: args);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
}
