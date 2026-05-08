import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:dawnbreaker/ui/common/components/preview_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leading,
    this.fullWidth = false,
    this.tintColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leading;
  final bool fullWidth;
  final TaskColor? tintColor;

  (double, EdgeInsets, TextStyle) get _sizeConfig => switch (size) {
    AppButtonSize.small => (
      32.0,
      const EdgeInsets.symmetric(horizontal: 12),
      AppTextStyle.caption,
    ),
    AppButtonSize.medium => (
      40.0,
      const EdgeInsets.symmetric(horizontal: 16),
      AppTextStyle.body,
    ),
    AppButtonSize.large => (
      52.0,
      const EdgeInsets.symmetric(horizontal: 22),
      AppTextStyle.headline,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    final (height, padding, textStyle) = _sizeConfig;
    final minSize = Size(fullWidth ? double.infinity : 0, height);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    final ts = textStyle.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );

    final child = leading != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [leading!, const SizedBox(width: 6), Text(label)],
          )
        : Text(label);

    return switch (variant) {
      .primary when tintColor is TaskColor => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: tintColor!.baseColor(context),
          foregroundColor: c.primaryOn,
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: ts,
          elevation: 1,
          shadowColor: c.shadow,
        ),
        child: child,
      ),
      .primary => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.primaryOn,
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: ts,
          elevation: 1,
          shadowColor: c.shadow,
        ),
        child: child,
      ),
      .secondary => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          side: BorderSide(color: c.borderStrong),
          textStyle: ts,
        ),
        child: child,
      ),
      .ghost => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: ts,
        ),
        child: child,
      ),
      .danger => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: c.danger,
          foregroundColor: c.primaryOn,
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          textStyle: ts,
          elevation: 1,
          shadowColor: c.shadow,
        ),
        child: child,
      ),
    };
  }
}

@Preview()
Widget previewButton() => const ButtonShowCase();

final class ButtonShowCase extends PreviewShowCase {
  const ButtonShowCase({super.key});

  @override
  Widget buildPreview(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          AppButton(label: 'Primary', onPressed: () {}),
          AppButton(
            label: 'Secondary',
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
          AppButton(
            label: 'Ghost',
            variant: AppButtonVariant.ghost,
            onPressed: () {},
          ),
          AppButton(
            label: 'Danger',
            variant: AppButtonVariant.danger,
            onPressed: () {},
          ),
        ],
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          AppButton(
            label: 'Tint',
            variant: AppButtonVariant.primary,
            onPressed: () {},
            tintColor: TaskColor.red,
          ),
          AppButton(
            label: 'Tint',
            variant: AppButtonVariant.primary,
            onPressed: () {},
            tintColor: TaskColor.blue,
          ),
          AppButton(
            label: 'Tint',
            variant: AppButtonVariant.primary,
            onPressed: () {},
            tintColor: TaskColor.orange,
          ),
          AppButton(
            label: 'Tint',
            variant: AppButtonVariant.primary,
            onPressed: () {},
            tintColor: TaskColor.yellow,
          ),
          AppButton(
            label: 'Tint',
            variant: AppButtonVariant.primary,
            onPressed: () {},
            tintColor: TaskColor.green,
          ),
          AppButton(
            label: 'Tint',
            variant: AppButtonVariant.primary,
            onPressed: () {},
            tintColor: TaskColor.none,
          ),
        ],
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          AppButton(
            label: 'Small',
            size: AppButtonSize.small,
            onPressed: () {},
          ),
          AppButton(label: 'Medium', onPressed: () {}),
          AppButton(
            label: 'Large',
            size: AppButtonSize.large,
            onPressed: () {},
          ),
        ],
      ),
      const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          AppButton(label: 'Primary'),
          AppButton(label: 'Secondary', variant: AppButtonVariant.secondary),
          AppButton(label: 'Danger', variant: AppButtonVariant.danger),
        ],
      ),
      AppButton(
        label: '完了',
        onPressed: () {},
        leading: const Icon(Icons.check, size: 16),
      ),
    ],
  );
}
