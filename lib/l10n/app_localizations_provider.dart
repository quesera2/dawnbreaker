import 'package:dawnbreaker/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_localizations_provider.g.dart';

@Riverpod(keepAlive: true)
class AppLocalizationsNotifier extends _$AppLocalizationsNotifier {
  @override
  Future<AppLocalizations> build() async {
    final binding = WidgetsBinding.instance;

    final observer = _LocaleObserver(() async {
      state = await AsyncValue.guard(() => _load());
    });

    binding.addObserver(observer);
    ref.onDispose(() => binding.removeObserver(observer));

    return await _load();
  }

  Future<AppLocalizations> _load() async {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final supportedLocale = basicLocaleListResolution([
      locale,
    ], AppLocalizations.supportedLocales);
    return await AppLocalizations.delegate.load(supportedLocale);
  }
}

class _LocaleObserver extends WidgetsBindingObserver {
  _LocaleObserver(this._onChanged);

  final VoidCallback _onChanged;

  @override
  void didChangeLocales(List<Locale>? locales) {
    _onChanged();
  }
}
