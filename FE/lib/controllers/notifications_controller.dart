import 'package:flutter/foundation.dart';
import '../data/datasources/notifications_remote_datasource.dart';
import '../domain/entities/notification.dart';

/// The activity-feed store, surfaced in the drawer badge and the 알림 screen.
/// Notifications are inherently a server feature (they're about *other* people),
/// so in local-first mode this stays empty and the badge never shows.
class NotificationsController extends ChangeNotifier {
  final NotificationsRemoteDataSource? _remote;

  List<AppNotification> _items = const [];
  bool _loading = false;

  NotificationsController({NotificationsRemoteDataSource? remote}) : _remote = remote;

  List<AppNotification> get items => _items;
  bool get isLoading => _loading;
  bool get isRemote => _remote != null;
  int get unreadCount => _items.where((n) => !n.read).length;

  /// Pull the latest feed. Best-effort: keeps the current list on failure.
  Future<void> load() async {
    if (_remote == null) {
      _items = const [];
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      _items = await _remote.fetch();
    } catch (_) {
      // Keep whatever we had; the badge just won't update this round.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Mark every notification read (clears the badge), then refresh from server.
  Future<void> markAllRead() async {
    if (_remote == null || _items.isEmpty) return;
    try {
      _items = await _remote.markAllRead();
    } catch (_) {
      // Optimistically clear locally so the badge doesn't linger.
      _items = [for (final n in _items) _read(n)];
    }
    notifyListeners();
  }

  /// Drop the feed (on sign-out).
  void clear() {
    _items = const [];
    notifyListeners();
  }

  AppNotification _read(AppNotification n) => AppNotification(
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        teamId: n.teamId,
        teamName: n.teamName,
        actor: n.actor,
        read: true,
        createdAt: n.createdAt,
      );
}
