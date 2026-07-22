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

class UserSettingsNotSignedInException extends UserSettingsRepositoryException {
  const UserSettingsNotSignedInException([super.message]);
}
