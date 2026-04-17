import 'package:flutter/material.dart';

enum TaskColor {
  none(Colors.grey),
  red(Colors.red),
  blue(Colors.blue),
  yellow(Colors.yellow),
  green(Colors.green),
  orange(Colors.orange);

  const TaskColor(this.color);

  final Color color;
}
