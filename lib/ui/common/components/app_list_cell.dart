import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/ui/common/components/app_section_header.dart';
import 'package:dawnbreaker/ui/common/components/preview_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

enum AppListCellType {
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
    required this.type,
    required this.child,
    this.onTap,
  });

  final AppListCellType type;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    final borderRadius = type.borderRadius(const Radius.circular(AppRadius.lg));

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Ink(
        decoration: type.boxDecoration(
          backgroundColor: colors.surface,
          borderColor: colors.border,
          borderRadius: borderRadius,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
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
    Widget cell(AppListCellType type, String label) => AppListCell(
      type: type,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(label, style: TextStyle(color: c.text)),
      ),
    );
    final items = [
      const AppSectionHeader(title: Text('single block')),
      cell(.single, 'single content'),
      const SizedBox(height: 20),
      const AppSectionHeader(title: Text('multiple block')),
      cell(.top, '1st line'),
      cell(.middle, '2nd line'),
      cell(.middle, '3rd line'),
      cell(.bottom, '4th line'),
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
