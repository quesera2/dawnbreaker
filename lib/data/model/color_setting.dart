import 'package:collection/collection.dart';
import 'package:dawnbreaker/data/model/task_color.dart';

class ColorSetting {
  const ColorSetting({required this.color, this.alias = ''});

  final TaskColor color;
  final String alias;

  static List<ColorSetting> defaults() =>
      TaskColor.values.map((c) => ColorSetting(color: c)).sorted((c1, c2) {
        if (c1.color == .none) return 1;
        if (c2.color == .none) return -1;
        return 0;
      }).toList();

  String encode() => '${color.name}:$alias';

  static ColorSetting? decode(String encoded) {
    final index = encoded.indexOf(':');
    if (index == -1) return null;
    final colorName = encoded.substring(0, index);
    final alias = encoded.substring(index + 1);
    try {
      final color = TaskColor.values.byName(colorName);
      return ColorSetting(color: color, alias: alias);
    } on ArgumentError {
      return null;
    }
  }

  static List<ColorSetting> fromStringList(List<String> encoded) {
    if (encoded.isEmpty) return defaults();
    final decoded = encoded.map(decode).whereType<ColorSetting>().toList();
    final existing = {for (final s in decoded) s.color};
    final missing = TaskColor.values
        .where((c) => !existing.contains(c))
        .map((c) => ColorSetting(color: c));
    return [...decoded, ...missing];
  }

  static List<String> toStringList(List<ColorSetting> settings) =>
      settings.map((s) => s.encode()).toList();

  ColorSetting copyWith({String? alias}) =>
      ColorSetting(color: color, alias: alias ?? this.alias);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorSetting && other.color == color && other.alias == alias;

  @override
  int get hashCode => Object.hash(color, alias);
}
