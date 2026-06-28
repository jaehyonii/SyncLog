import 'dart:io';
import 'package:video_player/video_player.dart';

/// Build a player for a locally-recorded take file (mobile/desktop). Selected by
/// conditional import when `dart:io` is available.
VideoPlayerController createTakeController(String path) =>
    VideoPlayerController.file(File(path));
