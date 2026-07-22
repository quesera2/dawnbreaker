import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/core/util/context_extension.dart';
import 'package:dawnbreaker/ui/common/components/app_button.dart';
import 'package:dawnbreaker/ui/common/messages_mixin.dart';
import 'package:dawnbreaker/ui/notification_intro/viewmodel/notification_intro_view_model.dart';
import 'package:dawnbreaker/ui/notification_intro/widgets/notification_preview_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// アカウントを作った直後に、通知が OFF のときだけ挟む誘導画面。
///
/// 断ってもホームへ進める。以降は設定画面から明示的に有効化してもらう。
class NotificationIntroScreen extends ConsumerStatefulWidget {
  const NotificationIntroScreen({super.key});

  @override
  ConsumerState<NotificationIntroScreen> createState() =>
      _NotificationIntroScreenState();
}

class _NotificationIntroScreenState
    extends ConsumerState<NotificationIntroScreen>
    with MessagesListenMixin {
  late final NotificationIntroViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(notificationIntroViewModelProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;
    listenMessages(notificationIntroViewModelProvider);
    final isEnabling = ref.watch(
      notificationIntroViewModelProvider.select((s) => s.isEnabling),
    );

    ref.listen(notificationIntroViewModelProvider.select((s) => s.completed), (
      prev,
      next,
    ) {
      if (next == null || prev?.id == next.id) return;
      context.go('/home');
    });

    return PopScope(
      canPop: false,
      // 戻る操作はキャンセル扱い。誘導のためだけの画面なので、行き止まりにはしない
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _viewModel.onSkip();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(
                  child: Center(child: NotificationPreviewAnimation()),
                ),
                Text(
                  context.l10n.notificationIntroTitle,
                  style: AppTextStyle.largeTitle.copyWith(
                    color: colorScheme.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.notificationIntroBody,
                  style: AppTextStyle.body.copyWith(
                    color: colorScheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: context.l10n.notificationIntroEnable,
                  onPressed: isEnabling ? null : _viewModel.onClickEnable,
                  fullWidth: true,
                  size: .large,
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: context.l10n.notificationIntroLater,
                  onPressed: isEnabling ? null : _viewModel.onSkip,
                  variant: .ghost,
                  fullWidth: true,
                  size: .large,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
