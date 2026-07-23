// CI 用のダミー。
//
// 実物の `lib/firebase_options_dev.dart` は FlutterFire が生成するもので
// `.gitignore` で除外しているため CI には存在しない。テストは
// `Firebase.initializeApp()` を呼ばず `flavor.dart` がコンパイルできればよいので、
// ここの値は参照されない。CI がこのファイルを `lib/` へコピーする
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'dummy',
    appId: 'dummy',
    messagingSenderId: 'dummy',
    projectId: 'dawn-breaker-dev-dummy',
  );
}
