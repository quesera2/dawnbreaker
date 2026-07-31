import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/ui/common/components/app_section_header.dart';
import 'package:dawnbreaker/ui/common/components/preview_show_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

enum AppListCellVariant { normal, destruction }

enum AppListCellStyle {
  top,
  middle,
  bottom,
  single;

  BorderRadius? borderRadius(Radius radius) {
    return switch (this) {
      single => BorderRadius.all(radius),
      top => BorderRadius.vertical(top: radius),
      bottom => BorderRadius.vertical(bottom: radius),
      middle => null,
    };
  }

  Border _border(BorderSide side) => switch (this) {
    single => Border.fromBorderSide(side),
    top => Border(top: side, left: side, right: side),
    bottom => Border(bottom: side, left: side, right: side),
    middle => Border(left: side, right: side),
  };

  BoxDecoration boxDecoration({
    required Color backgroundColor,
    required Color borderColor,
    required BorderRadius? borderRadius,
  }) {
    final side = BorderSide(color: borderColor);
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius,
      border: _border(side),
    );
  }
}

class AppListCell extends StatelessWidget {
  const AppListCell({
    super.key,
    required this.style,
    required this.child,
    this.variant = .normal,
    this.onTap,
  });

  final AppListCellStyle style;
  final Widget child;
  final AppListCellVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    final borderRadius = style.borderRadius(
      const Radius.circular(AppRadius.lg),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: DecoratedBox(
        decoration: style.boxDecoration(
          backgroundColor: colors.surface,
          borderColor: colors.border,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: _applyVariant(
                context,
                Align(alignment: Alignment.centerLeft, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 取り返しのつかない操作は本文の見た目で伝える。
  ///
  /// 大きさは周りのセルと揃え、色と太さだけ変える。`ListTile` は周囲の
  /// `DefaultTextStyle` を見ずに `ListTileTheme` から解決するため、
  /// 素の `Text` を置いた場合と両方に効かせる
  Widget _applyVariant(BuildContext context, Widget content) {
    if (variant == .normal) return content;

    final danger = context.appColorScheme.danger;
    final titleStyle =
        ListTileTheme.of(context).titleTextStyle ??
        Theme.of(context).textTheme.bodyLarge;
    return ListTileTheme.merge(
      titleTextStyle: titleStyle?.copyWith(
        color: danger,
        fontWeight: FontWeight.bold,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: danger, fontWeight: FontWeight.bold),
        child: content,
      ),
    );
  }

  static IndexedWidgetBuilder buildSeparator(
    List<Widget> items, {
    required Color borderColor,
    double borderHeight = 1,
  }) {
    return (_, index) {
      if (items[index] is AppListCell && items[index + 1] is AppListCell) {
        return Divider(height: borderHeight, color: borderColor);
      }
      return const SizedBox.shrink();
    };
  }
}

@Preview()
Widget previewAppListCell() => const AppListCellShowCase();

final class AppListCellShowCase extends PreviewShowCase {
  const AppListCellShowCase({super.key});

  @override
  Widget buildPreview(BuildContext context) {
    final c = context.appColorScheme;
    Widget cell(
      AppListCellStyle type,
      String label, {
      AppListCellVariant variant = .normal,
    }) {
      // destruction は AppListCell が本文のスタイルを与えるため、ここでは指定しない
      final TextStyle? style;
      if (variant == .destruction) {
        style = null;
      } else {
        style = TextStyle(color: c.text);
      }
      return AppListCell(
        style: type,
        variant: variant,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(label, style: style),
        ),
      );
    }

    final items = [
      const AppSectionHeader(title: Text('single block')),
      cell(.single, 'single content'),
      const SizedBox(height: 20),
      const AppSectionHeader(title: Text('multiple block')),
      cell(.top, '1st line'),
      cell(.middle, '2nd line'),
      cell(.middle, '3rd line'),
      cell(.bottom, '4th line'),
      const SizedBox(height: 20),
      const AppSectionHeader(title: Text('destruction')),
      cell(.single, 'delete account', variant: .destruction),
    ];
    return Material(
      type: MaterialType.transparency,
      child: ListView.separated(
        itemCount: items.length,
        itemBuilder: (_, index) => items[index],
        separatorBuilder: AppListCell.buildSeparator(
          items,
          borderColor: c.border,
        ),
      ),
    );
  }
}
