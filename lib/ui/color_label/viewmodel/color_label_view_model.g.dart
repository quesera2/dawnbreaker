// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'color_label_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ColorLabelViewModel)
final colorLabelViewModelProvider = ColorLabelViewModelProvider._();

final class ColorLabelViewModelProvider
    extends $NotifierProvider<ColorLabelViewModel, ColorLabelUiState> {
  ColorLabelViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'colorLabelViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$colorLabelViewModelHash();

  @$internal
  @override
  ColorLabelViewModel create() => ColorLabelViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ColorLabelUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ColorLabelUiState>(value),
    );
  }
}

String _$colorLabelViewModelHash() =>
    r'3c1288a6ee416298955a076dfedc418946e727d1';

abstract class _$ColorLabelViewModel extends $Notifier<ColorLabelUiState> {
  ColorLabelUiState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ColorLabelUiState, ColorLabelUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ColorLabelUiState, ColorLabelUiState>,
              ColorLabelUiState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
