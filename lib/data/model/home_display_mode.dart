enum HomeDisplayMode {
  timeline('time_line'),
  byColor('by_color');

  const HomeDisplayMode(this.rawKey);

  final String rawKey;

  static HomeDisplayMode fromString(String rawKey) =>
      values.firstWhere((e) => e.rawKey == rawKey, orElse: () => .timeline);
}
