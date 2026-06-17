import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'permission_service.dart';

/// Result of a single capture.
typedef CaptureResult = ({String? filePath, Duration duration});

/// Captures a video take of the player's part. The recording screen consumes
/// this through the interface, so it works identically whether a real camera is
/// present (mobile) or not (web/desktop/tests).
abstract class RecordingService {
  /// Request permissions and initialize the capture device. Safe to call once.
  Future<void> initialize();

  /// True once a real camera preview is live. When false, the screen shows its
  /// dark viewfinder placeholder and the rest of the flow still runs.
  bool get isReady;

  /// The live preview, or an empty box when no camera is available.
  Widget buildPreview();

  Future<void> start();
  Future<CaptureResult> stop();
  Future<void> dispose();

  /// Picks the real camera implementation on mobile, a no-camera fake elsewhere.
  factory RecordingService.platform(PermissionService permissions) {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return CameraRecordingService(permissions);
    }
    return FakeRecordingService();
  }
}

/// Real capture via the `camera` plugin (front camera, audio enabled).
class CameraRecordingService implements RecordingService {
  final PermissionService _permissions;
  CameraController? _controller;
  final Stopwatch _watch = Stopwatch();
  bool _ready = false;

  CameraRecordingService(this._permissions);

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    try {
      final granted = await _permissions.ensureCameraAndMic();
      if (!granted) return;
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await controller.initialize();
      _controller = controller;
      _ready = true;
    } catch (e) {
      // No usable camera — fall back to the placeholder preview.
      debugPrint('Camera init failed, using placeholder: $e');
      _ready = false;
    }
  }

  @override
  Widget buildPreview() {
    final c = _controller;
    if (_ready && c != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: c.value.previewSize?.height ?? 1,
            height: c.value.previewSize?.width ?? 1,
            child: CameraPreview(c),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Future<void> start() async {
    _watch
      ..reset()
      ..start();
    if (_ready && _controller != null && !_controller!.value.isRecordingVideo) {
      await _controller!.startVideoRecording();
    }
  }

  @override
  Future<CaptureResult> stop() async {
    _watch.stop();
    String? path;
    if (_ready && _controller != null && _controller!.value.isRecordingVideo) {
      final file = await _controller!.stopVideoRecording();
      path = file.path;
    }
    return (filePath: path, duration: _watch.elapsed);
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _ready = false;
  }
}

/// No-camera fallback: times the take and returns a path-less result, so the
/// micro-sync editor and upload flow work unchanged.
class FakeRecordingService implements RecordingService {
  final Stopwatch _watch = Stopwatch();

  @override
  bool get isReady => false;

  @override
  Future<void> initialize() async {}

  @override
  Widget buildPreview() => const SizedBox.shrink();

  @override
  Future<void> start() async {
    _watch
      ..reset()
      ..start();
  }

  @override
  Future<CaptureResult> stop() async {
    _watch.stop();
    return (filePath: null, duration: _watch.elapsed);
  }

  @override
  Future<void> dispose() async {}
}
