import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_theme.dart';
import 'package:flutter/material.dart';

abstract class PreviewShowCase extends StatelessWidget {
  const PreviewShowCase({super.key});

  @override
  Widget build(BuildContext context) => _PreviewWrapper(builder: buildPreview);

  Widget buildPreview(BuildContext context);
}

class _PreviewWrapper extends StatelessWidget {
  const _PreviewWrapper({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: createThemeData(context),
      child: Builder(
        builder: (context) => ColoredBox(
          color: context.appColorScheme.bg,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: builder(context),
          ),
        ),
      ),
    );
  }
}
