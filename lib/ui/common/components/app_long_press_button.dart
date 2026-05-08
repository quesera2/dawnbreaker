import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/ui/common/components/app_button_size.dart';
import 'package:dawnbreaker/ui/common/components/preview_show_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppLongPressButton extends StatefulWidget {
  const AppLongPressButton({
    super.key,
    required this.label,
    this.onLongPress,
    this.duration = const Duration(milliseconds: 1000),
    this.size = AppButtonSize.medium,
  });

  final String label;
  final VoidCallback? onLongPress;
  final Duration duration;
  final AppButtonSize size;

  @override
  State<AppLongPressButton> createState() => _AppLongPressButtonState();
}

class _AppLongPressButtonState extends State<AppLongPressButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onLongPress?.call();
        _isFinished = true;
      }
    });
  }

  @override
  void didUpdateWidget(AppLongPressButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) =>
      _controller.forward(from: _controller.value);

  void _onEnd() {
    if (_isFinished) return;

    _controller.animateBack(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColorScheme;
    final size = widget.size;
    final radius = BorderRadius.circular(AppRadius.md);
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (_) => _onEnd(),
      onTapCancel: _onEnd,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: colors.danger),
          borderRadius: radius,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: colors.dangerSoft)),
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _controller.value,
                    child: ColoredBox(color: colors.danger),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height),
                  child: Padding(
                    padding: size.padding,
                    child: Center(
                      child: Text(
                        widget.label,
                        style: size.textStyle.copyWith(
                          color: Color.lerp(
                            colors.danger,
                            colors.dangerSoft,
                            _controller.value,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@Preview()
Widget previewLongPressButton() => const LongPressButtonShowCase();

final class LongPressButtonShowCase extends PreviewShowCase {
  const LongPressButtonShowCase({super.key});

  @override
  Widget buildPreview(BuildContext context) =>
      const AppLongPressButton(label: '長押しで削除');
}
