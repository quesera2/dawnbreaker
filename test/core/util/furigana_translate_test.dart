import 'package:dawnbreaker/core/util/furigana_translate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('que.sera.sera/furigana.translate');

  late FuriganaTranslate translate;

  setUp(() {
    translate = const FuriganaTranslateImpl();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void setHandler(Future<Object?> Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  group('FuriganaTranslateImpl.translate', () {
    test('MethodChannelの結果を返す', () async {
      setHandler((_) async => 'てすと');

      expect(await translate.translate('テスト'), 'てすと');
    });

    test('MethodChannelがnullを返すとき空文字を返す', () async {
      setHandler((_) async => null);

      expect(await translate.translate('テスト'), '');
    });

    test('PlatformExceptionのとき空文字を返す', () async {
      setHandler((_) async => throw PlatformException(code: 'ERROR'));

      expect(await translate.translate('テスト'), '');
    });

    test('MissingPluginExceptionのとき空文字を返す', () async {
      setHandler((_) async => throw MissingPluginException(''));

      expect(await translate.translate('テスト'), '');
    });
  });
}
