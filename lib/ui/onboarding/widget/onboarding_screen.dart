import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/components/app_icon_button.dart';
import 'package:dawnbreaker/ui/common/messages_mixin.dart';
import 'package:dawnbreaker/ui/onboarding/viewmodel/onboarding_view_model.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_mode.dart';
import 'package:dawnbreaker/ui/onboarding/widget/onboarding_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.mode});

  final OnboardingMode mode;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with MessagesListenMixin {
  late final PageController _pageController;
  late final OnboardingViewModelProvider _viewState;
  late final OnboardingViewModel _viewModel;

  late List<OnboardingPage> _pages;
  late List<Color> _colors;
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _viewState = onboardingViewModelProvider(mode: widget.mode);
    _viewModel = ref.read(_viewState.notifier);
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
    listenMessages(_viewState);
    final isCompleting = ref.watch(_viewState.select((s) => s.isLoading));

    ref.listen(_viewState.select((s) => s.destination), (_, destination) {
      if (destination == null) return;
      switch (destination) {
        case .home:
          context.go('/home');
        case .newTask:
          context.go('/home/new_task');
        case .pop:
          context.pop();
      }
    });

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
              switch (widget.mode) {
                .fromSettings => Visibility(
                  visible: !_isLastPage,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 0, 0),
                      child: AppIconButton(
                        icon: Icons.close,
                        onTap: () => context.pop(),
                      ),
                    ),
                  ),
                ),
                .initial => Visibility(
                  visible: !_isLastPage,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 8, 4),
                      child: AppIconButton(
                        icon: Icons.skip_next,
                        label: context.l10n.onboardingSkip,
                        onTap: _viewModel.onClickSkip,
                      ),
                    ),
                  ),
                ),
              },
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
              _ButtonArea(
                isLastPage: _isLastPage,
                mode: widget.mode,
                isCompleting: isCompleting,
                onPrimary: _isLastPage
                    ? _viewModel.onClickDone
                    : () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
                onSecondary: _viewModel.onClickSkip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ButtonArea extends StatelessWidget {
  const _ButtonArea({
    required this.isLastPage,
    required this.mode,
    required this.isCompleting,
    required this.onPrimary,
    required this.onSecondary,
  });

  final bool isLastPage;
  final OnboardingMode mode;
  final bool isCompleting;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        spacing: 8,
        children: [
          AppButton(
            label: switch ((isLastPage, mode)) {
              (false, _) => context.l10n.onboardingNext,
              (true, .initial) => context.l10n.onboardingStart,
              (true, .fromSettings) => context.l10n.commonClose,
            },
            onPressed: isCompleting ? null : onPrimary,
            fullWidth: true,
            size: AppButtonSize.large,
          ),
          if (mode == .initial)
            AppButton(
              label: context.l10n.onboardingSkip,
              onPressed: isCompleting ? null : onSecondary,
              fullWidth: true,
              size: AppButtonSize.large,
              variant: AppButtonVariant.ghost,
            ),
        ],
      ),
    );
  }
}
