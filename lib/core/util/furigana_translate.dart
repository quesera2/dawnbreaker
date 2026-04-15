import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'furigana_translate.g.dart';

@riverpod
FuriganaTranslate furiganaTranslate(Ref ref) => const FuriganaTranslateImpl();

abstract class FuriganaTranslate {
  Future<String?> translate(String text);
}

class FuriganaTranslateImpl implements FuriganaTranslate {
  const FuriganaTranslateImpl();

  static const _channelName = 'que.sera.sera/furigana.translate';
  static const _methodTranslateToFurigana = 'translateToFurigana';
  static const _platform = MethodChannel(_channelName);

  @override
  Future<String?> translate(String text) async {
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
