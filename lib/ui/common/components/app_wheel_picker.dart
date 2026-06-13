import 'dart:async';

import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
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
/// スクロールコントローラーは内部で管理する。
class WheelColumn<T> extends StatefulWidget {
  const WheelColumn({
    super.key,
    required this.items,
    required this.initialSelected,
    required this.labelOf,
    required this.onChanged,
    this.flex = 1,
  });

  /// 0〜[count)-1 の整数列を生成するコンストラクタ。
  static WheelColumn<int> integers({
    Key? key,
    required int count,
    required int initialSelected,
    required ValueChanged<int> onChanged,
    String Function(int)? labelOf,
    int flex = 1,
  }) => WheelColumn<int>(
    key: key,
    items: List.generate(count, (i) => i),
    initialSelected: initialSelected,
    labelOf: labelOf ?? (i) => '$i',
    onChanged: onChanged,
    flex: flex,
  );

  final List<T> items;
  final T initialSelected;
  final String Function(T item) labelOf;
  final ValueChanged<T> onChanged;
  final int flex;

  @override
  State<WheelColumn<T>> createState() => _WheelColumnState<T>();
}

class _WheelColumnState<T> extends State<WheelColumn<T>> {
  late final FixedExtentScrollController _controller;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.items.indexOf(widget.initialSelected);
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return Expanded(
      flex: widget.flex,
      child: ListWheelScrollView(
        controller: _controller,
        itemExtent: AppWheelPicker.itemExtent,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (i) {
          unawaited(HapticFeedback.selectionClick());
          setState(() => _selectedIndex = i);
          widget.onChanged(widget.items[i]);
        },
        children: List.generate(
          widget.items.length,
          (i) => Center(
            child: Text(
              widget.labelOf(widget.items[i]),
              style: wheelItemTextStyle(c, isSelected: i == _selectedIndex),
            ),
          ),
        ),
      ),
    );
  }
}
