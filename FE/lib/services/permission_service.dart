import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera + microphone permission gate. On platforms without a permission
/// plugin (web/desktop/tests) it resolves as granted so the flow proceeds.
abstract class PermissionService {
  Future<bool> ensureCameraAndMic();

  factory PermissionService.platform() {
    if (kIsWeb) return const _AlwaysGrantedPermissionService();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return const RealPermissionService();
      default:
        return const _AlwaysGrantedPermissionService();
    }
  }
}

class RealPermissionService implements PermissionService {
  const RealPermissionService();

  @override
  Future<bool> ensureCameraAndMic() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    return statuses.values.every((s) => s.isGranted);
  }
}

class _AlwaysGrantedPermissionService implements PermissionService {
  const _AlwaysGrantedPermissionService();

  @override
  Future<bool> ensureCameraAndMic() async => true;
}
