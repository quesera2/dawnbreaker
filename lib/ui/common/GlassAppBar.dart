import 'dart:ui';

import 'package:flutter/material.dart';

//ref: https://qiita.com/e_kei/items/117c81f15217e3015c49
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final double blur;
  final double opacity;

  const GlassAppBar({
    super.key,
    required this.title,
    this.blur = 25.0,
    this.opacity = 0.70,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: opacity);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: AppBar(
          title: title,
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
    );
  }
}
