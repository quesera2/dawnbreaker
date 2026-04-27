import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/core/context_extension.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  late List<OnboardingPage> _pages;
  late List<Color> _colors;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages = buildOnboardingPages(context);
    _colors = _pages.map((page) => page.backgroundColor).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        final Color backgroundColor;

        if (_pageController.hasClients) {
          final page = _pageController.page ?? 0.0;
          final fromIndex = page.floor().clamp(0, _colors.length - 2);
          final t = (page - fromIndex).clamp(0.0, 1.0);
          backgroundColor = Color.lerp(
            _colors[fromIndex],
            _colors[fromIndex + 1],
            Curves.easeInOut.transform(t),
          )!;
        } else {
          backgroundColor = _colors[0];
        }

        return DecoratedBox(
          decoration: BoxDecoration(color: backgroundColor),
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: _pages,
                ),
              ),
              SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: colorScheme.primary,
                  dotColor: colorScheme.borderStrong,
                ),
                onDotClicked: (index) => _pageController.jumpToPage(index),
              ),
              _buttonArea(
                context,
                isLastPage: _currentPage == _pages.length - 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buttonArea(BuildContext context, {required bool isLastPage}) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        spacing: 8,
        children: [
          AppButton(
            label: isLastPage ? l10n.onboardingStart : l10n.onboardingNext,
            onPressed: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
            fullWidth: true,
            size: AppButtonSize.large,
          ),
          AppButton(
            label: l10n.onboardingSkip,
            onPressed: () {},
            fullWidth: true,
            size: AppButtonSize.large,
            variant: AppButtonVariant.ghost,
          ),
        ],
      ),
    );
  }
}
