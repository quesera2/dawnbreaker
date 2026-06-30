import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/core/util/furigana_translate.dart';
import 'package:dawnbreaker/data/database/app_database_provider.dart';
import 'package:dawnbreaker/data/repository/task/firestore_task_repository_impl.dart';
import 'package:dawnbreaker/data/repository/task/sqlite_task_repository_impl.dart';
import 'package:dawnbreaker/data/repository/task/task_repository.dart';
import 'package:dawnbreaker/data/repository/user/current_user_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_repository_provider.g.dart';

@riverpod
Future<TaskRepository> taskRepository(Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return switch (user) {
    LocalUser() => SQLiteTaskRepositoryImpl(
      db: ref.watch(appDatabaseProvider),
      furiganaTranslate: ref.watch(furiganaTranslateProvider),
    ),
    FirebaseAppUser(:final id) => FirestoreTaskRepositoryImpl(
      userId: id,
      furiganaTranslate: ref.watch(furiganaTranslateProvider),
      firestore: FirebaseFirestore.instance,
    ),
  };
}
