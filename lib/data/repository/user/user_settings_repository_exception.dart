sealed class UserSettingsRepositoryException implements Exception {
  const UserSettingsRepositoryException([this.message]);

  final String? message;

  @override
  String toString() => message ?? runtimeType.toString();
}

class UserSettingsLoadException extends UserSettingsRepositoryException {
  const UserSettingsLoadException([super.message]);
}

class UserSettingsSaveException extends UserSettingsRepositoryException {
  const UserSettingsSaveException([super.message]);
}

/// サインインしていないのにリポジトリを使おうとした。プログラムの誤り
class UserSettingsNotSignedInException extends UserSettingsRepositoryException {
  const UserSettingsNotSignedInException([super.message]);
}

/// 書き込もうとしたらセッションが切れていた。ダイアログは `SessionExpiry` が出す
class UserSettingsSessionExpiredException
    extends UserSettingsRepositoryException {
  const UserSettingsSessionExpiredException([super.message]);
}
