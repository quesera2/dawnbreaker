import 'package:flutter/material.dart';

class AppTextStyle {
  AppTextStyle._();

  static const largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
  );

  static const title1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700);

  static const title2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);

  static const headline = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);

  static const body = TextStyle(fontSize: 15, fontWeight: FontWeight.w400);

  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

  static const overline = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);

  static const mono = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'monospace',
  );
}
