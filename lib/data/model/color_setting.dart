import 'package:collection/collection.dart';
import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'color_setting.freezed.dart';

@freezed
abstract class ColorSetting with _$ColorSetting {
  const ColorSetting._();

  const factory ColorSetting({
    required TaskColor color,
    @Default('') String alias,
    required int order,
  }) = _ColorSetting;

  static List<ColorSetting> defaults() => TaskColor.values
      .map((c) => ColorSetting(color: c, order: c.defaultOrder))
      .sortedBy<num>((s) => s.order);

  static final _pattern = RegExp(r'^([^:]+):(\d+):(.*)$');

  String encode() => '${color.name}:$order:$alias';

  static ColorSetting? decode(String encoded) {
    final match = _pattern.firstMatch(encoded);
    if (match == null) return null;
    try {
      final color = TaskColor.values.byName(match.group(1)!);
      return ColorSetting(
        color: color,
        order: int.parse(match.group(2)!),
        alias: match.group(3)!,
      );
    } on ArgumentError catch (e, s) {
      logger.w('ColorSetting.decode failed', error: e, stackTrace: s);
      return null;
    }
  }

  static List<ColorSetting> fromStringList(List<String> encoded) {
    final decoded = {
      for (final s in encoded.map(decode).whereType<ColorSetting>()) s.color: s,
    };
    return TaskColor.values
        .map((c) => decoded[c] ?? ColorSetting(color: c, order: c.defaultOrder))
        .sortedBy<num>((s) => s.order);
  }

  static List<String> toStringList(List<ColorSetting> settings) =>
      settings.map((s) => s.encode()).toList();
}

extension _TaskColorDefaultOrder on TaskColor {
  int get defaultOrder => switch (this) {
    .red => 0,
    .blue => 1,
    .yellow => 2,
    .green => 3,
    .orange => 4,
    .none => 5,
  };
}
