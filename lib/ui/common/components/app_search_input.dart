import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppSearchInput extends StatefulWidget {
  const AppSearchInput({
    super.key,
    this.controller,
    this.onChanged,
    this.placeholder = 'タスクを検索',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? placeholder;

  @override
  State<AppSearchInput> createState() => _AppSearchInputState();
}

class _AppSearchInputState extends State<AppSearchInput> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_rebuild);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 44,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _focusNode.hasFocus ? c.primary : c.border,
          width: _focusNode.hasFocus ? 1.5 : 1.0,
        ),
        boxShadow: _focusNode.hasFocus
            ? [BoxShadow(color: c.primarySoft, blurRadius: 0, spreadRadius: 3)]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search,
            size: 18,
            color: _focusNode.hasFocus ? c.primary : c.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              onChanged: widget.onChanged,
              style: AppTextStyle.body.copyWith(color: c.text),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: AppTextStyle.body.copyWith(color: c.textSubtle),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

@Preview()
Widget previewSearchInput() => const SearchInputShowCase();

final class SearchInputShowCase extends StatelessWidget {
  const SearchInputShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Container(
      color: c.bg,
      padding: const EdgeInsets.all(24),
      child: const SizedBox(width: 320, child: AppSearchInput()),
    );
  }
}
