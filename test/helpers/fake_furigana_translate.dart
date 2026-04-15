import 'package:dawnbreaker/core/util/furigana_translate.dart';

class FakeFuriganaTranslate extends FuriganaTranslate {
  const FakeFuriganaTranslate(this._map);

  final Map<String, String> _map;

  @override
  Future<String?> translate(String text) async => _map[text];
}