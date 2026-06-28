import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/sync_app_bar.dart';

/// 도움말 — a short, static FAQ explaining the record → micro-sync → stack flow.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      q: 'SyncLog는 어떤 앱인가요?',
      a: '합주 팀이 한 곡과 고정 템포를 정하고, 각자 메트로놈에 맞춰 자기 파트를 촬영해 '
          '하나의 멀티트랙 타임라인에 쌓아 올리는 비대면 합주 앱이에요.',
    ),
    (
      q: '파트는 어떻게 녹화하나요?',
      a: '팀 화면에서 ‘내 파트 녹화하기’를 누르면 메트로놈과 함께 촬영이 시작돼요. '
          '촬영이 끝나면 싱크 조절 화면에서 정박 대비 타이밍을 미세 조정한 뒤 올릴 수 있어요.',
    ),
    (
      q: '싱크(싱크 오프셋)는 무엇인가요?',
      a: '내 연주가 메트로놈 정박보다 얼마나 빠르거나 느린지를 ±0.0X초 단위로 맞추는 값이에요. '
          '0에 가까울수록 ‘In sync’로 표시되고, 합주 재생 시 자동으로 정렬돼요.',
    ),
    (
      q: '팀에 어떻게 초대하나요?',
      a: '팀 화면 오른쪽 위의 초대 버튼으로 초대 코드를 공유하세요. 받은 사람은 메뉴의 '
          '‘코드로 팀 참여’에서 코드를 입력하면 합류돼요.',
    ),
    (
      q: '연습 히스토리는 무엇인가요?',
      a: '새 take를 올릴 때마다 버전(v1.0, v1.1 …)과 한 줄 소감이 Git 히스토리처럼 쌓여요. '
          '팀이 어떻게 발전해 왔는지 한눈에 볼 수 있어요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SyncAppBar(
              left: SLIconButton(icon: SLIcons.arrowLeft, label: '뒤로', onTap: () => context.pop()),
              title: const Text('도움말'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(SL.gutter),
                children: [
                  Text('자주 묻는 질문',
                      style: SLType.sans(
                          size: SLType.xl2, weight: FontWeight.w700, letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  for (final f in _faqs) ...[
                    _FaqCard(question: f.q, answer: f.a),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: Text('문의: help@synclog.app',
                        style: SLType.sans(size: SLType.sm, color: SL.textPlaceholder)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqCard({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SL.surfaceCard,
        border: Border.all(color: SL.borderSoft),
        borderRadius: BorderRadius.circular(SL.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(SLIcons.helpCircle, size: 18, color: SL.rec),
              const SizedBox(width: 8),
              Expanded(
                child: Text(question,
                    style: SLType.sans(size: SLType.md, weight: FontWeight.w700, height: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(answer,
                style: SLType.sans(size: SLType.sm, color: SL.textSecondary, height: 1.6)),
          ),
        ],
      ),
    );
  }
}
