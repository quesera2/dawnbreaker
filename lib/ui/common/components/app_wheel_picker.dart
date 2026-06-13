import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// スクロールホイールピッカーのコンテナ。
/// [children] に [ListWheelScrollView] の列を並べる。
class AppWheelPicker extends StatelessWidget {
  const AppWheelPicker({super.key, required this.children});

  static const itemExtent = 52.0;
  static const height = 200.0;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Stack(
        children: [
          Positioned(
            top: (height - itemExtent) / 2,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: itemExtent,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: c.trackBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(children: children),
          ),
          _FadeEdge(color: c.bgSubtle, alignment: Alignment.topCenter),
          _FadeEdge(color: c.bgSubtle, alignment: Alignment.bottomCenter),
        ],
      ),
    );
  }
}

class _FadeEdge extends StatelessWidget {
  const _FadeEdge({required this.color, required this.alignment});

  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: alignment == Alignment.topCenter ? 0 : null,
      bottom: alignment == Alignment.bottomCenter ? 0 : null,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: alignment,
              end: alignment == Alignment.topCenter
                  ? Alignment.bottomCenter
                  : Alignment.topCenter,
              colors: [color, color.withAlpha(0)],
            ),
          ),
        ),
      ),
    );
  }
}

/// ホイールピッカーの各アイテムのテキストスタイルを返す。
TextStyle wheelItemTextStyle(AppColorScheme c, {required bool isSelected}) =>
    AppTextStyle.headline.copyWith(color: isSelected ? c.text : c.textMuted);

/// [ListWheelScrollView] の汎用ラッパー。
/// [items] からアイテムを生成し、選択中アイテムのスタイルを自動適用する。
class WheelColumn<T> extends StatelessWidget {
  const WheelColumn({
    super.key,
    required this.items,
    required this.selected,
    required this.controller,
    required this.labelOf,
    required this.onChanged,
    this.flex = 1,
  });

  final List<T> items;
  final T selected;
  final FixedExtentScrollController controller;
  final String Function(T item) labelOf;
  final ValueChanged<T> onChanged;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return Expanded(
      flex: flex,
      child: ListWheelScrollView(
        controller: controller,
        itemExtent: AppWheelPicker.itemExtent,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (i) {
          HapticFeedback.selectionClick();
          onChanged(items[i]);
        },
        children: items.map((item) {
          return Center(
            child: Text(
              labelOf(item),
              style: wheelItemTextStyle(c, isSelected: item == selected),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 0〜[count)-1 の整数をスクロール選択するホイール列。
class WheelIntColumn extends StatelessWidget {
  const WheelIntColumn({
    super.key,
    required this.count,
    required this.selected,
    required this.controller,
    required this.onChanged,
    this.labelOf,
    this.flex = 1,
  });

  final int count;
  final int selected;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;
  final String Function(int)? labelOf;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return Expanded(
      flex: flex,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: AppWheelPicker.itemExtent,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (i) {
          HapticFeedback.selectionClick();
          onChanged(i);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, i) => Center(
            child: Text(
              labelOf != null ? labelOf!(i) : '$i',
              style: wheelItemTextStyle(c, isSelected: i == selected),
            ),
          ),
        ),
      ),
    );
  }
}
