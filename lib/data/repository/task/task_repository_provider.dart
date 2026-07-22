import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/util/furigana_translate.dart';
import 'package:dawnbreaker/data/repository/task/firestore_task_repository_impl.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/task/task_repository_exception.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_repository_provider.g.dart';

@riverpod
Future<TaskRepository> taskRepository(Ref ref) async {
  // PR5 で同期の Provider にする。ここで変えると全 ViewModel に波及するため据え置く
  final user = ref.watch(currentUserProvider);
  return switch (user) {
    NoLogin() => throw const TaskNotSignedInException(
      'cannot read or write tasks without a signed-in user',
    ),
    SignedInUser(:final id) => FirestoreTaskRepositoryImpl(
      userId: id,
      furiganaTranslate: ref.watch(furiganaTranslateProvider),
      firestore: FirebaseFirestore.instance,
    ),
  };
}
