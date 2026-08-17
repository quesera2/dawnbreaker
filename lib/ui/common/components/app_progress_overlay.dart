import 'package:dawnbreaker/app/app_colors.dart';
import 'package:flutter/material.dart';

/// 処理中であることを示し、その間の操作を塞ぐ。
///
/// サインインやアカウント削除は外部との往復があって数秒かかりうる。ボタンを無効に
/// するだけだと、押せないのが処理中なのか不具合なのか分からない
class AppProgressOverlay extends StatelessWidget {
  const AppProgressOverlay({
    required this.visible,
    required this.child,
    super.key,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          ColoredBox(
            color: context.appColorScheme.overlay,
            // 裏のボタンに触れないよう、面ごと覆う
            child: const SizedBox.expand(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
