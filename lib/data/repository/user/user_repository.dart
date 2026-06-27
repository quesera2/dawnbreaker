import 'package:dawnbreaker/core/auth/app_user.dart';

abstract interface class UserRepository {
  Future<AppUser> getUser();
}
