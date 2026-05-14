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

  late List<OnboardingPageData> _pageData;
  late List<Color> _colors;
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pageData.length - 1;

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
    final c = context.appColorScheme;
    _colors = [
      c.info,
      c.warning,
      c.danger,
      c.successSoft,
    ].map((color) => Color.lerp(color, c.surface, 0.65)!).toList();
    _pageData = buildOnboardingPages(
      context,
      pageColors: _colors,
      mode: widget.mode,
      onNext: () => _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ),
      onDone: _viewModel.onClickDone,
      onSkip: _viewModel.onClickSkip,
      onRequestNotification: _viewModel.onRequestNotification,
    );
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

    ref.listen(_viewState.select((s) => s.destination), (prev, next) {
      if (next == null || prev?.id == next.id) return;

      switch (next.type) {
        case .home:
          context.go('/home');
        case .newTask:
          context.go('/home/new_task');
        case .pop:
          context.pop();
        case .next:
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
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
                  children: _pageData.map((d) => d.page).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsetsGeometry.symmetric(vertical: 16),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: _pageData.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    activeDotColor: colorScheme.primary,
                    dotColor: colorScheme.borderStrong,
                  ),
                  onDotClicked: (index) => _pageController.jumpToPage(index),
                ),
              ),
              _ButtonArea(
                buttons: _pageData[_currentPage].buttons,
                isCompleting: isCompleting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ButtonArea extends StatelessWidget {
  const _ButtonArea({required this.buttons, required this.isCompleting});

  final ButtonConfig buttons;
  final bool isCompleting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        spacing: 8,
        children: [
          AppButton(
            label: buttons.primaryLabel,
            onPressed: isCompleting ? null : buttons.primaryAction,
            fullWidth: true,
            size: AppButtonSize.large,
          ),
          if (buttons.hasSecondaryArea)
            Visibility(
              visible: buttons.secondaryLabel != null,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: AppButton(
                label: buttons.secondaryLabel ?? '',
                onPressed: isCompleting ? null : buttons.secondaryAction,
                fullWidth: true,
                size: AppButtonSize.large,
                variant: AppButtonVariant.ghost,
              ),
            ),
        ],
      ),
    );
  }
}
