import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/ui/common/components/app_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

enum AppTableCellType {
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
    required Radius radius,
  }) {
    final side = BorderSide(color: borderColor);
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius(radius),
      border: _border(side),
    );
  }
}

class AppTableCell extends StatelessWidget {
  const AppTableCell({
    super.key,
    required this.type,
    required this.child,
    this.onTap,
  });

  final AppTableCellType type;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    const borderRadius = Radius.circular(AppRadius.lg);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Ink(
        decoration: type.boxDecoration(
          backgroundColor: colors.surface,
          borderColor: colors.border,
          radius: borderRadius,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: type.borderRadius(borderRadius),
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
      if (items[index] is AppTableCell && items[index + 1] is AppTableCell) {
        return Divider(height: borderHeight, color: borderColor);
      }
      return const SizedBox.shrink();
    };
  }
}

@Preview()
Widget previewAppTableCell() => const AppTableCellShowCase();

final class AppTableCellShowCase extends StatelessWidget {
  const AppTableCellShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    Widget cell(AppTableCellType type, String label) => AppTableCell(
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
      color: c.bg,
      child: Padding(
        padding: const EdgeInsetsGeometry.all(10),
        child: ListView.separated(
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
          separatorBuilder: AppTableCell.buildSeparator(
            items,
            borderColor: c.border,
          ),
        ),
      ),
    );
  }
}
