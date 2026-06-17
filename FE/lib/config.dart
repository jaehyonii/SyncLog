/// App-wide configuration. In production these come from `--dart-define`
/// (e.g. `flutter build --dart-define=API_BASE_URL=https://api.synclog.app`).
///
/// SyncLog runs **local-first**: the local store is the source of truth and the
/// app is fully usable offline. When [useRemote] is enabled, the repository
/// also talks to the REST API described in the product spec (GET /api/v1/teams,
/// GET /api/v1/teams/{id}/stream, POST /api/v1/teams/{id}/record).
class AppConfig {
  final String apiBaseUrl;
  final bool useRemote;

  const AppConfig({
    required this.apiBaseUrl,
    required this.useRemote,
  });

  factory AppConfig.fromEnvironment() {
    const base = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.synclog.app',
    );
    // Defaults to false: there is no live server yet, so the app stays
    // local-first. Flip to true (or pass --dart-define=USE_REMOTE=true) once a
    // backend is available.
    const useRemote = bool.fromEnvironment('USE_REMOTE', defaultValue: false);
    return const AppConfig(apiBaseUrl: base, useRemote: useRemote);
  }
}
