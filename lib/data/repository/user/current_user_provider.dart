import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/firebase_user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_user_provider.g.dart';

@riverpod
Future<AppUser> currentUser(Ref ref) =>
    ref.watch(userRepositoryProvider).getUser();
