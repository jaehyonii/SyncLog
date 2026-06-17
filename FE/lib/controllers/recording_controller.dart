import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/entities/recorded_take.dart';
import '../services/metronome_audio.dart';
import '../services/recording_service.dart';

enum RecordingPhase { idle, countIn, recording }

/// Drives the recording studio: camera setup, the 3·2·1·Start! count-in, the
/// metronome (which only starts once recording begins), the elapsed timer, and
/// producing the final take. Holds no UI; the screen observes it.
class RecordingController extends ChangeNotifier {
  final RecordingService service;
  final MetronomeAudio _audio;
  final int bpm;

  RecordingController({
    required this.service,
    required MetronomeAudio audio,
    required this.bpm,
  }) : _audio = audio;

  RecordingPhase _phase = RecordingPhase.idle;
  int? _countIn; // 3/2/1, 0 == "Start!"
  int _beat = -1;
  int _elapsedSec = 0;
  bool _cameraReady = false;

  RecordingPhase get phase => _phase;
  int? get countIn => _countIn;
  int get beat => _beat;
  int get elapsedSec => _elapsedSec;
  bool get isRecording => _phase == RecordingPhase.recording;
  bool get isCameraReady => _cameraReady;

  int get _beatMs => (60000 / bpm).round();

  Timer? _countTimer;
  Timer? _beatTimer;
  Timer? _elapsedTimer;

  Future<void> initialize() async {
    await service.initialize();
    _cameraReady = service.isReady;
    notifyListeners();
  }

  /// Begin the count-in. The metronome stays idle until recording starts.
  void start() {
    if (_phase != RecordingPhase.idle) return;
    _phase = RecordingPhase.countIn;
    var n = 3;
    _countIn = 3;
    notifyListeners();
    _countTimer = Timer.periodic(Duration(milliseconds: _beatMs), (t) {
      n -= 1;
      if (n >= 1) {
        _countIn = n;
        _audio.tick();
      } else if (n == 0) {
        _countIn = 0; // "Start!"
        _audio.accent();
      } else {
        t.cancel();
        _beginRecording();
        return;
      }
      notifyListeners();
    });
  }

  void _beginRecording() {
    _countIn = null;
    _phase = RecordingPhase.recording;
    _elapsedSec = 0;
    _beat = 0;
    _audio.accent();
    service.start();
    notifyListeners();

    var b = 0;
    _beatTimer = Timer.periodic(Duration(milliseconds: _beatMs), (_) {
      b = (b + 1) % 4;
      _beat = b;
      b == 0 ? _audio.accent() : _audio.tick();
      notifyListeners();
    });
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSec += 1;
      notifyListeners();
    });
  }

  /// Discard the in-progress take (count-in included) and return to idle.
  Future<void> reset() async {
    _countTimer?.cancel();
    _beatTimer?.cancel();
    _elapsedTimer?.cancel();
    if (_phase == RecordingPhase.recording) {
      await service.stop(); // discard
    }
    _phase = RecordingPhase.idle;
    _countIn = null;
    _beat = -1;
    _elapsedSec = 0;
    notifyListeners();
  }

  /// Stop recording and produce the take for the micro-sync editor.
  Future<RecordedTake> stop() async {
    _beatTimer?.cancel();
    _elapsedTimer?.cancel();
    final result = await service.stop();
    _phase = RecordingPhase.idle;
    _beat = -1;
    notifyListeners();
    return RecordedTake(
      filePath: result.filePath,
      duration: result.duration,
      bpm: bpm,
    );
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    _beatTimer?.cancel();
    _elapsedTimer?.cancel();
    service.dispose();
    super.dispose();
  }
}
