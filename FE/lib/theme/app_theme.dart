import 'package:flutter/material.dart';
import 'tokens.dart';

/// The app's Material theme, anchored to the SyncLog tokens. Most surfaces are
/// hand-built widgets that read tokens directly; this provides sensible
/// defaults (selection color, splash suppression, dialog/sheet surfaces).
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: SL.paper,
    canvasColor: SL.paper,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: SL.rec,
      primary: SL.ink,
      surface: SL.paper,
      error: SL.rec,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: SL.rec,
      selectionColor: SL.recSoft,
      selectionHandleColor: SL.rec,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SL.ink,
      contentTextStyle: SLType.sans(color: SL.textOnInk),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
