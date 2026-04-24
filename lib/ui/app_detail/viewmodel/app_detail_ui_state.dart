import 'package:dawnbreaker/data/model/task_item.dart';
import 'package:dawnbreaker/ui/common/base_ui_state.dart';
import 'package:dawnbreaker/ui/common/error_message.dart';
import 'package:dawnbreaker/ui/common/snack_bar_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_detail_ui_state.freezed.dart';

@freezed
abstract class AppDetailUiState with _$AppDetailUiState implements BaseUiState {
  const factory AppDetailUiState({
    @Default(true) bool isLoading,
    TaskItem? task,
    @Default(false) bool shouldPop,
    @override ErrorMessage? errorMessage,
    @override SnackBarMessage? snackBarMessage,
  }) = _AppDetailUiState;
}
