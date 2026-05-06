import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/ui/common/components/preview_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? c.text : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: isSelected ? c.text : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 120),
              style: AppTextStyle.caption.copyWith(
                color: isSelected ? c.textInverse : c.textMuted,
                letterSpacing: 0.1,
                height: 1,
              ),
              child: Text(label),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 120),
                style: AppTextStyle.caption.copyWith(
                  color: isSelected
                      ? c.textInverse.withValues(alpha: 0.7)
                      : c.textMuted.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                  height: 1,
                ),
                child: Text('$count'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

@Preview()
Widget previewFilterChip() => const FilterChipShowCase();

final class FilterChipShowCase extends StatelessWidget {
  const FilterChipShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColorScheme;
    return PreviewWrapper(
      child: Container(
        color: c.bg,
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            AppFilterChip(
              label: 'すべて',
              isSelected: true,
              onTap: () {},
              count: 12,
            ),
            AppFilterChip(
              label: '超過',
              isSelected: false,
              onTap: () {},
              count: 3,
            ),
            AppFilterChip(label: '今日', isSelected: false, onTap: () {}),
            AppFilterChip(label: '7日以内', isSelected: false, onTap: () {}),
          ],
        ),
      ),
    );
  }
}
