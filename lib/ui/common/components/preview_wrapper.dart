import 'package:dawnbreaker/app/app_theme.dart';
import 'package:flutter/material.dart';

class PreviewWrapper extends StatelessWidget {
  const PreviewWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(data: createThemeData(context), child: child);
  }
}
