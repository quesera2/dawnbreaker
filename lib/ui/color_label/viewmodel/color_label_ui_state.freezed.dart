// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'color_label_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ColorLabelUiState {

 bool get isLoading; List<ColorSetting> get settings; ColorLabelMode get mode; DialogMessage? get dialogMessage; SnackBarMessage? get snackBarMessage;
/// Create a copy of ColorLabelUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ColorLabelUiStateCopyWith<ColorLabelUiState> get copyWith => _$ColorLabelUiStateCopyWithImpl<ColorLabelUiState>(this as ColorLabelUiState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ColorLabelUiState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.settings, settings)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.dialogMessage, dialogMessage) || other.dialogMessage == dialogMessage)&&(identical(other.snackBarMessage, snackBarMessage) || other.snackBarMessage == snackBarMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(settings),mode,dialogMessage,snackBarMessage);

@override
String toString() {
  return 'ColorLabelUiState(isLoading: $isLoading, settings: $settings, mode: $mode, dialogMessage: $dialogMessage, snackBarMessage: $snackBarMessage)';
}


}

/// @nodoc
abstract mixin class $ColorLabelUiStateCopyWith<$Res>  {
  factory $ColorLabelUiStateCopyWith(ColorLabelUiState value, $Res Function(ColorLabelUiState) _then) = _$ColorLabelUiStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, List<ColorSetting> settings, ColorLabelMode mode, DialogMessage? dialogMessage, SnackBarMessage? snackBarMessage
});




}
/// @nodoc
class _$ColorLabelUiStateCopyWithImpl<$Res>
    implements $ColorLabelUiStateCopyWith<$Res> {
  _$ColorLabelUiStateCopyWithImpl(this._self, this._then);

  final ColorLabelUiState _self;
  final $Res Function(ColorLabelUiState) _then;

/// Create a copy of ColorLabelUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? settings = null,Object? mode = null,Object? dialogMessage = freezed,Object? snackBarMessage = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as List<ColorSetting>,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ColorLabelMode,dialogMessage: freezed == dialogMessage ? _self.dialogMessage : dialogMessage // ignore: cast_nullable_to_non_nullable
as DialogMessage?,snackBarMessage: freezed == snackBarMessage ? _self.snackBarMessage : snackBarMessage // ignore: cast_nullable_to_non_nullable
as SnackBarMessage?,
  ));
}

}


/// Adds pattern-matching-related methods to [ColorLabelUiState].
extension ColorLabelUiStatePatterns on ColorLabelUiState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ColorLabelUiState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ColorLabelUiState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ColorLabelUiState value)  $default,){
final _that = this;
switch (_that) {
case _ColorLabelUiState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ColorLabelUiState value)?  $default,){
final _that = this;
switch (_that) {
case _ColorLabelUiState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  List<ColorSetting> settings,  ColorLabelMode mode,  DialogMessage? dialogMessage,  SnackBarMessage? snackBarMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ColorLabelUiState() when $default != null:
return $default(_that.isLoading,_that.settings,_that.mode,_that.dialogMessage,_that.snackBarMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  List<ColorSetting> settings,  ColorLabelMode mode,  DialogMessage? dialogMessage,  SnackBarMessage? snackBarMessage)  $default,) {final _that = this;
switch (_that) {
case _ColorLabelUiState():
return $default(_that.isLoading,_that.settings,_that.mode,_that.dialogMessage,_that.snackBarMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  List<ColorSetting> settings,  ColorLabelMode mode,  DialogMessage? dialogMessage,  SnackBarMessage? snackBarMessage)?  $default,) {final _that = this;
switch (_that) {
case _ColorLabelUiState() when $default != null:
return $default(_that.isLoading,_that.settings,_that.mode,_that.dialogMessage,_that.snackBarMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ColorLabelUiState implements ColorLabelUiState {
  const _ColorLabelUiState({this.isLoading = true, final  List<ColorSetting> settings = const [], this.mode = ColorLabelMode.edit, this.dialogMessage, this.snackBarMessage}): _settings = settings;
  

@override@JsonKey() final  bool isLoading;
 final  List<ColorSetting> _settings;
@override@JsonKey() List<ColorSetting> get settings {
  if (_settings is EqualUnmodifiableListView) return _settings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_settings);
}

@override@JsonKey() final  ColorLabelMode mode;
@override final  DialogMessage? dialogMessage;
@override final  SnackBarMessage? snackBarMessage;

/// Create a copy of ColorLabelUiState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ColorLabelUiStateCopyWith<_ColorLabelUiState> get copyWith => __$ColorLabelUiStateCopyWithImpl<_ColorLabelUiState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ColorLabelUiState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other._settings, _settings)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.dialogMessage, dialogMessage) || other.dialogMessage == dialogMessage)&&(identical(other.snackBarMessage, snackBarMessage) || other.snackBarMessage == snackBarMessage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(_settings),mode,dialogMessage,snackBarMessage);

@override
String toString() {
  return 'ColorLabelUiState(isLoading: $isLoading, settings: $settings, mode: $mode, dialogMessage: $dialogMessage, snackBarMessage: $snackBarMessage)';
}


}

/// @nodoc
abstract mixin class _$ColorLabelUiStateCopyWith<$Res> implements $ColorLabelUiStateCopyWith<$Res> {
  factory _$ColorLabelUiStateCopyWith(_ColorLabelUiState value, $Res Function(_ColorLabelUiState) _then) = __$ColorLabelUiStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, List<ColorSetting> settings, ColorLabelMode mode, DialogMessage? dialogMessage, SnackBarMessage? snackBarMessage
});




}
/// @nodoc
class __$ColorLabelUiStateCopyWithImpl<$Res>
    implements _$ColorLabelUiStateCopyWith<$Res> {
  __$ColorLabelUiStateCopyWithImpl(this._self, this._then);

  final _ColorLabelUiState _self;
  final $Res Function(_ColorLabelUiState) _then;

/// Create a copy of ColorLabelUiState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? settings = null,Object? mode = null,Object? dialogMessage = freezed,Object? snackBarMessage = freezed,}) {
  return _then(_ColorLabelUiState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,settings: null == settings ? _self._settings : settings // ignore: cast_nullable_to_non_nullable
as List<ColorSetting>,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ColorLabelMode,dialogMessage: freezed == dialogMessage ? _self.dialogMessage : dialogMessage // ignore: cast_nullable_to_non_nullable
as DialogMessage?,snackBarMessage: freezed == snackBarMessage ? _self.snackBarMessage : snackBarMessage // ignore: cast_nullable_to_non_nullable
as SnackBarMessage?,
  ));
}


}

// dart format on
