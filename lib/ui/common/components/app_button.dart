import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leading,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leading;
  final bool fullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null;

  (double, EdgeInsets, TextStyle) get _sizeConfig => switch (widget.size) {
    AppButtonSize.small => (
      32.0,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      AppTextStyle.caption,
    ),
    AppButtonSize.medium => (
      40.0,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      AppTextStyle.body,
    ),
    AppButtonSize.large => (
      52.0,
      const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
      AppTextStyle.headline,
    ),
  };

  void _onTapDown(TapDownDetails _) {
    if (!_isDisabled) setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (!_isDisabled) {
      setState(() => _isPressed = false);
      widget.onPressed?.call();
    }
  }

  void _onTapCancel() {
    if (!_isDisabled) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    final (height, padding, textStyle) = _sizeConfig;

    final backgroundColor = switch (widget.variant) {
      AppButtonVariant.primary => c.primary,
      AppButtonVariant.secondary => c.surface,
      AppButtonVariant.ghost => Colors.transparent,
      AppButtonVariant.danger => c.danger,
    };
    final textColor = switch (widget.variant) {
      AppButtonVariant.primary => c.primaryOn,
      AppButtonVariant.secondary => c.text,
      AppButtonVariant.ghost => c.text,
      AppButtonVariant.danger => c.primaryOn,
    };
    final border = switch (widget.variant) {
      AppButtonVariant.secondary => Border.all(color: c.borderStrong, width: 1),
      _ => null,
    };
    final shadows = switch (widget.variant) {
      AppButtonVariant.primary || AppButtonVariant.secondary => const [
        BoxShadow(
          color: Color(0x0A1E1914),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
      _ => null,
    };

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedOpacity(
        opacity: _isDisabled ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: _isPressed
              ? const Duration(milliseconds: 80)
              : const Duration(milliseconds: 120),
          transform: Matrix4.translationValues(0, _isPressed ? 0.5 : 0, 0),
          height: height,
          width: widget.fullWidth ? double.infinity : null,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: border,
            boxShadow: shadows,
          ),
          child: Row(
            mainAxisSize: widget.fullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[
                IconTheme(
                  data: IconThemeData(color: textColor),
                  child: widget.leading!,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: textStyle.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview()
Widget previewButton() => const ButtonShowCase();

final class ButtonShowCase extends StatelessWidget {
  const ButtonShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Container(
      color: c.bg,
      padding: const EdgeInsets.all(24),
      child: Column(
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
              AppButton(
                label: 'Secondary',
                variant: AppButtonVariant.secondary,
              ),
              AppButton(label: 'Danger', variant: AppButtonVariant.danger),
            ],
          ),
          AppButton(
            label: '完了',
            onPressed: () {},
            leading: const Icon(Icons.check, size: 16),
          ),
        ],
      ),
    );
  }
}
