import 'package:dawnbreaker/app/app_colors.dart';
import 'package:flutter/material.dart';

enum SocialProvider { google }

/// ソーシャルログインのサインインボタン。
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
    final (backgroundColor, foregroundColor) = switch (provider) {
      .google => (colorScheme.surface, colorScheme.text),
    };

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: switch (provider) {
            .google => BorderSide(color: colorScheme.borderStrong),
          },
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
            child: _Mark(provider: provider),
          ),
          Text(label),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.provider});

  final SocialProvider provider;

  @override
  Widget build(BuildContext context) => switch (provider) {
    // 4 色でブランドが成立するため着色しない
    .google => Image.asset('assets/google_mark.png', width: 26, height: 26),
  };
}
