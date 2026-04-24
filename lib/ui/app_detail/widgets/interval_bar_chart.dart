import 'dart:math' show max, min;

import 'package:collection/collection.dart';
import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:flutter/material.dart';

const double _chartHeight = 96.0;

// 1〜2本など少ないデータのときにバーが不格好に広がるのを防ぐ上限
const double _maxBarWidth = 80.0;
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
  });

  final List<int> intervals;
  final double averageInterval;
  final TaskColor taskColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _chartHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarChartPainter(
          intervals: intervals,
          averageInterval: averageInterval,
          baseColor: taskColor.baseColor(context),
          onColor: taskColor.onColor(context),
          softColor: taskColor.softColor(context),
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
  });

  final List<int> intervals;
  final double averageInterval;
  final Color baseColor;
  final Color onColor;
  final Color softColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (intervals.isEmpty) return;

    final count = intervals.length;
    final maxVal = intervals.reduce(max).toDouble();
    if (maxVal == 0) return;

    final chartHeight = size.height;

    // チャートを count 等分で配列
    final slotWidth = (size.width - _barHorizontalMargin * 2) / count;
    // バー幅: スロット内の余白を確保しつつでキャップ
    final barWidth = min(
      slotWidth - _minBarGap,
      _maxBarWidth,
    ).clamp(0.0, slotWidth);

    // ベースライン描画
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = baseColor.withValues(alpha: 0.2)
        ..strokeWidth = 1,
    );

    // バーを描画
    for (var i = 0; i < count; i++) {
      final ratio = intervals[i] / maxVal;
      final barHeight = ratio * chartHeight;
      if (barHeight <= 0) continue;

      final left = _barHorizontalMargin + i * slotWidth + (slotWidth - barWidth) / 2;
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
      canvas.drawLine(Offset(x, start.dy), Offset(segmentEndX, start.dy), linePaint);
      x += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      !ListEquality().equals(intervals, old.intervals) ||
      baseColor != old.baseColor ||
      softColor != old.softColor ||
      onColor != old.onColor ||
      averageInterval != old.averageInterval;
}
