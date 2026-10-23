import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawnbreaker/core/auth/session_guard.dart';
import 'package:dawnbreaker/core/util/furigana_translate.dart';
import 'package:dawnbreaker/data/repository/task/firestore_task_repository_impl.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_repository_provider.g.dart';

@riverpod
TaskRepository taskRepository(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw const TaskNotSignedInException(
      'cannot read or write tasks without a signed-in user',
    );
  }
  return FirestoreTaskRepositoryImpl(
    userId: userId,
    furiganaTranslate: ref.watch(furiganaTranslateProvider),
    firestore: FirebaseFirestore.instance,
    sessionGuard: ref.watch(sessionGuardProvider),
  );
}
