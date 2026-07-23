import 'package:dawnbreaker/firebase_options_dev.dart' as dev_options;
import 'package:dawnbreaker/firebase_options_prod.dart' as prod_options;
import 'package:firebase_core/firebase_core.dart';

/// ビルドの向き先
enum Flavor {
  dev,
  prod;

  FirebaseOptions get firebaseOptions => switch (this) {
    .dev => dev_options.DefaultFirebaseOptions.currentPlatform,
    .prod => prod_options.DefaultFirebaseOptions.currentPlatform,
  };
}
