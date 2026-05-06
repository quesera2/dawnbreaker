import 'package:dawnbreaker/data/model/task_color.dart';
import 'package:flutter/material.dart';

class AppColorsLight {
  AppColorsLight._();

  // Backgrounds
  static const bg = Color(0xFFF6F4EF);
  static const bgSubtle = Color(0xFFEFEDE6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFBFAF6);

  // Borders & Dividers
  static const border = Color(0x141E1914);
  static const borderStrong = Color(0x231E1914);
  static const divider = Color(0x0F1E1914);
  static const overlay = Color(0x731E1914);
  static const trackBg = Color(0x121E1914);
  static const shadow = Color(0x0A1E1914);

  // Text
  static const text = Color(0xFF1B1A17);
  static const textMuted = Color(0x9E1B1A17);
  static const textSubtle = Color(0x6B1B1A17);
  static const textInverse = Color(0xFFFBFAF6);

  static const primary = Color(0xFF3C4253);
  static const primarySoft = Color(0xFFE8EBF2);
  static const primaryOn = Color(0xFFFFFFFF);

  static const danger = Color(0xFFC82F33);
  static const dangerSoft = Color(0xFFFFE6E3);

  static const warning = Color(0xFFD79628);
  static const warningSoft = Color(0xFFFFEBD2);

  static const success = Color(0xFF4A9A5E);
  static const successSoft = Color(0xFFDFF6E2);

  static const info = Color(0xFF4188B6);
  static const infoSoft = Color(0xFFDDF2FF);
}

class AppColorsDark {
  AppColorsDark._();

  static const bg = Color(0xFF12110F);
  static const bgSubtle = Color(0xFF1A1916);
  static const surface = Color(0xFF1E1C19);
  static const surfaceAlt = Color(0xFF24221E);

  static const border = Color(0x17FFFAF0);
  static const borderStrong = Color(0x29FFFAF0);
  static const divider = Color(0x0FFFFAF0);
  static const overlay = Color(0x99000000);
  static const trackBg = Color(0x17FFFAF0);
  static const shadow = Color(0x40000000);

  static const text = Color(0xFFF2EFE8);
  static const textMuted = Color(0x9EF2EFE8);
  static const textSubtle = Color(0x66F2EFE8);
  static const textInverse = Color(0xFF1B1A17);

  static const primary = Color(0xFF7D859F);
  static const primarySoft = Color(0xFF2F333D);
  static const primaryOn = Color(0xFF12110F);

  static const danger = Color(0xFFFF645F);
  static const dangerSoft = Color(0xFF551112);
  static const warning = Color(0xFFEBA941);
  static const warningSoft = Color(0xFF4A2B00);
  static const success = Color(0xFF69BA7C);
  static const successSoft = Color(0xFF033816);
  static const info = Color(0xFF67ADDD);
  static const infoSoft = Color(0xFF003151);
}

class AppTaskColorsLight {
  AppTaskColorsLight._();

  static const slateBase = Color(0xFF68718A);
  static const slateSoft = Color(0xFFE4E8F2);
  static const slateOn = Color(0xFF3F475E);

  static const redBase = Color(0xFFD15C56);
  static const redSoft = Color(0xFFFFE2DE);
  static const redOn = Color(0xFF972527);

  static const blueBase = Color(0xFF348DCF);
  static const blueSoft = Color(0xFFD9EEFF);
  static const blueOn = Color(0xFF005998);

  static const yellowBase = Color(0xFFE7B643);
  static const yellowSoft = Color(0xFFFEF0D4);
  static const yellowOn = Color(0xFF8A5700);

  static const greenBase = Color(0xFF4CA563);
  static const greenSoft = Color(0xFFDCF2DF);
  static const greenOn = Color(0xFF00682A);

  static const orangeBase = Color(0xFFE48233);
  static const orangeSoft = Color(0xFFFFE8D6);
  static const orangeOn = Color(0xFFA53E00);
}

class AppTaskColorsDark {
  AppTaskColorsDark._();

  static const slateBase = Color(0xFF858FA8);
  static const slateSoft = Color(0xFF252933);
  static const slateOn = Color(0xFFC3CDE9);

  static const redBase = Color(0xFFF2716A);
  static const redSoft = Color(0xFF4F1A18);
  static const redOn = Color(0xFFFFAEA6);

  static const blueBase = Color(0xFF4FA6E9);
  static const blueSoft = Color(0xFF003053);
  static const blueOn = Color(0xFF95D5FF);

  static const yellowBase = Color(0xFFEEBC4A);
  static const yellowSoft = Color(0xFF4A2B00);
  static const yellowOn = Color(0xFFFFD16B);

  static const greenBase = Color(0xFF62BB78);
  static const greenSoft = Color(0xFF033816);
  static const greenOn = Color(0xFF98E2A8);

  static const orangeBase = Color(0xFFF59145);
  static const orangeSoft = Color(0xFF562001);
  static const orangeOn = Color(0xFFFFC081);
}

class AppColorScheme {
  const AppColorScheme._({
    required this.bg,
    required this.bgSubtle,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.overlay,
    required this.trackBg,
    required this.shadow,
    required this.text,
    required this.textMuted,
    required this.textSubtle,
    required this.textInverse,
    required this.primary,
    required this.primaryInverse,
    required this.primarySoft,
    required this.primaryOn,
    required this.danger,
    required this.dangerSoft,
    required this.warning,
    required this.warningSoft,
    required this.success,
    required this.successSoft,
    required this.info,
    required this.infoSoft,
  });

  final Color bg;
  final Color bgSubtle;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color borderStrong;
  final Color divider;
  final Color overlay;
  final Color trackBg;
  final Color shadow;
  final Color text;
  final Color textMuted;
  final Color textSubtle;
  final Color textInverse;
  final Color primary;
  final Color primaryInverse;
  final Color primarySoft;
  final Color primaryOn;
  final Color danger;
  final Color dangerSoft;
  final Color warning;
  final Color warningSoft;
  final Color success;
  final Color successSoft;
  final Color info;
  final Color infoSoft;

  static const light = AppColorScheme._(
    bg: AppColorsLight.bg,
    bgSubtle: AppColorsLight.bgSubtle,
    surface: AppColorsLight.surface,
    surfaceAlt: AppColorsLight.surfaceAlt,
    border: AppColorsLight.border,
    borderStrong: AppColorsLight.borderStrong,
    divider: AppColorsLight.divider,
    overlay: AppColorsLight.overlay,
    trackBg: AppColorsLight.trackBg,
    shadow: AppColorsLight.shadow,
    text: AppColorsLight.text,
    textMuted: AppColorsLight.textMuted,
    textSubtle: AppColorsLight.textSubtle,
    textInverse: AppColorsLight.textInverse,
    primary: AppColorsLight.primary,
    primaryInverse: AppColorsDark.primary,
    primarySoft: AppColorsLight.primarySoft,
    primaryOn: AppColorsLight.primaryOn,
    danger: AppColorsLight.danger,
    dangerSoft: AppColorsLight.dangerSoft,
    warning: AppColorsLight.warning,
    warningSoft: AppColorsLight.warningSoft,
    success: AppColorsLight.success,
    successSoft: AppColorsLight.successSoft,
    info: AppColorsLight.info,
    infoSoft: AppColorsLight.infoSoft,
  );

  static const dark = AppColorScheme._(
    bg: AppColorsDark.bg,
    bgSubtle: AppColorsDark.bgSubtle,
    surface: AppColorsDark.surface,
    surfaceAlt: AppColorsDark.surfaceAlt,
    border: AppColorsDark.border,
    borderStrong: AppColorsDark.borderStrong,
    divider: AppColorsDark.divider,
    overlay: AppColorsDark.overlay,
    trackBg: AppColorsDark.trackBg,
    shadow: AppColorsDark.shadow,
    text: AppColorsDark.text,
    textMuted: AppColorsDark.textMuted,
    textSubtle: AppColorsDark.textSubtle,
    textInverse: AppColorsDark.textInverse,
    primary: AppColorsDark.primary,
    primaryInverse: AppColorsLight.primary,
    primarySoft: AppColorsDark.primarySoft,
    primaryOn: AppColorsDark.primaryOn,
    danger: AppColorsDark.danger,
    dangerSoft: AppColorsDark.dangerSoft,
    warning: AppColorsDark.warning,
    warningSoft: AppColorsDark.warningSoft,
    success: AppColorsDark.success,
    successSoft: AppColorsDark.successSoft,
    info: AppColorsDark.info,
    infoSoft: AppColorsDark.infoSoft,
  );
}

class AppTaskColorScheme {
  const AppTaskColorScheme._({
    required this.slateBase,
    required this.slateSoft,
    required this.slateOn,
    required this.redBase,
    required this.redSoft,
    required this.redOn,
    required this.blueBase,
    required this.blueSoft,
    required this.blueOn,
    required this.yellowBase,
    required this.yellowSoft,
    required this.yellowOn,
    required this.greenBase,
    required this.greenSoft,
    required this.greenOn,
    required this.orangeBase,
    required this.orangeSoft,
    required this.orangeOn,
  });

  final Color slateBase, slateSoft, slateOn;
  final Color redBase, redSoft, redOn;
  final Color blueBase, blueSoft, blueOn;
  final Color yellowBase, yellowSoft, yellowOn;
  final Color greenBase, greenSoft, greenOn;
  final Color orangeBase, orangeSoft, orangeOn;

  Color base(TaskColor color) => switch (color) {
    TaskColor.none => slateBase,
    TaskColor.red => redBase,
    TaskColor.blue => blueBase,
    TaskColor.yellow => yellowBase,
    TaskColor.green => greenBase,
    TaskColor.orange => orangeBase,
  };

  Color soft(TaskColor color) => switch (color) {
    TaskColor.none => slateSoft,
    TaskColor.red => redSoft,
    TaskColor.blue => blueSoft,
    TaskColor.yellow => yellowSoft,
    TaskColor.green => greenSoft,
    TaskColor.orange => orangeSoft,
  };

  Color on(TaskColor color) => switch (color) {
    TaskColor.none => slateOn,
    TaskColor.red => redOn,
    TaskColor.blue => blueOn,
    TaskColor.yellow => yellowOn,
    TaskColor.green => greenOn,
    TaskColor.orange => orangeOn,
  };

  static const light = AppTaskColorScheme._(
    slateBase: AppTaskColorsLight.slateBase,
    slateSoft: AppTaskColorsLight.slateSoft,
    slateOn: AppTaskColorsLight.slateOn,
    redBase: AppTaskColorsLight.redBase,
    redSoft: AppTaskColorsLight.redSoft,
    redOn: AppTaskColorsLight.redOn,
    blueBase: AppTaskColorsLight.blueBase,
    blueSoft: AppTaskColorsLight.blueSoft,
    blueOn: AppTaskColorsLight.blueOn,
    yellowBase: AppTaskColorsLight.yellowBase,
    yellowSoft: AppTaskColorsLight.yellowSoft,
    yellowOn: AppTaskColorsLight.yellowOn,
    greenBase: AppTaskColorsLight.greenBase,
    greenSoft: AppTaskColorsLight.greenSoft,
    greenOn: AppTaskColorsLight.greenOn,
    orangeBase: AppTaskColorsLight.orangeBase,
    orangeSoft: AppTaskColorsLight.orangeSoft,
    orangeOn: AppTaskColorsLight.orangeOn,
  );

  static const dark = AppTaskColorScheme._(
    slateBase: AppTaskColorsDark.slateBase,
    slateSoft: AppTaskColorsDark.slateSoft,
    slateOn: AppTaskColorsDark.slateOn,
    redBase: AppTaskColorsDark.redBase,
    redSoft: AppTaskColorsDark.redSoft,
    redOn: AppTaskColorsDark.redOn,
    blueBase: AppTaskColorsDark.blueBase,
    blueSoft: AppTaskColorsDark.blueSoft,
    blueOn: AppTaskColorsDark.blueOn,
    yellowBase: AppTaskColorsDark.yellowBase,
    yellowSoft: AppTaskColorsDark.yellowSoft,
    yellowOn: AppTaskColorsDark.yellowOn,
    greenBase: AppTaskColorsDark.greenBase,
    greenSoft: AppTaskColorsDark.greenSoft,
    greenOn: AppTaskColorsDark.greenOn,
    orangeBase: AppTaskColorsDark.orangeBase,
    orangeSoft: AppTaskColorsDark.orangeSoft,
    orangeOn: AppTaskColorsDark.orangeOn,
  );
}

extension TaskColorContext on TaskColor {
  Color baseColor(BuildContext context) =>
      context.appTaskColorScheme.base(this);

  Color softColor(BuildContext context) =>
      context.appTaskColorScheme.soft(this);

  Color onColor(BuildContext context) => context.appTaskColorScheme.on(this);
}

extension AppColors on BuildContext {
  AppColorScheme get appColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppColorScheme.dark
      : AppColorScheme.light;

  AppTaskColorScheme get appTaskColorScheme =>
      Theme.of(this).brightness == Brightness.dark
      ? AppTaskColorScheme.dark
      : AppTaskColorScheme.light;
}
