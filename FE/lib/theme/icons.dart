import 'package:flutter/material.dart';

/// Lucide → Material icon substitution.
///
/// The design system draws Lucide line icons; the production app is Flutter, so
/// these map each Lucide glyph used in the kit to its nearest Material icon.
/// Swap in the real Flutter glyph set for pixel-exact icons.
class SLIcons {
  SLIcons._();

  // chrome / nav
  static const menu = Icons.menu;
  static const arrowLeft = Icons.arrow_back;
  static const moreVertical = Icons.more_vert;
  static const close = Icons.close;
  static const rotateCcw = Icons.refresh; // 촬영 초기화
  static const plus = Icons.add;
  static const minus = Icons.remove;
  static const check = Icons.check;
  static const link = Icons.link;
  static const copy = Icons.content_copy;
  static const upload = Icons.file_upload_outlined;
  static const chevronLeft = Icons.chevron_left;
  static const chevronRight = Icons.chevron_right;

  // transport
  static const play = Icons.play_arrow_rounded;
  static const pause = Icons.pause_rounded;
  static const skipBack = Icons.skip_previous_rounded;
  static const skipForward = Icons.skip_next_rounded;

  // content
  static const disc3 = Icons.album_outlined; // team cover
  static const target = Icons.adjust; // tracking song
  static const music = Icons.music_note;
  static const circle = Icons.circle;
  static const circlePlus = Icons.add_circle_outline;
  static const userRound = Icons.person_outline; // self-camera ghost
  static const gitCommit = Icons.commit;

  // instrument glyphs (track labels) — Material lacks drum/guitar, substitute
  static const drum = Icons.album_outlined;
  static const guitar = Icons.music_note_outlined;
  static const piano = Icons.piano;
  static const audioLines = Icons.graphic_eq;

  // auth / forms
  static const mail = Icons.mail_outline;
  static const lock = Icons.lock_outline;
  static const eye = Icons.visibility_outlined;
  static const eyeOff = Icons.visibility_off_outlined;

  // drawer
  static const listMusic = Icons.queue_music;
  static const archive = Icons.archive_outlined;
  static const bell = Icons.notifications_none;
  static const userPlus = Icons.person_add_alt;
  static const settings = Icons.settings_outlined;
  static const helpCircle = Icons.help_outline;
  static const logOut = Icons.logout;

  /// Resolve an instrument glyph name (from track data) to its icon.
  static IconData instrument(String name) {
    switch (name) {
      case 'drum':
        return drum;
      case 'guitar':
        return guitar;
      case 'piano':
        return piano;
      case 'audio-lines':
        return audioLines;
      default:
        return music;
    }
  }
}
