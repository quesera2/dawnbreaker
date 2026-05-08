import 'package:dawnbreaker/app/app_typography.dart';
import 'package:flutter/material.dart';

enum AppButtonSize {
  small(32.0, EdgeInsets.symmetric(horizontal: 12), AppTextStyle.caption),
  medium(40.0, EdgeInsets.symmetric(horizontal: 16), AppTextStyle.body),
  large(52.0, EdgeInsets.symmetric(horizontal: 22), AppTextStyle.headline);

  const AppButtonSize(this.height, this.padding, this.textStyle);

  final double height;
  final EdgeInsets padding;
  final TextStyle textStyle;
}
