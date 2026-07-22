import 'dart:async';

import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:flutter/material.dart';

/// 予定日に通知が届く様子を見せるイラスト。
///
/// アカウント作成後の通知誘導画面で使う。
class NotificationPreviewAnimation extends StatefulWidget {
  const NotificationPreviewAnimation({super.key});

  @override
  State<NotificationPreviewAnimation> createState() =>
      _NotificationPreviewAnimationState();
}

class _NotificationPreviewAnimationState
    extends State<NotificationPreviewAnimation>
    with SingleTickerProviderStateMixin {
  static const _iconSize = 72.0;
  static const _iconRadius = _iconSize / 2;
  static const _iconCenter = Offset(100, 90);
  static const _rippleCount = 3;
  static const _period = 1.0 / _rippleCount;
  static const _scaleUpTime = _period * 0.18;
  static const _pulseWindow = _period * 0.9;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return SizedBox(
      width: 280,
      height: 240,
      child: AnimatedBuilder(
        animation: _controller,
        child: const _NotificationCard(iconEmoji: '🪥'),
        builder: (context, card) {
          final t = _controller.value;

          // 波紋は 1/3 サイクルごとに発火 → アイコン・通知カードを振動させる
          double iconScale = 1.0;
          double cardScale = 1.0;
          bool isScalingUp = false;
          for (int i = 0; i < _rippleCount; i++) {
            final localT = (t - i / _rippleCount + 1.0) % 1.0;
            if (localT < _pulseWindow) {
              isScalingUp = localT < _scaleUpTime;
              iconScale = _pulseScale(localT, amplitude: 0.24);
            }
            // 通知カードはディレイを入れる
            final cardLocalT = localT - _period * 0.06;
            if (cardLocalT > 0 && cardLocalT < _period * 0.75) {
              cardScale = _pulseScale(cardLocalT, amplitude: 0.1);
            }
          }

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // 波紋
              CustomPaint(
                size: const Size(280, 240),
                painter: _RipplePainter(
                  color: c.primary,
                  progress: t,
                  center: _iconCenter,
                  startRadius: _iconRadius + 4,
                  maxRadius: 190,
                  count: _rippleCount,
                ),
              ),
              // 通知アイコン
              Positioned(
                left: _iconCenter.dx - _iconRadius,
                top: _iconCenter.dy - _iconRadius,
                child: Transform.scale(
                  scale: iconScale,
                  child: Container(
                    width: _iconSize,
                    height: _iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primary,
                    ),
                    child: Icon(
                      isScalingUp
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_outlined,
                      color: c.primaryOn,
                      size: 40,
                    ),
                  ),
                ),
              ),
              // 通知カード（常時表示・パルスあり）
              Positioned(
                right: 0,
                bottom: 0,
                child: Transform.scale(
                  scale: cardScale,
                  alignment: Alignment.center,
                  child: card,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 心拍風のスケーリングを行う
  static double _pulseScale(double localT, {required double amplitude}) {
    if (localT < _scaleUpTime) {
      final p = localT / _scaleUpTime;
      return 1.0 + p * p * amplitude;
    }
    if (localT < _pulseWindow) {
      final p = (localT - _scaleUpTime) / (_pulseWindow - _scaleUpTime);
      return (1.0 + amplitude) - (1.0 - (1.0 - p) * (1.0 - p)) * amplitude;
    }
    return 1.0;
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.iconEmoji});

  final String iconEmoji;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return Card(
      color: c.surface,
      elevation: 3,
      child: SizedBox(
        width: 200,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(iconEmoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.notificationIntroPreviewTaskName,
                      style: AppTextStyle.caption.copyWith(
                        color: c.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      context.l10n.notificationIntroPreviewBody,
                      style: AppTextStyle.caption.copyWith(color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter({
    required this.color,
    required this.progress,
    required this.center,
    required this.startRadius,
    required this.maxRadius,
    required this.count,
  });

  final Color color;
  final double progress;
  final Offset center;
  final double startRadius;
  final double maxRadius;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final p = (progress + i / count) % 1.0;
      // アイコン pulse に追従するよう少し遅らせて展開開始
      if (p < 0.025) continue;
      final expand = (p - 0.025) / 0.985;
      final radius = startRadius + expand * (maxRadius - startRadius);
      final opacity = (1.0 - expand) * 0.45;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.color != color;
}
