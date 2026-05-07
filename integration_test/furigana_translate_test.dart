import 'package:dawnbreaker/core/util/furigana_translate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FuriganaTranslate translate;

  setUp(() {
    translate = const FuriganaTranslateImpl();
  });

  group('FuriganaTranslateImpl.translate', () {
    group('正常系', () {
      for (final (input, expected) in [
        ('掃除', 'そうじ'),
        ('洗濯', 'せんたく'),
        ('歯磨き', 'はみがき'),
        ('車検', 'しゃけん'),
        ('健康診断', 'けんこうしんだん'),
      ]) {
        test('$input → $expected', () async {
          expect(await translate.translate(input), expected);
        });
      }
    });

    test('空文字を渡したとき空文字を返す', () async {
      expect(await translate.translate(''), '');
    });
  });
}
