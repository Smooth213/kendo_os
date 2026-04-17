// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventSettings {

 String get id; String get name; MatchFormat get defaultFormat; int get defaultDurationSeconds;
/// Create a copy of EventSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventSettingsCopyWith<EventSettings> get copyWith => _$EventSettingsCopyWithImpl<EventSettings>(this as EventSettings, _$identity);

  /// Serializes this EventSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventSettings&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.defaultFormat, defaultFormat) || other.defaultFormat == defaultFormat)&&(identical(other.defaultDurationSeconds, defaultDurationSeconds) || other.defaultDurationSeconds == defaultDurationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,defaultFormat,defaultDurationSeconds);

@override
String toString() {
  return 'EventSettings(id: $id, name: $name, defaultFormat: $defaultFormat, defaultDurationSeconds: $defaultDurationSeconds)';
}


}

/// @nodoc
abstract mixin class $EventSettingsCopyWith<$Res>  {
  factory $EventSettingsCopyWith(EventSettings value, $Res Function(EventSettings) _then) = _$EventSettingsCopyWithImpl;
@useResult
$Res call({
 String id, String name, MatchFormat defaultFormat, int defaultDurationSeconds
});




}
/// @nodoc
class _$EventSettingsCopyWithImpl<$Res>
    implements $EventSettingsCopyWith<$Res> {
  _$EventSettingsCopyWithImpl(this._self, this._then);

  final EventSettings _self;
  final $Res Function(EventSettings) _then;

/// Create a copy of EventSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? defaultFormat = null,Object? defaultDurationSeconds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,defaultFormat: null == defaultFormat ? _self.defaultFormat : defaultFormat // ignore: cast_nullable_to_non_nullable
as MatchFormat,defaultDurationSeconds: null == defaultDurationSeconds ? _self.defaultDurationSeconds : defaultDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EventSettings].
extension EventSettingsPatterns on EventSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventSettings value)  $default,){
final _that = this;
switch (_that) {
case _EventSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventSettings value)?  $default,){
final _that = this;
switch (_that) {
case _EventSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  MatchFormat defaultFormat,  int defaultDurationSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventSettings() when $default != null:
return $default(_that.id,_that.name,_that.defaultFormat,_that.defaultDurationSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  MatchFormat defaultFormat,  int defaultDurationSeconds)  $default,) {final _that = this;
switch (_that) {
case _EventSettings():
return $default(_that.id,_that.name,_that.defaultFormat,_that.defaultDurationSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  MatchFormat defaultFormat,  int defaultDurationSeconds)?  $default,) {final _that = this;
switch (_that) {
case _EventSettings() when $default != null:
return $default(_that.id,_that.name,_that.defaultFormat,_that.defaultDurationSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventSettings implements EventSettings {
  const _EventSettings({this.id = 'test_event_v2', this.name = '新規大会', this.defaultFormat = MatchFormat.individual, this.defaultDurationSeconds = 180});
  factory _EventSettings.fromJson(Map<String, dynamic> json) => _$EventSettingsFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  MatchFormat defaultFormat;
@override@JsonKey() final  int defaultDurationSeconds;

/// Create a copy of EventSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventSettingsCopyWith<_EventSettings> get copyWith => __$EventSettingsCopyWithImpl<_EventSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventSettings&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.defaultFormat, defaultFormat) || other.defaultFormat == defaultFormat)&&(identical(other.defaultDurationSeconds, defaultDurationSeconds) || other.defaultDurationSeconds == defaultDurationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,defaultFormat,defaultDurationSeconds);

@override
String toString() {
  return 'EventSettings(id: $id, name: $name, defaultFormat: $defaultFormat, defaultDurationSeconds: $defaultDurationSeconds)';
}


}

/// @nodoc
abstract mixin class _$EventSettingsCopyWith<$Res> implements $EventSettingsCopyWith<$Res> {
  factory _$EventSettingsCopyWith(_EventSettings value, $Res Function(_EventSettings) _then) = __$EventSettingsCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, MatchFormat defaultFormat, int defaultDurationSeconds
});




}
/// @nodoc
class __$EventSettingsCopyWithImpl<$Res>
    implements _$EventSettingsCopyWith<$Res> {
  __$EventSettingsCopyWithImpl(this._self, this._then);

  final _EventSettings _self;
  final $Res Function(_EventSettings) _then;

/// Create a copy of EventSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? defaultFormat = null,Object? defaultDurationSeconds = null,}) {
  return _then(_EventSettings(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,defaultFormat: null == defaultFormat ? _self.defaultFormat : defaultFormat // ignore: cast_nullable_to_non_nullable
as MatchFormat,defaultDurationSeconds: null == defaultDurationSeconds ? _self.defaultDurationSeconds : defaultDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
