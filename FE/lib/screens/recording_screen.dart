import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/recording_controller.dart';
import '../router.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../util/time_format.dart';
import '../widgets/beat_dots.dart';
import '../widgets/pressable.dart';
import '../widgets/sync_app_bar.dart';

/// 3. RECORDING STUDIO. A dark self-camera stage (real camera preview when
/// available, a viewfinder placeholder otherwise), a read-only BPM chip, a
/// metronome that stays idle until recording begins, a 3·2·1·Start! count-in,
/// and the red record→stop control.
class RecordingScreen extends StatelessWidget {
  final String teamId;
  final String? trackId;

  const RecordingScreen({super.key, required this.teamId, this.trackId});

  Future<void> _stop(BuildContext context, RecordingController c) async {
    final take = await c.stop();
    if (!context.mounted) return;
    context.push(
      '/teams/$teamId/record/sync',
      extra: SyncEditorArgs(
        teamId: teamId,
        trackId: trackId ?? 'open',
        take: take,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RecordingController>();

    return Scaffold(
      backgroundColor: SL.dark1,
      body: Stack(
        children: [
          // dark camera stage vignette
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.16),
                  radius: 0.95,
                  colors: [Color(0xFF20231F), Color(0xFF14150F), Color(0xFF0C0D09)],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // real camera preview if ready, else the ghost placeholder
          if (c.isCameraReady)
            Positioned.fill(child: c.service.buildPreview())
          else
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(SLIcons.userRound,
                      size: 130, color: const Color(0xFFF4F3EF).withValues(alpha: 0.09)),
                  const SizedBox(height: 14),
                  Text('셀프 카메라',
                      style: SLType.sans(
                          size: 12,
                          color: const Color(0xFFF4F3EF).withValues(alpha: 0.26),
                          letterSpacing: 1.6)),
                ],
              ),
            ),
          const Positioned.fill(
            child: Padding(padding: EdgeInsets.all(18), child: _ViewfinderCorners()),
          ),
          // chrome
          SafeArea(
            child: Column(
              children: [
                SyncAppBar(
                  dark: true,
                  transparent: true,
                  title: const Text('동영상 촬영'),
                  left: SLIconButton(
                      icon: SLIcons.close,
                      label: '닫기',
                      color: SL.textOnDark,
                      onTap: () => context.pop()),
                  right: SLIconButton(
                      icon: SLIcons.rotateCcw,
                      label: '촬영 초기화',
                      color: SL.textOnDark,
                      onTap: c.reset),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: SL.dark2,
                    borderRadius: BorderRadius.circular(SL.radiusPill),
                    border: Border.all(color: SL.dark3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(SLIcons.music, size: 16, color: SL.textOnDarkDim),
                      const SizedBox(width: 10),
                      Text('${c.bpm}',
                          style: SLType.mono(size: 18, weight: FontWeight.w700, color: SL.textOnDark)),
                      const SizedBox(width: 6),
                      Text('BPM',
                          style: SLType.sans(size: SLType.xs, color: SL.textOnDarkDim, letterSpacing: 1.6)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                BeatDots(count: 4, active: c.beat),
                const Spacer(),
                if (c.isRecording)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _RecPulse(),
                        const SizedBox(width: 8),
                        Text(fmtTime(c.elapsedSec),
                            style: SLType.mono(size: 16, weight: FontWeight.w700, color: SL.textOnDark)),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 44),
                  child: c.isRecording
                      ? _ControlButton.stop(onTap: () => _stop(context, c))
                      : _ControlButton.record(
                          enabled: c.phase == RecordingPhase.idle,
                          onTap: c.start,
                        ),
                ),
              ],
            ),
          ),
          if (c.countIn != null)
            Positioned.fill(child: _CountIn(value: c.countIn!)),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final bool isStop;
  final bool enabled;
  final VoidCallback onTap;

  const _ControlButton._({required this.isStop, required this.enabled, required this.onTap});

  factory _ControlButton.record({required bool enabled, required VoidCallback onTap}) =>
      _ControlButton._(isStop: false, enabled: enabled, onTap: onTap);
  factory _ControlButton.stop({required VoidCallback onTap}) =>
      _ControlButton._(isStop: true, enabled: true, onTap: onTap);

  @override
  Widget build(BuildContext context) {
    final inner = isStop
        ? Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: SL.rec, borderRadius: BorderRadius.circular(7)),
          )
        : Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: SL.rec, shape: BoxShape.circle),
          );
    return Pressable(
      onTap: enabled ? onTap : null,
      semanticLabel: isStop ? '녹화 중지' : '녹화 시작',
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          width: SL.recordBtn,
          height: SL.recordBtn,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: inner,
        ),
      ),
    );
  }
}

class _CountIn extends StatelessWidget {
  final int value;
  const _CountIn({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SL.overlayCountIn,
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(value),
        tween: Tween(begin: 0.6, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: SL.easeOut,
        builder: (context, v, child) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.8 + v * 0.4, child: child),
        ),
        child: Text(
          value == 0 ? 'Start!' : '$value',
          style: SLType.mono(
            size: value == 0 ? 56 : SLType.display,
            weight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}

class _RecPulse extends StatefulWidget {
  const _RecPulse();
  @override
  State<_RecPulse> createState() => _RecPulseState();
}

class _RecPulseState extends State<_RecPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_ctrl),
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(color: SL.rec, shape: BoxShape.circle),
      ),
    );
  }
}

class _ViewfinderCorners extends StatelessWidget {
  const _ViewfinderCorners();

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.28);
    return Stack(
      children: [
        Positioned(top: 0, left: 0, child: _corner(color, top: true, left: true)),
        Positioned(top: 0, right: 0, child: _corner(color, top: true, left: false)),
        Positioned(bottom: 0, left: 0, child: _corner(color, top: false, left: true)),
        Positioned(bottom: 0, right: 0, child: _corner(color, top: false, left: false)),
      ],
    );
  }

  Widget _corner(Color color, {required bool top, required bool left}) {
    const w = 2.0;
    final side = BorderSide(color: color, width: w);
    return SizedBox(
      width: 22,
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top ? side : BorderSide.none,
            bottom: !top ? side : BorderSide.none,
            left: left ? side : BorderSide.none,
            right: !left ? side : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
