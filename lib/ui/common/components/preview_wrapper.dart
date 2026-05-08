import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_theme.dart';
import 'package:flutter/material.dart';

class PreviewWrapper extends StatelessWidget {
  const PreviewWrapper({super.key, required this.builder});

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

abstract class PreviewShowCase extends StatelessWidget {
  const PreviewShowCase({super.key});

  @override
  Widget build(BuildContext context) => PreviewWrapper(builder: buildPreview);

  Widget buildPreview(BuildContext context);
}
