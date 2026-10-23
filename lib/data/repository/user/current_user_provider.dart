import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_user_provider.g.dart';

/// アプリがいま使っているユーザー。
///
/// Firebase Auth の変化は購読しない。購読すると、他端末でアカウントが消されたときなどに
/// SDK がローカルでサインアウトした瞬間、下流のリポジトリと画面が作り直されて壊れるため。
/// ユーザーを切り替えたコード（サインイン・ログアウト・アカウント削除）が直後に
/// `ref.invalidate(currentUserProvider)` で読み直す。
/// 外から切られたセッションは、起動時・復帰時と書き込み時の確認で見つける。
///
/// 誰も見ていない間に破棄されると、次に読んだときに SDK の状態を拾い直してしまうため、
/// 読み直すまで同じ値を持ち続けるよう keepAlive にする
@Riverpod(keepAlive: true)
AppUser currentUser(Ref ref) => ref.watch(userRepositoryProvider).getUser();

/// サインイン中なら uid、未サインインなら null。
///
/// 昇格（ゲスト → リンク済み）では uid が変わらないため、uid に属するリポジトリは
/// こちらを見て、昇格で作り直されないようにする
@riverpod
String? currentUserId(Ref ref) => ref.watch(currentUserProvider).signedInId;
