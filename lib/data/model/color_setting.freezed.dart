// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'color_setting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ColorSetting {

 TaskColor get color; String get alias; int get order;
/// Create a copy of ColorSetting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ColorSettingCopyWith<ColorSetting> get copyWith => _$ColorSettingCopyWithImpl<ColorSetting>(this as ColorSetting, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ColorSetting&&(identical(other.color, color) || other.color == color)&&(identical(other.alias, alias) || other.alias == alias)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,color,alias,order);

@override
String toString() {
  return 'ColorSetting(color: $color, alias: $alias, order: $order)';
}


}

/// @nodoc
abstract mixin class $ColorSettingCopyWith<$Res>  {
  factory $ColorSettingCopyWith(ColorSetting value, $Res Function(ColorSetting) _then) = _$ColorSettingCopyWithImpl;
@useResult
$Res call({
 TaskColor color, String alias, int order
});




}
/// @nodoc
class _$ColorSettingCopyWithImpl<$Res>
    implements $ColorSettingCopyWith<$Res> {
  _$ColorSettingCopyWithImpl(this._self, this._then);

  final ColorSetting _self;
  final $Res Function(ColorSetting) _then;

/// Create a copy of ColorSetting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? color = null,Object? alias = null,Object? order = null,}) {
  return _then(_self.copyWith(
color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as TaskColor,alias: null == alias ? _self.alias : alias // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ColorSetting].
extension ColorSettingPatterns on ColorSetting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ColorSetting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ColorSetting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ColorSetting value)  $default,){
final _that = this;
switch (_that) {
case _ColorSetting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ColorSetting value)?  $default,){
final _that = this;
switch (_that) {
case _ColorSetting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TaskColor color,  String alias,  int order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ColorSetting() when $default != null:
return $default(_that.color,_that.alias,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TaskColor color,  String alias,  int order)  $default,) {final _that = this;
switch (_that) {
case _ColorSetting():
return $default(_that.color,_that.alias,_that.order);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TaskColor color,  String alias,  int order)?  $default,) {final _that = this;
switch (_that) {
case _ColorSetting() when $default != null:
return $default(_that.color,_that.alias,_that.order);case _:
  return null;

}
}

}

/// @nodoc


class _ColorSetting extends ColorSetting {
  const _ColorSetting({required this.color, this.alias = '', required this.order}): super._();
  

@override final  TaskColor color;
@override@JsonKey() final  String alias;
@override final  int order;

/// Create a copy of ColorSetting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ColorSettingCopyWith<_ColorSetting> get copyWith => __$ColorSettingCopyWithImpl<_ColorSetting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ColorSetting&&(identical(other.color, color) || other.color == color)&&(identical(other.alias, alias) || other.alias == alias)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,color,alias,order);

@override
String toString() {
  return 'ColorSetting(color: $color, alias: $alias, order: $order)';
}


}

/// @nodoc
abstract mixin class _$ColorSettingCopyWith<$Res> implements $ColorSettingCopyWith<$Res> {
  factory _$ColorSettingCopyWith(_ColorSetting value, $Res Function(_ColorSetting) _then) = __$ColorSettingCopyWithImpl;
@override @useResult
$Res call({
 TaskColor color, String alias, int order
});




}
/// @nodoc
class __$ColorSettingCopyWithImpl<$Res>
    implements _$ColorSettingCopyWith<$Res> {
  __$ColorSettingCopyWithImpl(this._self, this._then);

  final _ColorSetting _self;
  final $Res Function(_ColorSetting) _then;

/// Create a copy of ColorSetting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? color = null,Object? alias = null,Object? order = null,}) {
  return _then(_ColorSetting(
color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as TaskColor,alias: null == alias ? _self.alias : alias // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
