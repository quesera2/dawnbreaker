import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FuriganaTranslate {
  const FuriganaTranslate._();

  static const _channelName = 'que.sera.sera/furigana.translate';
  static const _methodTranslateToFurigana = 'translateToFurigana';

  static const _platform = MethodChannel(_channelName);

  static Future<String?> translateToFurigana(String text) async {
    try {
      return await _platform.invokeMethod(_methodTranslateToFurigana, text);
    } on PlatformException catch (e) {
      debugPrint(e.message);
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
