import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/ui/common/components/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:go_router/go_router.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.centerTitle = false,
    this.actions,
    this.onBack,
  });

  final String title;
  final bool centerTitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: _leading(context),
      automaticallyImplyLeading: false,
      title: Text(title),
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  Widget? _leading(BuildContext context) {
    if (onBack != null || Navigator.maybeOf(context)?.canPop() == true) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 0, 10),
        child: AppIconButton(
          icon: Icons.arrow_back_ios_new,
          onTap: onBack ?? () => context.pop(),
        ),
      );
    }
    return null;
  }
}

@Preview()
Widget previewAppAppBar() => const AppAppBarShowCase();

final class AppAppBarShowCase extends StatelessWidget {
  const AppAppBarShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return ColoredBox(
      color: c.bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAppBar(title: 'タイトルのみ'),
          Divider(height: 1, color: c.divider),
          AppAppBar(
            title: 'アクションあり',
            actions: [
              AppIconButton(onTap: () {}, icon: Icons.add),
              const SizedBox(width: 8),
              AppIconButton(onTap: () {}, icon: Icons.settings_outlined),
              const SizedBox(width: 4),
            ],
          ),
          Divider(height: 1, color: c.divider),
          AppAppBar(title: '戻るボタンあり', onBack: () {}),
          Divider(height: 1, color: c.divider),
          AppAppBar(
            title: 'すべてあり',
            onBack: (){},
            actions: [
              AppIconButton(onTap: () {},  icon: Icons.more_vert),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }
}
