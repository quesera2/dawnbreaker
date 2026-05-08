import 'package:dawnbreaker/app/app_colors.dart';
import 'package:dawnbreaker/app/app_radius.dart';
import 'package:dawnbreaker/app/app_typography.dart';
import 'package:dawnbreaker/ui/common/components/preview_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

class AppTextInput extends StatefulWidget {
  const AppTextInput({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
  });

  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;

  @override
  State<AppTextInput> createState() => _AppTextInputState();
}

class _AppTextInputState extends State<AppTextInput> {
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
    final c = context.appColorScheme;
    return TextField(
      focusNode: _focusNode,
      controller: widget.controller,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      style: AppTextStyle.body.copyWith(color: c.text),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTextStyle.body.copyWith(color: c.textSubtle),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
      ),
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    );
  }
}

class AppSearchInput extends StatefulWidget {
  const AppSearchInput({
    super.key,
    required this.placeholder,
    this.controller,
    this.onChanged,
    this.onClear,
    this.showClear = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool showClear;
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
    final c = context.appColorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 44,
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
          if (widget.showClear && widget.onClear != null) ...[
            IconButton(
              onPressed: widget.onClear,
              icon: Icon(Icons.clear, size: 18, color: c.textMuted),
            ),
          ] else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}

@Preview()
Widget previewInputs() => const InputShowCase();

final class InputShowCase extends PreviewShowCase {
  const InputShowCase({super.key});

  @override
  Widget buildPreview(BuildContext context) => const SizedBox(
    width: 320,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        AppTextInput(hintText: 'タスク名を入力'),
        AppSearchInput(placeholder: 'タスクを検索'),
        AppSearchInput(placeholder: '検索中…', showClear: true),
      ],
    ),
  );
}
