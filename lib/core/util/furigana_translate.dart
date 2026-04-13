import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FuriganaTranslate {
  final platform = MethodChannel('que.sera.sera/furigana.translate');

  Future<String?> translateToFurigana(String text) async {
    try {
      return await platform.invokeMethod('translateToFurigana', text);
    } on PlatformException catch (e) {
      debugPrint(e.message);
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
