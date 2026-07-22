import 'package:dawnbreaker/core/auth/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

/// `currentUserProvider` は初期値を `getUser()` から、その直後に同じ値を
/// `watchUser()` から受け取る。等価でないと起動のたびに下流が 1 度無駄に
/// 再構築されるため、値等価が保たれていることを固める
void main() {
  group('AppUser の値等価', () {
    test('同じ uid の Guest どうしは等しい', () {
      expect(const Guest('user-1'), const Guest('user-1'));
      expect(const Guest('user-1').hashCode, const Guest('user-1').hashCode);
    });

    test('uid が違う Guest どうしは等しくない', () {
      expect(const Guest('user-1'), isNot(const Guest('user-2')));
    });

    test('同じ uid の LoggedIn どうしは等しい', () {
      expect(const LoggedIn('user-1'), const LoggedIn('user-1'));
      expect(
        const LoggedIn('user-1').hashCode,
        const LoggedIn('user-1').hashCode,
      );
    });

    test('uid が同じでも Guest と LoggedIn は等しくない', () {
      expect(const Guest('user-1'), isNot(const LoggedIn('user-1')));
      expect(
        const Guest('user-1').hashCode,
        isNot(const LoggedIn('user-1').hashCode),
      );
    });

    test('NoLogin どうしは等しい', () {
      expect(const NoLogin(), const NoLogin());
      expect(const NoLogin().hashCode, const NoLogin().hashCode);
    });

    test('NoLogin はサインイン済みユーザーと等しくない', () {
      expect(const NoLogin(), isNot(const Guest('user-1')));
      expect(const NoLogin(), isNot(const LoggedIn('user-1')));
    });

    test('重複を含むリストを Set にすると同じ値がまとまる', () {
      final users = <AppUser>{}
        ..add(const Guest('user-1'))
        ..add(const Guest('user-1'))
        ..add(const LoggedIn('user-1'))
        ..add(const NoLogin())
        ..add(const NoLogin());
      expect(users, hasLength(3));
    });
  });
}
