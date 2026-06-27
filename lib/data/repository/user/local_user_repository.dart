import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:dawnbreaker/data/repository/user/user_repository.dart';

class LocalUserRepository implements UserRepository {
  const LocalUserRepository();

  @override
  Future<AppUser> getUser() async => const LocalUser();
}
