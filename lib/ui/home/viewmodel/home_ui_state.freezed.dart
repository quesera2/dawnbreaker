// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeUiState {

 bool get isLoading; DialogMessage? get dialogMessage; SnackBarMessage? get snackBarMessage; List<TaskItem> get tasks; String get searchQuery; HomeFilter get selectedFilter; HomeDisplayMode get displayMode; List<ColorSetting> get colorSettings; bool get progressBarAnimationEnabled;
/// Create a copy of HomeUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeUiStateCopyWith<HomeUiState> get copyWith => _$HomeUiStateCopyWithImpl<HomeUiState>(this as HomeUiState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeUiState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.dialogMessage, dialogMessage) || other.dialogMessage == dialogMessage)&&(identical(other.snackBarMessage, snackBarMessage) || other.snackBarMessage == snackBarMessage)&&const DeepCollectionEquality().equals(other.tasks, tasks)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.selectedFilter, selectedFilter) || other.selectedFilter == selectedFilter)&&(identical(other.displayMode, displayMode) || other.displayMode == displayMode)&&const DeepCollectionEquality().equals(other.colorSettings, colorSettings)&&(identical(other.progressBarAnimationEnabled, progressBarAnimationEnabled) || other.progressBarAnimationEnabled == progressBarAnimationEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,dialogMessage,snackBarMessage,const DeepCollectionEquality().hash(tasks),searchQuery,selectedFilter,displayMode,const DeepCollectionEquality().hash(colorSettings),progressBarAnimationEnabled);

@override
String toString() {
  return 'HomeUiState(isLoading: $isLoading, dialogMessage: $dialogMessage, snackBarMessage: $snackBarMessage, tasks: $tasks, searchQuery: $searchQuery, selectedFilter: $selectedFilter, displayMode: $displayMode, colorSettings: $colorSettings, progressBarAnimationEnabled: $progressBarAnimationEnabled)';
}


}

/// @nodoc
abstract mixin class $HomeUiStateCopyWith<$Res>  {
  factory $HomeUiStateCopyWith(HomeUiState value, $Res Function(HomeUiState) _then) = _$HomeUiStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, DialogMessage? dialogMessage, SnackBarMessage? snackBarMessage, List<TaskItem> tasks, String searchQuery, HomeFilter selectedFilter, HomeDisplayMode displayMode, List<ColorSetting> colorSettings, bool progressBarAnimationEnabled
});




}
/// @nodoc
class _$HomeUiStateCopyWithImpl<$Res>
    implements $HomeUiStateCopyWith<$Res> {
  _$HomeUiStateCopyWithImpl(this._self, this._then);

  final HomeUiState _self;
  final $Res Function(HomeUiState) _then;

/// Create a copy of HomeUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? dialogMessage = freezed,Object? snackBarMessage = freezed,Object? tasks = null,Object? searchQuery = null,Object? selectedFilter = null,Object? displayMode = null,Object? colorSettings = null,Object? progressBarAnimationEnabled = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,dialogMessage: freezed == dialogMessage ? _self.dialogMessage : dialogMessage // ignore: cast_nullable_to_non_nullable
as DialogMessage?,snackBarMessage: freezed == snackBarMessage ? _self.snackBarMessage : snackBarMessage // ignore: cast_nullable_to_non_nullable
as SnackBarMessage?,tasks: null == tasks ? _self.tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<TaskItem>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,selectedFilter: null == selectedFilter ? _self.selectedFilter : selectedFilter // ignore: cast_nullable_to_non_nullable
as HomeFilter,displayMode: null == displayMode ? _self.displayMode : displayMode // ignore: cast_nullable_to_non_nullable
as HomeDisplayMode,colorSettings: null == colorSettings ? _self.colorSettings : colorSettings // ignore: cast_nullable_to_non_nullable
as List<ColorSetting>,progressBarAnimationEnabled: null == progressBarAnimationEnabled ? _self.progressBarAnimationEnabled : progressBarAnimationEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeUiState].
extension HomeUiStatePatterns on HomeUiState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeUiState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeUiState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeUiState value)  $default,){
final _that = this;
switch (_that) {
case _HomeUiState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeUiState value)?  $default,){
final _that = this;
switch (_that) {
case _HomeUiState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  DialogMessage? dialogMessage,  SnackBarMessage? snackBarMessage,  List<TaskItem> tasks,  String searchQuery,  HomeFilter selectedFilter,  HomeDisplayMode displayMode,  List<ColorSetting> colorSettings,  bool progressBarAnimationEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeUiState() when $default != null:
return $default(_that.isLoading,_that.dialogMessage,_that.snackBarMessage,_that.tasks,_that.searchQuery,_that.selectedFilter,_that.displayMode,_that.colorSettings,_that.progressBarAnimationEnabled);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  DialogMessage? dialogMessage,  SnackBarMessage? snackBarMessage,  List<TaskItem> tasks,  String searchQuery,  HomeFilter selectedFilter,  HomeDisplayMode displayMode,  List<ColorSetting> colorSettings,  bool progressBarAnimationEnabled)  $default,) {final _that = this;
switch (_that) {
case _HomeUiState():
return $default(_that.isLoading,_that.dialogMessage,_that.snackBarMessage,_that.tasks,_that.searchQuery,_that.selectedFilter,_that.displayMode,_that.colorSettings,_that.progressBarAnimationEnabled);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  DialogMessage? dialogMessage,  SnackBarMessage? snackBarMessage,  List<TaskItem> tasks,  String searchQuery,  HomeFilter selectedFilter,  HomeDisplayMode displayMode,  List<ColorSetting> colorSettings,  bool progressBarAnimationEnabled)?  $default,) {final _that = this;
switch (_that) {
case _HomeUiState() when $default != null:
return $default(_that.isLoading,_that.dialogMessage,_that.snackBarMessage,_that.tasks,_that.searchQuery,_that.selectedFilter,_that.displayMode,_that.colorSettings,_that.progressBarAnimationEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _HomeUiState extends HomeUiState {
  const _HomeUiState({this.isLoading = false, this.dialogMessage, this.snackBarMessage, final  List<TaskItem> tasks = const [], this.searchQuery = '', this.selectedFilter = HomeFilter.all, this.displayMode = HomeDisplayMode.timeline, final  List<ColorSetting> colorSettings = const [], this.progressBarAnimationEnabled = true}): _tasks = tasks,_colorSettings = colorSettings,super._();
  

@override@JsonKey() final  bool isLoading;
@override final  DialogMessage? dialogMessage;
@override final  SnackBarMessage? snackBarMessage;
 final  List<TaskItem> _tasks;
@override@JsonKey() List<TaskItem> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}

@override@JsonKey() final  String searchQuery;
@override@JsonKey() final  HomeFilter selectedFilter;
@override@JsonKey() final  HomeDisplayMode displayMode;
 final  List<ColorSetting> _colorSettings;
@override@JsonKey() List<ColorSetting> get colorSettings {
  if (_colorSettings is EqualUnmodifiableListView) return _colorSettings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colorSettings);
}

@override@JsonKey() final  bool progressBarAnimationEnabled;

/// Create a copy of HomeUiState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeUiStateCopyWith<_HomeUiState> get copyWith => __$HomeUiStateCopyWithImpl<_HomeUiState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeUiState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.dialogMessage, dialogMessage) || other.dialogMessage == dialogMessage)&&(identical(other.snackBarMessage, snackBarMessage) || other.snackBarMessage == snackBarMessage)&&const DeepCollectionEquality().equals(other._tasks, _tasks)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.selectedFilter, selectedFilter) || other.selectedFilter == selectedFilter)&&(identical(other.displayMode, displayMode) || other.displayMode == displayMode)&&const DeepCollectionEquality().equals(other._colorSettings, _colorSettings)&&(identical(other.progressBarAnimationEnabled, progressBarAnimationEnabled) || other.progressBarAnimationEnabled == progressBarAnimationEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,dialogMessage,snackBarMessage,const DeepCollectionEquality().hash(_tasks),searchQuery,selectedFilter,displayMode,const DeepCollectionEquality().hash(_colorSettings),progressBarAnimationEnabled);

@override
String toString() {
  return 'HomeUiState(isLoading: $isLoading, dialogMessage: $dialogMessage, snackBarMessage: $snackBarMessage, tasks: $tasks, searchQuery: $searchQuery, selectedFilter: $selectedFilter, displayMode: $displayMode, colorSettings: $colorSettings, progressBarAnimationEnabled: $progressBarAnimationEnabled)';
}


}

/// @nodoc
abstract mixin class _$HomeUiStateCopyWith<$Res> implements $HomeUiStateCopyWith<$Res> {
  factory _$HomeUiStateCopyWith(_HomeUiState value, $Res Function(_HomeUiState) _then) = __$HomeUiStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, DialogMessage? dialogMessage, SnackBarMessage? snackBarMessage, List<TaskItem> tasks, String searchQuery, HomeFilter selectedFilter, HomeDisplayMode displayMode, List<ColorSetting> colorSettings, bool progressBarAnimationEnabled
});




}
/// @nodoc
class __$HomeUiStateCopyWithImpl<$Res>
    implements _$HomeUiStateCopyWith<$Res> {
  __$HomeUiStateCopyWithImpl(this._self, this._then);

  final _HomeUiState _self;
  final $Res Function(_HomeUiState) _then;

/// Create a copy of HomeUiState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? dialogMessage = freezed,Object? snackBarMessage = freezed,Object? tasks = null,Object? searchQuery = null,Object? selectedFilter = null,Object? displayMode = null,Object? colorSettings = null,Object? progressBarAnimationEnabled = null,}) {
  return _then(_HomeUiState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,dialogMessage: freezed == dialogMessage ? _self.dialogMessage : dialogMessage // ignore: cast_nullable_to_non_nullable
as DialogMessage?,snackBarMessage: freezed == snackBarMessage ? _self.snackBarMessage : snackBarMessage // ignore: cast_nullable_to_non_nullable
as SnackBarMessage?,tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<TaskItem>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,selectedFilter: null == selectedFilter ? _self.selectedFilter : selectedFilter // ignore: cast_nullable_to_non_nullable
as HomeFilter,displayMode: null == displayMode ? _self.displayMode : displayMode // ignore: cast_nullable_to_non_nullable
as HomeDisplayMode,colorSettings: null == colorSettings ? _self._colorSettings : colorSettings // ignore: cast_nullable_to_non_nullable
as List<ColorSetting>,progressBarAnimationEnabled: null == progressBarAnimationEnabled ? _self.progressBarAnimationEnabled : progressBarAnimationEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
