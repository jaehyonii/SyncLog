import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SyncLog design tokens — a 1:1 port of the design system's CSS custom
/// properties (tokens/colors.css, typography.css, spacing.css, effects.css).
///
/// The system is a calm, warm off-white "score sheet" for the app chrome, a
/// near-black stage wherever the camera or video lives, and ONE signature
/// record-red that only ever means live / record / active beat / active tab.
class SL {
  SL._();

  // ---- Brand / signature ----
  static const rec = Color(0xFFE23A2E); // record red
  static const recPressed = Color(0xFFC22C20);
  static const recSoft = Color(0xFFFBE7E4);
  static const ink = Color(0xFF1A1714); // warm near-black
  static const inkPressed = Color(0xFF000000);
  static const paper = Color(0xFFF6F5F1); // off-white score sheet
  static const paper2 = Color(0xFFEFECE5);

  // ---- Neutrals (warm gray ramp) ----
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const gray50 = Color(0xFFFAF9F6);
  static const gray100 = Color(0xFFF0EEE9);
  static const gray200 = Color(0xFFE6E3DC);
  static const gray300 = Color(0xFFD8D4CB);
  static const gray400 = Color(0xFFB7B2A8);
  static const gray500 = Color(0xFF8C8A85);
  static const gray600 = Color(0xFF6D6B66);

  // ---- Dark stage ramp (camera / video grid) ----
  static const dark0 = Color(0xFF100F0E);
  static const dark1 = Color(0xFF181715);
  static const dark2 = Color(0xFF232220);
  static const dark3 = Color(0xFF34322E);

  // ---- Semantic: surfaces ----
  static const bgApp = paper;
  static const surfaceCard = white;
  static const surfaceMuted = gray100;

  // ---- Semantic: text ----
  static const textPrimary = Color(0xFF1A1714);
  static const textSecondary = gray500;
  static const textPlaceholder = gray400;
  static const textOnInk = paper;
  static const textOnRec = white;
  static const textOnDark = Color(0xFFF4F3EF);
  static final textOnDarkDim = const Color(0xFFF4F3EF).withValues(alpha: 0.55);

  // ---- Lines & accents ----
  static const border = gray300;
  static const borderSoft = gray200;
  static final borderDark = Colors.white.withValues(alpha: 0.12);
  static const success = Color(0xFF2F9E6F); // "in sync" confirmation
  static const waveformTrack = gray300;

  // ---- Overlays ----
  static final overlay = const Color(0xFF100F0E).withValues(alpha: 0.55);
  static final overlayCountIn = const Color(0xFF100F0E).withValues(alpha: 0.32);
  static final scrimLabel = const Color(0xFF14120F).withValues(alpha: 0.82);

  // ---- Spacing scale (px) ----
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 20.0; // page gutter — the dominant rhythm
  static const space6 = 24.0;
  static const space7 = 32.0;
  static const space8 = 40.0;
  static const gutter = space5;

  // ---- Radii ----
  static const radiusXs = 8.0; // tags, small chips, part labels
  static const radiusSm = 12.0; // buttons, inputs, BPM stepper
  static const radiusMd = 18.0; // cards, video cells
  static const radiusLg = 24.0; // bottom sheets
  static const radiusPill = 999.0;

  // ---- Layout constants ----
  static const headerHeight = 56.0;
  static const navbarHeight = 84.0;
  static const fabSize = 56.0;
  static const recordBtn = 76.0;

  // ---- Shadows ----
  static List<BoxShadow> get shadowCard => [
        BoxShadow(
          color: const Color(0xFF1A1714).withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];
  static List<BoxShadow> get shadowFab => [
        BoxShadow(
          color: const Color(0xFF1A1714).withValues(alpha: 0.20),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // ---- Motion ----
  static const durationFast = Duration(milliseconds: 120);
  static const durationBase = Duration(milliseconds: 200);
  static const durationSlow = Duration(milliseconds: 320);
  static const easeStandard = Cubic(0.4, 0, 0.2, 1);
  static const easeOut = Cubic(0.16, 1, 0.3, 1);
  static const easeBeat = Cubic(0.2, 0, 0, 1);
}

/// Brand type. One family does the talking (Spoqa Han Sans Neo → Noto Sans KR
/// substitute); JetBrains Mono is reserved for live numerics so tabular
/// figures keep the layout from twitching while a value ticks.
class SLType {
  SLType._();

  static TextStyle sans({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color color = SL.textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.notoSansKr(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color color = SL.textPrimary,
    double? letterSpacing,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Size scale
  static const xs = 11.0;
  static const sm = 13.0;
  static const base = 15.0;
  static const md = 16.0;
  static const lg = 18.0;
  static const xl = 20.0;
  static const xl2 = 28.0;
  static const xl3 = 40.0;
  static const display = 72.0;
}
