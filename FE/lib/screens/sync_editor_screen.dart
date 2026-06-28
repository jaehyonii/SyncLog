import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../controllers/teams_controller.dart';
import '../domain/entities/recorded_take.dart';
import '../router.dart';
import '../services/take_player_stub.dart'
    if (dart.library.io) '../services/take_player_io.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/pressable.dart';
import '../widgets/sync_app_bar.dart';
import '../widgets/sync_button.dart';
import '../widgets/sync_tag.dart';
import '../widgets/waveform.dart';

/// 4. MICRO-SYNC EDITOR. The recorded take preview, a waveform, and a micro-sync
/// slider showing a live ±0.0Xs offset (turns green "In sync" near zero), plus
/// an optional practice note. 이 로그로 업데이트 uploads via the repository,
/// fills the slot and appends a versioned commit.
class SyncEditorScreen extends StatefulWidget {
  final SyncEditorArgs args;
  const SyncEditorScreen({super.key, required this.args});

  @override
  State<SyncEditorScreen> createState() => _SyncEditorScreenState();
}

class _SyncEditorScreenState extends State<SyncEditorScreen> {
  int _offsetMs = 20;
  final _note = TextEditingController();
  bool _uploading = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _inSync => _offsetMs.abs() <= 10;
  String get _label {
    final sign = _offsetMs > 0 ? '+' : '';
    return '$sign${(_offsetMs / 1000).toStringAsFixed(2)}s';
  }

  void _nudge(int delta) => setState(() => _offsetMs = (_offsetMs + delta).clamp(-300, 300));

  Future<void> _confirm() async {
    if (_uploading) return;
    final teams = context.read<TeamsController>();
    final messenger = ScaffoldMessenger.of(context);

    // Resolve the target slot (falls back to the first open one).
    final team = teams.teamById(widget.args.teamId);
    var trackId = widget.args.trackId;
    if (team != null && team.trackById(trackId) == null) {
      trackId = team.firstOpenTrack?.id ?? trackId;
    }

    setState(() => _uploading = true);
    try {
      await teams.uploadTake(
        teamId: widget.args.teamId,
        trackId: trackId,
        take: widget.args.take,
        syncOffsetMs: _offsetMs,
        note: _note.text,
      );
      if (!mounted) return;
      context.go('/teams/${widget.args.teamId}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      messenger.showSnackBar(const SnackBar(content: Text('업로드에 실패했어요. 다시 시도해 주세요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SyncAppBar(
              left: SLIconButton(icon: SLIcons.close, label: '취소', onTap: () => context.pop()),
              title: const Text('싱크 조절'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(SL.gutter),
                children: [
                  _TakePreview(take: widget.args.take),
                  const SizedBox(height: 22),
                  _offsetReadout(),
                  const SizedBox(height: 22),
                  _waveformBlock(),
                  const SizedBox(height: 22),
                  _slider(),
                  const SizedBox(height: 22),
                  _noteField(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(SL.gutter, 12, SL.gutter, 30),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: SL.borderSoft))),
              child: SyncButton(
                label: _uploading ? '올리는 중…' : '이 로그로 업데이트',
                variant: SLButtonVariant.primary,
                size: SLButtonSize.lg,
                fullWidth: true,
                icon: SLIcons.upload,
                onTap: _uploading ? null : _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offsetReadout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('메트로놈 정박 대비', style: SLType.sans(size: SLType.sm, color: SL.textSecondary)),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(_label,
                    style: SLType.mono(
                        size: SLType.xl3,
                        weight: FontWeight.w700,
                        color: _inSync ? SL.success : SL.textPrimary,
                        letterSpacing: -0.8)),
                if (_inSync) ...[
                  const SizedBox(width: 8),
                  SyncTag('In sync',
                      tone: SLTagTone.neutral,
                      colorOverride: SL.success,
                      bgOverride: SL.success.withValues(alpha: 0.12)),
                ],
              ],
            ),
          ],
        ),
        Icon(SLIcons.gitCommit, size: 26, color: SL.textPlaceholder),
      ],
    );
  }

  Widget _waveformBlock() {
    return Column(
      children: [
        Waveform(progress: (0.5 + _offsetMs / 600).clamp(0.0, 1.0)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('-0.30s', style: SLType.mono(size: SLType.xs, color: SL.textPlaceholder)),
            Text('정박', style: SLType.mono(size: SLType.xs, color: SL.textPlaceholder)),
            Text('+0.30s', style: SLType.mono(size: SLType.xs, color: SL.textPlaceholder)),
          ],
        ),
      ],
    );
  }

  Widget _slider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: SL.rec,
            inactiveTrackColor: SL.waveformTrack,
            thumbColor: SL.rec,
            overlayColor: SL.rec.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            min: -300,
            max: 300,
            divisions: 60,
            value: _offsetMs.toDouble(),
            onChanged: (v) => setState(() => _offsetMs = v.round()),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SyncButton(
              label: '당기기',
              variant: SLButtonVariant.soft,
              size: SLButtonSize.sm,
              icon: SLIcons.chevronLeft,
              onTap: () => _nudge(-10),
            ),
            const SizedBox(width: 10),
            SyncButton(
              label: '밀기',
              variant: SLButtonVariant.soft,
              size: SLButtonSize.sm,
              iconRight: SLIcons.chevronRight,
              onTap: () => _nudge(10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _noteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('연습 소감 (선택)',
            style: SLType.sans(size: SLType.sm, weight: FontWeight.w500, color: SL.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: SL.surfaceCard,
            border: Border.all(color: SL.border),
            borderRadius: BorderRadius.circular(SL.radiusSm),
          ),
          child: TextField(
            controller: _note,
            minLines: 1,
            maxLines: 3,
            cursorColor: SL.rec,
            style: SLType.sans(size: SLType.md, color: SL.textPrimary),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: '예: 킥 살짝 당겨서 다시 떴어요',
              hintStyle: SLType.sans(size: SLType.md, color: SL.textPlaceholder),
            ),
          ),
        ),
      ],
    );
  }
}

/// The recorded take's square preview. Plays the local capture on tap (real
/// camera takes on mobile); on platforms with no file handle it keeps the dark
/// placeholder and explains why playback isn't available.
class _TakePreview extends StatefulWidget {
  final RecordedTake take;
  const _TakePreview({required this.take});

  @override
  State<_TakePreview> createState() => _TakePreviewState();
}

class _TakePreviewState extends State<_TakePreview> {
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _failed = false;

  /// A real, file-backed take we can actually play (mobile capture).
  bool get _playable =>
      !kIsWeb && widget.take.isReal && widget.take.filePath != null && !_failed;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!_playable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 환경에서는 촬영본 미리보기를 지원하지 않아요.')),
      );
      return;
    }

    // Lazily create + initialize the controller on first play.
    if (_controller == null) {
      setState(() => _initializing = true);
      try {
        final c = createTakeController(widget.take.filePath!);
        await c.initialize();
        await c.setLooping(true);
        if (!mounted) {
          await c.dispose();
          return;
        }
        c.addListener(_onTick);
        setState(() {
          _controller = c;
          _initializing = false;
        });
        await c.play();
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _failed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('촬영본을 재생하지 못했어요.')),
        );
      }
      return;
    }

    final c = _controller!;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    if (mounted) setState(() {});
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final isPlaying = c?.value.isPlaying ?? false;
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SL.radiusMd),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 0.85,
                    colors: [Color(0xFF26231F), Color(0xFF131210)],
                  ),
                ),
              ),
            ),
            if (c != null && c.value.isInitialized)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: c.value.size.width,
                    height: c.value.size.height,
                    child: VideoPlayer(c),
                  ),
                ),
              )
            else
              Center(
                child: Icon(SLIcons.piano,
                    size: 64, color: const Color(0xFFF4F3EF).withValues(alpha: 0.12)),
              ),
            Positioned(
              left: 12,
              top: 12,
              child: SyncTag(
                widget.take.isReal ? '내 촬영본' : '내 파트',
                tone: SLTagTone.onDark,
              ),
            ),
            // Hide the big play button while actively playing; tap the frame to pause.
            Positioned.fill(
              child: Pressable(
                onTap: _toggle,
                semanticLabel: isPlaying ? '일시정지' : '재생',
                child: Center(
                  child: isPlaying
                      ? const SizedBox.shrink()
                      : Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          child: _initializing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4, color: SL.ink),
                                )
                              : const Icon(SLIcons.play, size: 28, color: SL.ink),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
