import 'package:video_player/video_player.dart';

/// Web fallback: there is no `dart:io` file handle to play, so a freshly
/// recorded local take can't be previewed here. The recording flow on web uses
/// the fake camera (no file), so this is never reached in practice.
VideoPlayerController createTakeController(String path) =>
    throw UnsupportedError('이 플랫폼에서는 로컬 파일 미리보기를 지원하지 않아요.');
