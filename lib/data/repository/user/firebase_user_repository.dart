import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_user_repository.g.dart';

@riverpod
UserRepository userRepository(Ref ref) => FirebaseUserRepository();

class FirebaseUserRepository implements UserRepository {
  @override
  Future<AppUser> getUser() async {
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    if (currentUser != null) return _toAppUser(currentUser);
    final credential = await auth.signInAnonymously();
    return _toAppUser(credential.user!);
  }

  AppUser _toAppUser(User user) =>
      user.isAnonymous ? Guest(user.uid) : LoggedIn(user.uid);
}
