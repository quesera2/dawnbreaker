import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_ui_state.freezed.dart';

@freezed
abstract class HomeUiState with _$HomeUiState {
  const factory HomeUiState({
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _HomeUiState;
}
