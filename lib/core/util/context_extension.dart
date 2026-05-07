import 'package:dawnbreaker/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';

extension ContextExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
