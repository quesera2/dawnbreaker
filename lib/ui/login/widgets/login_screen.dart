import 'dart:math' as math;

import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/ui/common/messages_mixin.dart';
import 'package:dawnbreaker/ui/login/viewmodel/login_view_model.dart';
import 'package:dawnbreaker/ui/login/widgets/social_sign_in_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// ログイン画面だけのブランド表現。
///
/// 深いインディゴの面にワードマークを据え、シャンパンゴールドの細部で品位を出す。
/// アプリ内の他の画面には出てこない配色のため、デザイントークンには持ち上げない。
class _LoginBrandColors {
  _LoginBrandColors._();

  static const deep = Color(0xFF1D2335);
  static const deepGlow = Color(0xFF2C344D);
  static const champagne = Color(0xFFD9C190);
  static const onDeep = Color(0xFFF2EDE2);
  static const onDeepMuted = Color(0x99F2EDE2);
  static const hairline = Color(0x38F2EDE2);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with MessagesListenMixin {
  late final LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(loginViewModelProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    listenMessages(loginViewModelProvider);
    final isSigningIn = ref.watch(
      loginViewModelProvider.select((s) => s.isSigningIn),
    );

    ref.listen(loginViewModelProvider.select((s) => s.destination), (
      prev,
      next,
    ) {
      if (next == null || prev?.id == next.id) return;

      switch (next.type) {
        case .home:
          context.go('/home');
        case .notificationIntro:
          context.go('/notification-intro');
      }
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          // 上端の外側を光源にして、画面全体を一枚の面として見せる
          gradient: RadialGradient(
            center: Alignment(0, -1.16),
            radius: 1.2,
            colors: [_LoginBrandColors.deepGlow, _LoginBrandColors.deep],
            stops: [0, 0.62],
          ),
        ),
        child: Column(
          children: [
            const Expanded(child: SafeArea(bottom: false, child: _Wordmark())),
            _SignInSheet(isSigningIn: isSigningIn, viewModel: _viewModel),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  static const _hairlineWidth = 148.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 54, 28, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Diamond(size: 6),
          const SizedBox(height: 22),
          Image.asset(
            'assets/somniloop_wordmark.png',
            height: 34,
            color: _LoginBrandColors.onDeep,
            colorBlendMode: BlendMode.srcIn,
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: _hairlineWidth,
            child: Row(
              children: [
                Expanded(child: _Hairline()),
                SizedBox(width: 10),
                _Diamond(size: 4),
                SizedBox(width: 10),
                Expanded(child: _Hairline()),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.loginTagline,
            textAlign: TextAlign.center,
            style: AppTextStyle.caption.copyWith(
              color: _LoginBrandColors.onDeepMuted,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.44,
              height: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Diamond extends StatelessWidget {
  const _Diamond({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: SizedBox(
        width: size,
        height: size,
        child: const ColoredBox(color: _LoginBrandColors.champagne),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: _LoginBrandColors.hairline,
    child: SizedBox(height: 1),
  );
}

class _SignInSheet extends StatelessWidget {
  const _SignInSheet({required this.isSigningIn, required this.viewModel});

  final bool isSigningIn;
  final LoginViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          if (isDark)
            // 暗い面に黒い影を落としても境界がにじむだけなので、上端を明るく縁取る。
            // シートと同じ形を 1px 上にずらして描き、角丸に沿った線を出している
            BoxShadow(color: colorScheme.border, offset: const Offset(0, -1))
          else
            BoxShadow(
              color: colorScheme.shadow,
              blurRadius: 44,
              offset: const Offset(0, -18),
            ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(28, 26, 28, bottomInset + 26),
      child: Column(
        spacing: 12,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phase9 で配線するまでは押しても何も起きない。onPressed を null にすると
          // 「使えないボタン」に見えてしまうため、押せる見た目のままにする
          SocialSignInButton(
            provider: .google,
            label: context.l10n.loginWithGoogle,
            onPressed: isSigningIn ? null : () {},
          ),
          SocialSignInButton(
            provider: .apple,
            label: context.l10n.loginWithApple,
            onPressed: isSigningIn ? null : () {},
          ),
          const _OrSeparator(),
          // ソーシャルログインを主役にするため、ゲスト利用はここだけ弱いテキストボタンで置く
          TextButton(
            onPressed: isSigningIn ? null : viewModel.onClickStartAsGuest,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.textSubtle,
              textStyle: AppTextStyle.caption,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: Text(context.l10n.loginStartAsGuest),
          ),
          // TODO: 規約とポリシーが用意できていないため空
          _TermsNotice(onClickTerms: () {}, onClickPrivacy: () {}),
        ],
      ),
    );
  }
}

/// 利用規約、プライバシーポリシーの文言
class _TermsNotice extends StatefulWidget {
  const _TermsNotice({
    required this.onClickTerms,
    required this.onClickPrivacy,
  });

  final VoidCallback onClickTerms;
  final VoidCallback onClickPrivacy;

  @override
  State<_TermsNotice> createState() => _TermsNoticeState();
}

class _TermsNoticeState extends State<_TermsNotice> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    // widget 越しに呼ぶ。ハンドラを直接持つと差し替えられたとき古い方を掴んだままになる
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => widget.onClickTerms();
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => widget.onClickPrivacy();
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text.rich(
        _termsText(context),
        textAlign: TextAlign.center,
        style: AppTextStyle.overline.copyWith(
          color: colorScheme.textSubtle,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  /// 文中の「利用規約」「プライバシーポリシー」だけをリンクにする。
  TextSpan _termsText(BuildContext context) {
    final terms = context.l10n.loginTermsOfService;
    final privacy = context.l10n.loginPrivacyPolicy;
    final linkStyle = TextStyle(
      color: context.appColorScheme.textMuted,
      decoration: TextDecoration.underline,
    );

    final sentence = context.l10n.loginTermsAgreement(terms, privacy);
    final [before, between] = sentence.split(terms);
    final [conjunction, after] = between.split(privacy);

    return TextSpan(
      children: [
        TextSpan(text: before),
        TextSpan(text: terms, style: linkStyle, recognizer: _termsRecognizer),
        TextSpan(text: conjunction),
        TextSpan(
          text: privacy,
          style: linkStyle,
          recognizer: _privacyRecognizer,
        ),
        TextSpan(text: after),
      ],
    );
  }
}

class _OrSeparator extends StatelessWidget {
  const _OrSeparator();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    final line = Expanded(
      child: ColoredBox(
        color: colorScheme.border,
        child: const SizedBox(height: 1),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              context.l10n.loginOr,
              style: AppTextStyle.caption.copyWith(
                color: colorScheme.textSubtle,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.2,
              ),
            ),
          ),
          line,
        ],
      ),
    );
  }
}
