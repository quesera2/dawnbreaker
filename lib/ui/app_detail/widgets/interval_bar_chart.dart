import 'dart:math' show max, min;

import 'package:collection/collection.dart';
import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:flutter/material.dart';

const double _barAreaHeight = 96.0;
const double _labelAreaHeight = 32.0;

// 1〜2本など少ないデータのときにバーが不格好に広がるのを防ぐ上限
const double _maxBarWidth = 32.0;
// バー間の最低間隔
const double _minBarGap = 8.0;
// バーの開始のマージン
const double _barHorizontalMargin = 8.0;

class IntervalBarChart extends StatelessWidget {
  const IntervalBarChart({
    super.key,
    required this.intervals,
    required this.averageInterval,
    required this.taskColor,
    this.barAreaHeight = _barAreaHeight,
  });

  final List<int> intervals;
  final double averageInterval;
  final TaskColor taskColor;
  final double barAreaHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return SizedBox(
      height: barAreaHeight + _labelAreaHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarChartPainter(
          intervals: intervals,
          averageInterval: averageInterval,
          baseColor: taskColor.baseColor(context),
          onColor: taskColor.onColor(context),
          softColor: taskColor.softColor(context),
          primaryColor: c.primary,
          primaryOnColor: c.primaryOn,
          dayUnit: context.l10n.appDetailStatsDay,
          barAreaHeight: barAreaHeight,
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.intervals,
    required this.averageInterval,
    required this.baseColor,
    required this.onColor,
    required this.softColor,
    required this.primaryColor,
    required this.primaryOnColor,
    required this.dayUnit,
    required this.barAreaHeight,
  });

  final List<int> intervals;
  final double averageInterval;
  final Color baseColor;
  final Color onColor;
  final Color softColor;
  final Color primaryColor;
  final Color primaryOnColor;
  final String dayUnit;
  final double barAreaHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (intervals.isEmpty) return;

    final count = intervals.length;
    final maxVal = intervals.reduce(max).toDouble();
    if (maxVal == 0) return;

    final chartHeight = barAreaHeight;

    final graphWidth = size.width - _barHorizontalMargin * 2;
    // 1本辺りに使える幅
    final unitWidth = min(_maxBarWidth + _minBarGap, graphWidth / count);
    final barWidth = (unitWidth - _minBarGap).clamp(0.0, _maxBarWidth);
    final startX = size.width - _barHorizontalMargin - (unitWidth * count);

    // ベースライン描画
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = baseColor.withValues(alpha: 0.2)
        ..strokeWidth = 1,
    );

    // バーを描画（intervals は新しい順なので逆から描画して左=古い順にする）
    for (var i = 0; i < count; i++) {
      final ratio = intervals[count - 1 - i] / maxVal;
      final barHeight = ratio * chartHeight;
      if (barHeight <= 0) continue;

      final left = startX + i * unitWidth + (unitWidth - barWidth) / 2;
      final top = size.height - barHeight;
      final opacity = count > 1 ? (0.25 + 0.35 * i / (count - 1)) : 0.6;
      final barPaint = Paint();

      canvas.drawRect(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        barPaint..color = baseColor.withValues(alpha: opacity),
      );
    }

    // アベレージボーダーを描画
    if (averageInterval > 0) {
      final avgRatio = averageInterval / maxVal;
      final avgY = size.height - avgRatio * chartHeight;
      _drawAverageLine(canvas, Offset(0, avgY), Offset(size.width, avgY));
    }

    // 最大値ラベルを描画
    _drawMaxLabel(
        canvas,
        size,
        maxVal.toInt(),
        count,
        unitWidth,
        barWidth,
        startX);
  }

  void _drawMaxLabel(Canvas canvas,
      Size size,
      int maxValue,
      int count,
      double slotWidth,
      double barWidth,
      double startX,) {
    // 最大値バーの描画インデックス（最新のものを選択）
    var maxDrawI = 0;
    for (var i = 0; i < count; i++) {
      if (intervals[count - 1 - i] == maxValue) {
        maxDrawI = i;
      }
    }

    final maxBarCenterX =
        startX + maxDrawI * slotWidth + (slotWidth - barWidth) / 2 +
            barWidth / 2;

    final tp = TextPainter(
      text: TextSpan(
        text: '$maxValue$dayUnit',
        style: AppTextStyle.overline.copyWith(color: primaryOnColor),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout();

    const hPad = 6.0;
    const vPad = 2.0;
    final badgeW = tp.width + hPad * 2;
    final badgeH = tp.height + vPad * 2;
    const labelCenterY = _labelAreaHeight / 2;

    // バッジがチャート端からはみ出さないようクランプ
    final centerX = maxBarCenterX.clamp(badgeW / 2, size.width - badgeW / 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, labelCenterY),
          width: badgeW,
          height: badgeH,
        ),
        const Radius.circular(AppRadius.xs),
      ),
      Paint()
        ..color = primaryColor,
    );

    tp.paint(
      canvas,
      Offset(centerX - tp.width / 2, labelCenterY - tp.height / 2),
    );
  }

  void _drawAverageLine(Canvas canvas, Offset start, Offset end) {
    const dashLen = 6.0;
    const gapLen = 4.0;

    final linePaint = Paint()
      ..color = onColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // グロー層: 連続ラインにして strokeWidth を太くすることでブラーが広がる
    // ダッシュ単位でブラーするとセグメント間が孤立してグロー感が出ない
    final glowPaint = Paint()
      ..color = softColor.withValues(alpha: 0.8)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawLine(start, end, glowPaint);

    // 点線はグロー層の上にシャープなラインとして描画
    double x = start.dx;
    while (x < end.dx) {
      final segmentEndX = (x + dashLen).clamp(start.dx, end.dx);
      canvas.drawLine(
        Offset(x, start.dy),
        Offset(segmentEndX, start.dy),
        linePaint,
      );
      x += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      !const ListEquality<int>().equals(intervals, old.intervals) ||
          baseColor != old.baseColor ||
          softColor != old.softColor ||
          onColor != old.onColor ||
          averageInterval != old.averageInterval ||
          primaryColor != old.primaryColor ||
          primaryOnColor != old.primaryOnColor ||
          dayUnit != old.dayUnit ||
          barAreaHeight != old.barAreaHeight;
}
