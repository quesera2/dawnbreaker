import 'package:dawnbreaker/app/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum SocialProvider { google, apple }

/// Google / Apple のサインインボタン。
class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    super.key,
    required this.provider,
    required this.label,
    this.onPressed,
  });

  final SocialProvider provider;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    // strong / strongOn はテーマで反転するため、Apple の黒地白抜き・白地黒抜きが
    // 分岐なしで揃う
    final (backgroundColor, foregroundColor) = switch (provider) {
      .google => (colorScheme.surface, colorScheme.text),
      .apple => (colorScheme.strong, colorScheme.strongOn),
    };

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: provider == .google
              ? BorderSide(color: colorScheme.borderStrong)
              : BorderSide.none,
        ),
        elevation: 1,
        shadowColor: colorScheme.shadow,
      ),
      // マークは各社の作例に合わせて先頭に固定し、ラベルはボタンの中央に置く
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _Mark(provider: provider, color: foregroundColor),
          ),
          Text(label),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.provider, required this.color});

  final SocialProvider provider;
  final Color color;

  @override
  Widget build(BuildContext context) => switch (provider) {
    // 4 色でブランドが成立するため着色しない
    .google => Image.asset('assets/google_mark.png', width: 26, height: 26),
    .apple => SvgPicture.asset('assets/apple_mark.svg', width: 52, height: 52),
  };
}
