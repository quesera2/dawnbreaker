import 'package:dawnbreaker/core/logger/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'furigana_translate.g.dart';

@riverpod
FuriganaTranslate furiganaTranslate(Ref ref) => const FuriganaTranslateImpl();

abstract interface class FuriganaTranslate {
  Future<String> translate(String text);
}

class FuriganaTranslateImpl implements FuriganaTranslate {
  const FuriganaTranslateImpl();

  static const _channelName = 'que.sera.sera/furigana.translate';
  static const _methodTranslateToFurigana = 'translateToFurigana';
  static const _platform = MethodChannel(_channelName);

  @override
  Future<String> translate(String text) async {
    try {
      return await _platform.invokeMethod(_methodTranslateToFurigana, text) ??
          '';
    } on PlatformException catch (e, s) {
      logger.w('furigana translation failed', error: e, stackTrace: s);
      return '';
    } on MissingPluginException {
      return '';
    }
  }
}
