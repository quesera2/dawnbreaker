import 'package:firebase_auth/firebase_auth.dart';

/// サインイン UI を出して Firebase 用の credential を作る。
///
/// Google / Apple などプロバイダごとに実装を用意し、リポジトリはこの型を受け取って
/// signIn する。プロバイダ固有の処理は各実装に閉じる。テストではこの seam を fake に差し替える。
abstract interface class CredentialSource {
  /// サインイン UI を出して credential を返す。ユーザーが中断したら `null` を返す。
  Future<AuthCredential?> getCredential();
}
