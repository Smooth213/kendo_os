// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tournament_rule_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TimeConfig {

 double get matchTimeMinutes; bool get isRunningTime;
/// Create a copy of TimeConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeConfigCopyWith<TimeConfig> get copyWith => _$TimeConfigCopyWithImpl<TimeConfig>(this as TimeConfig, _$identity);

  /// Serializes this TimeConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeConfig&&(identical(other.matchTimeMinutes, matchTimeMinutes) || other.matchTimeMinutes == matchTimeMinutes)&&(identical(other.isRunningTime, isRunningTime) || other.isRunningTime == isRunningTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matchTimeMinutes,isRunningTime);

@override
String toString() {
  return 'TimeConfig(matchTimeMinutes: $matchTimeMinutes, isRunningTime: $isRunningTime)';
}


}

/// @nodoc
abstract mixin class $TimeConfigCopyWith<$Res>  {
  factory $TimeConfigCopyWith(TimeConfig value, $Res Function(TimeConfig) _then) = _$TimeConfigCopyWithImpl;
@useResult
$Res call({
 double matchTimeMinutes, bool isRunningTime
});




}
/// @nodoc
class _$TimeConfigCopyWithImpl<$Res>
    implements $TimeConfigCopyWith<$Res> {
  _$TimeConfigCopyWithImpl(this._self, this._then);

  final TimeConfig _self;
  final $Res Function(TimeConfig) _then;

/// Create a copy of TimeConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? matchTimeMinutes = null,Object? isRunningTime = null,}) {
  return _then(_self.copyWith(
matchTimeMinutes: null == matchTimeMinutes ? _self.matchTimeMinutes : matchTimeMinutes // ignore: cast_nullable_to_non_nullable
as double,isRunningTime: null == isRunningTime ? _self.isRunningTime : isRunningTime // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TimeConfig].
extension TimeConfigPatterns on TimeConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimeConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimeConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimeConfig value)  $default,){
final _that = this;
switch (_that) {
case _TimeConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimeConfig value)?  $default,){
final _that = this;
switch (_that) {
case _TimeConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double matchTimeMinutes,  bool isRunningTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimeConfig() when $default != null:
return $default(_that.matchTimeMinutes,_that.isRunningTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double matchTimeMinutes,  bool isRunningTime)  $default,) {final _that = this;
switch (_that) {
case _TimeConfig():
return $default(_that.matchTimeMinutes,_that.isRunningTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double matchTimeMinutes,  bool isRunningTime)?  $default,) {final _that = this;
switch (_that) {
case _TimeConfig() when $default != null:
return $default(_that.matchTimeMinutes,_that.isRunningTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimeConfig implements TimeConfig {
  const _TimeConfig({this.matchTimeMinutes = 3.0, this.isRunningTime = false});
  factory _TimeConfig.fromJson(Map<String, dynamic> json) => _$TimeConfigFromJson(json);

@override@JsonKey() final  double matchTimeMinutes;
@override@JsonKey() final  bool isRunningTime;

/// Create a copy of TimeConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimeConfigCopyWith<_TimeConfig> get copyWith => __$TimeConfigCopyWithImpl<_TimeConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimeConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimeConfig&&(identical(other.matchTimeMinutes, matchTimeMinutes) || other.matchTimeMinutes == matchTimeMinutes)&&(identical(other.isRunningTime, isRunningTime) || other.isRunningTime == isRunningTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matchTimeMinutes,isRunningTime);

@override
String toString() {
  return 'TimeConfig(matchTimeMinutes: $matchTimeMinutes, isRunningTime: $isRunningTime)';
}


}

/// @nodoc
abstract mixin class _$TimeConfigCopyWith<$Res> implements $TimeConfigCopyWith<$Res> {
  factory _$TimeConfigCopyWith(_TimeConfig value, $Res Function(_TimeConfig) _then) = __$TimeConfigCopyWithImpl;
@override @useResult
$Res call({
 double matchTimeMinutes, bool isRunningTime
});




}
/// @nodoc
class __$TimeConfigCopyWithImpl<$Res>
    implements _$TimeConfigCopyWith<$Res> {
  __$TimeConfigCopyWithImpl(this._self, this._then);

  final _TimeConfig _self;
  final $Res Function(_TimeConfig) _then;

/// Create a copy of TimeConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? matchTimeMinutes = null,Object? isRunningTime = null,}) {
  return _then(_TimeConfig(
matchTimeMinutes: null == matchTimeMinutes ? _self.matchTimeMinutes : matchTimeMinutes // ignore: cast_nullable_to_non_nullable
as double,isRunningTime: null == isRunningTime ? _self.isRunningTime : isRunningTime // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$EnchoConfig {

 bool get isEnchoUnlimited; double get enchoTimeMinutes; int get enchoCount;
/// Create a copy of EnchoConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnchoConfigCopyWith<EnchoConfig> get copyWith => _$EnchoConfigCopyWithImpl<EnchoConfig>(this as EnchoConfig, _$identity);

  /// Serializes this EnchoConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnchoConfig&&(identical(other.isEnchoUnlimited, isEnchoUnlimited) || other.isEnchoUnlimited == isEnchoUnlimited)&&(identical(other.enchoTimeMinutes, enchoTimeMinutes) || other.enchoTimeMinutes == enchoTimeMinutes)&&(identical(other.enchoCount, enchoCount) || other.enchoCount == enchoCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isEnchoUnlimited,enchoTimeMinutes,enchoCount);

@override
String toString() {
  return 'EnchoConfig(isEnchoUnlimited: $isEnchoUnlimited, enchoTimeMinutes: $enchoTimeMinutes, enchoCount: $enchoCount)';
}


}

/// @nodoc
abstract mixin class $EnchoConfigCopyWith<$Res>  {
  factory $EnchoConfigCopyWith(EnchoConfig value, $Res Function(EnchoConfig) _then) = _$EnchoConfigCopyWithImpl;
@useResult
$Res call({
 bool isEnchoUnlimited, double enchoTimeMinutes, int enchoCount
});




}
/// @nodoc
class _$EnchoConfigCopyWithImpl<$Res>
    implements $EnchoConfigCopyWith<$Res> {
  _$EnchoConfigCopyWithImpl(this._self, this._then);

  final EnchoConfig _self;
  final $Res Function(EnchoConfig) _then;

/// Create a copy of EnchoConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isEnchoUnlimited = null,Object? enchoTimeMinutes = null,Object? enchoCount = null,}) {
  return _then(_self.copyWith(
isEnchoUnlimited: null == isEnchoUnlimited ? _self.isEnchoUnlimited : isEnchoUnlimited // ignore: cast_nullable_to_non_nullable
as bool,enchoTimeMinutes: null == enchoTimeMinutes ? _self.enchoTimeMinutes : enchoTimeMinutes // ignore: cast_nullable_to_non_nullable
as double,enchoCount: null == enchoCount ? _self.enchoCount : enchoCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EnchoConfig].
extension EnchoConfigPatterns on EnchoConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnchoConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnchoConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnchoConfig value)  $default,){
final _that = this;
switch (_that) {
case _EnchoConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnchoConfig value)?  $default,){
final _that = this;
switch (_that) {
case _EnchoConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isEnchoUnlimited,  double enchoTimeMinutes,  int enchoCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnchoConfig() when $default != null:
return $default(_that.isEnchoUnlimited,_that.enchoTimeMinutes,_that.enchoCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isEnchoUnlimited,  double enchoTimeMinutes,  int enchoCount)  $default,) {final _that = this;
switch (_that) {
case _EnchoConfig():
return $default(_that.isEnchoUnlimited,_that.enchoTimeMinutes,_that.enchoCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isEnchoUnlimited,  double enchoTimeMinutes,  int enchoCount)?  $default,) {final _that = this;
switch (_that) {
case _EnchoConfig() when $default != null:
return $default(_that.isEnchoUnlimited,_that.enchoTimeMinutes,_that.enchoCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnchoConfig implements EnchoConfig {
  const _EnchoConfig({this.isEnchoUnlimited = false, this.enchoTimeMinutes = 3.0, this.enchoCount = 1});
  factory _EnchoConfig.fromJson(Map<String, dynamic> json) => _$EnchoConfigFromJson(json);

@override@JsonKey() final  bool isEnchoUnlimited;
@override@JsonKey() final  double enchoTimeMinutes;
@override@JsonKey() final  int enchoCount;

/// Create a copy of EnchoConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnchoConfigCopyWith<_EnchoConfig> get copyWith => __$EnchoConfigCopyWithImpl<_EnchoConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnchoConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnchoConfig&&(identical(other.isEnchoUnlimited, isEnchoUnlimited) || other.isEnchoUnlimited == isEnchoUnlimited)&&(identical(other.enchoTimeMinutes, enchoTimeMinutes) || other.enchoTimeMinutes == enchoTimeMinutes)&&(identical(other.enchoCount, enchoCount) || other.enchoCount == enchoCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isEnchoUnlimited,enchoTimeMinutes,enchoCount);

@override
String toString() {
  return 'EnchoConfig(isEnchoUnlimited: $isEnchoUnlimited, enchoTimeMinutes: $enchoTimeMinutes, enchoCount: $enchoCount)';
}


}

/// @nodoc
abstract mixin class _$EnchoConfigCopyWith<$Res> implements $EnchoConfigCopyWith<$Res> {
  factory _$EnchoConfigCopyWith(_EnchoConfig value, $Res Function(_EnchoConfig) _then) = __$EnchoConfigCopyWithImpl;
@override @useResult
$Res call({
 bool isEnchoUnlimited, double enchoTimeMinutes, int enchoCount
});




}
/// @nodoc
class __$EnchoConfigCopyWithImpl<$Res>
    implements _$EnchoConfigCopyWith<$Res> {
  __$EnchoConfigCopyWithImpl(this._self, this._then);

  final _EnchoConfig _self;
  final $Res Function(_EnchoConfig) _then;

/// Create a copy of EnchoConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isEnchoUnlimited = null,Object? enchoTimeMinutes = null,Object? enchoCount = null,}) {
  return _then(_EnchoConfig(
isEnchoUnlimited: null == isEnchoUnlimited ? _self.isEnchoUnlimited : isEnchoUnlimited // ignore: cast_nullable_to_non_nullable
as bool,enchoTimeMinutes: null == enchoTimeMinutes ? _self.enchoTimeMinutes : enchoTimeMinutes // ignore: cast_nullable_to_non_nullable
as double,enchoCount: null == enchoCount ? _self.enchoCount : enchoCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ScoringConfig {

 int get ipponLimit; bool get isIpponShobu;
/// Create a copy of ScoringConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScoringConfigCopyWith<ScoringConfig> get copyWith => _$ScoringConfigCopyWithImpl<ScoringConfig>(this as ScoringConfig, _$identity);

  /// Serializes this ScoringConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScoringConfig&&(identical(other.ipponLimit, ipponLimit) || other.ipponLimit == ipponLimit)&&(identical(other.isIpponShobu, isIpponShobu) || other.isIpponShobu == isIpponShobu));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ipponLimit,isIpponShobu);

@override
String toString() {
  return 'ScoringConfig(ipponLimit: $ipponLimit, isIpponShobu: $isIpponShobu)';
}


}

/// @nodoc
abstract mixin class $ScoringConfigCopyWith<$Res>  {
  factory $ScoringConfigCopyWith(ScoringConfig value, $Res Function(ScoringConfig) _then) = _$ScoringConfigCopyWithImpl;
@useResult
$Res call({
 int ipponLimit, bool isIpponShobu
});




}
/// @nodoc
class _$ScoringConfigCopyWithImpl<$Res>
    implements $ScoringConfigCopyWith<$Res> {
  _$ScoringConfigCopyWithImpl(this._self, this._then);

  final ScoringConfig _self;
  final $Res Function(ScoringConfig) _then;

/// Create a copy of ScoringConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ipponLimit = null,Object? isIpponShobu = null,}) {
  return _then(_self.copyWith(
ipponLimit: null == ipponLimit ? _self.ipponLimit : ipponLimit // ignore: cast_nullable_to_non_nullable
as int,isIpponShobu: null == isIpponShobu ? _self.isIpponShobu : isIpponShobu // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ScoringConfig].
extension ScoringConfigPatterns on ScoringConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScoringConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScoringConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScoringConfig value)  $default,){
final _that = this;
switch (_that) {
case _ScoringConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScoringConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ScoringConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int ipponLimit,  bool isIpponShobu)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScoringConfig() when $default != null:
return $default(_that.ipponLimit,_that.isIpponShobu);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int ipponLimit,  bool isIpponShobu)  $default,) {final _that = this;
switch (_that) {
case _ScoringConfig():
return $default(_that.ipponLimit,_that.isIpponShobu);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int ipponLimit,  bool isIpponShobu)?  $default,) {final _that = this;
switch (_that) {
case _ScoringConfig() when $default != null:
return $default(_that.ipponLimit,_that.isIpponShobu);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScoringConfig implements ScoringConfig {
  const _ScoringConfig({this.ipponLimit = 2, this.isIpponShobu = false});
  factory _ScoringConfig.fromJson(Map<String, dynamic> json) => _$ScoringConfigFromJson(json);

@override@JsonKey() final  int ipponLimit;
@override@JsonKey() final  bool isIpponShobu;

/// Create a copy of ScoringConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScoringConfigCopyWith<_ScoringConfig> get copyWith => __$ScoringConfigCopyWithImpl<_ScoringConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScoringConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScoringConfig&&(identical(other.ipponLimit, ipponLimit) || other.ipponLimit == ipponLimit)&&(identical(other.isIpponShobu, isIpponShobu) || other.isIpponShobu == isIpponShobu));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ipponLimit,isIpponShobu);

@override
String toString() {
  return 'ScoringConfig(ipponLimit: $ipponLimit, isIpponShobu: $isIpponShobu)';
}


}

/// @nodoc
abstract mixin class _$ScoringConfigCopyWith<$Res> implements $ScoringConfigCopyWith<$Res> {
  factory _$ScoringConfigCopyWith(_ScoringConfig value, $Res Function(_ScoringConfig) _then) = __$ScoringConfigCopyWithImpl;
@override @useResult
$Res call({
 int ipponLimit, bool isIpponShobu
});




}
/// @nodoc
class __$ScoringConfigCopyWithImpl<$Res>
    implements _$ScoringConfigCopyWith<$Res> {
  __$ScoringConfigCopyWithImpl(this._self, this._then);

  final _ScoringConfig _self;
  final $Res Function(_ScoringConfig) _then;

/// Create a copy of ScoringConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ipponLimit = null,Object? isIpponShobu = null,}) {
  return _then(_ScoringConfig(
ipponLimit: null == ipponLimit ? _self.ipponLimit : ipponLimit // ignore: cast_nullable_to_non_nullable
as int,isIpponShobu: null == isIpponShobu ? _self.isIpponShobu : isIpponShobu // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$HansokuConfig {

 int get hansokuLimit;
/// Create a copy of HansokuConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HansokuConfigCopyWith<HansokuConfig> get copyWith => _$HansokuConfigCopyWithImpl<HansokuConfig>(this as HansokuConfig, _$identity);

  /// Serializes this HansokuConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HansokuConfig&&(identical(other.hansokuLimit, hansokuLimit) || other.hansokuLimit == hansokuLimit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hansokuLimit);

@override
String toString() {
  return 'HansokuConfig(hansokuLimit: $hansokuLimit)';
}


}

/// @nodoc
abstract mixin class $HansokuConfigCopyWith<$Res>  {
  factory $HansokuConfigCopyWith(HansokuConfig value, $Res Function(HansokuConfig) _then) = _$HansokuConfigCopyWithImpl;
@useResult
$Res call({
 int hansokuLimit
});




}
/// @nodoc
class _$HansokuConfigCopyWithImpl<$Res>
    implements $HansokuConfigCopyWith<$Res> {
  _$HansokuConfigCopyWithImpl(this._self, this._then);

  final HansokuConfig _self;
  final $Res Function(HansokuConfig) _then;

/// Create a copy of HansokuConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hansokuLimit = null,}) {
  return _then(_self.copyWith(
hansokuLimit: null == hansokuLimit ? _self.hansokuLimit : hansokuLimit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HansokuConfig].
extension HansokuConfigPatterns on HansokuConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HansokuConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HansokuConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HansokuConfig value)  $default,){
final _that = this;
switch (_that) {
case _HansokuConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HansokuConfig value)?  $default,){
final _that = this;
switch (_that) {
case _HansokuConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int hansokuLimit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HansokuConfig() when $default != null:
return $default(_that.hansokuLimit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int hansokuLimit)  $default,) {final _that = this;
switch (_that) {
case _HansokuConfig():
return $default(_that.hansokuLimit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int hansokuLimit)?  $default,) {final _that = this;
switch (_that) {
case _HansokuConfig() when $default != null:
return $default(_that.hansokuLimit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HansokuConfig implements HansokuConfig {
  const _HansokuConfig({this.hansokuLimit = 2});
  factory _HansokuConfig.fromJson(Map<String, dynamic> json) => _$HansokuConfigFromJson(json);

@override@JsonKey() final  int hansokuLimit;

/// Create a copy of HansokuConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HansokuConfigCopyWith<_HansokuConfig> get copyWith => __$HansokuConfigCopyWithImpl<_HansokuConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HansokuConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HansokuConfig&&(identical(other.hansokuLimit, hansokuLimit) || other.hansokuLimit == hansokuLimit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hansokuLimit);

@override
String toString() {
  return 'HansokuConfig(hansokuLimit: $hansokuLimit)';
}


}

/// @nodoc
abstract mixin class _$HansokuConfigCopyWith<$Res> implements $HansokuConfigCopyWith<$Res> {
  factory _$HansokuConfigCopyWith(_HansokuConfig value, $Res Function(_HansokuConfig) _then) = __$HansokuConfigCopyWithImpl;
@override @useResult
$Res call({
 int hansokuLimit
});




}
/// @nodoc
class __$HansokuConfigCopyWithImpl<$Res>
    implements _$HansokuConfigCopyWith<$Res> {
  __$HansokuConfigCopyWithImpl(this._self, this._then);

  final _HansokuConfig _self;
  final $Res Function(_HansokuConfig) _then;

/// Create a copy of HansokuConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hansokuLimit = null,}) {
  return _then(_HansokuConfig(
hansokuLimit: null == hansokuLimit ? _self.hansokuLimit : hansokuLimit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TeamConfig {

 bool get isKachinuki; String get kachinukiUnlimitedType; bool get hasRepresentativeMatch; bool get isDaihyoIpponShobu;
/// Create a copy of TeamConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamConfigCopyWith<TeamConfig> get copyWith => _$TeamConfigCopyWithImpl<TeamConfig>(this as TeamConfig, _$identity);

  /// Serializes this TeamConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamConfig&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&(identical(other.kachinukiUnlimitedType, kachinukiUnlimitedType) || other.kachinukiUnlimitedType == kachinukiUnlimitedType)&&(identical(other.hasRepresentativeMatch, hasRepresentativeMatch) || other.hasRepresentativeMatch == hasRepresentativeMatch)&&(identical(other.isDaihyoIpponShobu, isDaihyoIpponShobu) || other.isDaihyoIpponShobu == isDaihyoIpponShobu));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isKachinuki,kachinukiUnlimitedType,hasRepresentativeMatch,isDaihyoIpponShobu);

@override
String toString() {
  return 'TeamConfig(isKachinuki: $isKachinuki, kachinukiUnlimitedType: $kachinukiUnlimitedType, hasRepresentativeMatch: $hasRepresentativeMatch, isDaihyoIpponShobu: $isDaihyoIpponShobu)';
}


}

/// @nodoc
abstract mixin class $TeamConfigCopyWith<$Res>  {
  factory $TeamConfigCopyWith(TeamConfig value, $Res Function(TeamConfig) _then) = _$TeamConfigCopyWithImpl;
@useResult
$Res call({
 bool isKachinuki, String kachinukiUnlimitedType, bool hasRepresentativeMatch, bool isDaihyoIpponShobu
});




}
/// @nodoc
class _$TeamConfigCopyWithImpl<$Res>
    implements $TeamConfigCopyWith<$Res> {
  _$TeamConfigCopyWithImpl(this._self, this._then);

  final TeamConfig _self;
  final $Res Function(TeamConfig) _then;

/// Create a copy of TeamConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isKachinuki = null,Object? kachinukiUnlimitedType = null,Object? hasRepresentativeMatch = null,Object? isDaihyoIpponShobu = null,}) {
  return _then(_self.copyWith(
isKachinuki: null == isKachinuki ? _self.isKachinuki : isKachinuki // ignore: cast_nullable_to_non_nullable
as bool,kachinukiUnlimitedType: null == kachinukiUnlimitedType ? _self.kachinukiUnlimitedType : kachinukiUnlimitedType // ignore: cast_nullable_to_non_nullable
as String,hasRepresentativeMatch: null == hasRepresentativeMatch ? _self.hasRepresentativeMatch : hasRepresentativeMatch // ignore: cast_nullable_to_non_nullable
as bool,isDaihyoIpponShobu: null == isDaihyoIpponShobu ? _self.isDaihyoIpponShobu : isDaihyoIpponShobu // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamConfig].
extension TeamConfigPatterns on TeamConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamConfig value)  $default,){
final _that = this;
switch (_that) {
case _TeamConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamConfig value)?  $default,){
final _that = this;
switch (_that) {
case _TeamConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isKachinuki,  String kachinukiUnlimitedType,  bool hasRepresentativeMatch,  bool isDaihyoIpponShobu)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamConfig() when $default != null:
return $default(_that.isKachinuki,_that.kachinukiUnlimitedType,_that.hasRepresentativeMatch,_that.isDaihyoIpponShobu);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isKachinuki,  String kachinukiUnlimitedType,  bool hasRepresentativeMatch,  bool isDaihyoIpponShobu)  $default,) {final _that = this;
switch (_that) {
case _TeamConfig():
return $default(_that.isKachinuki,_that.kachinukiUnlimitedType,_that.hasRepresentativeMatch,_that.isDaihyoIpponShobu);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isKachinuki,  String kachinukiUnlimitedType,  bool hasRepresentativeMatch,  bool isDaihyoIpponShobu)?  $default,) {final _that = this;
switch (_that) {
case _TeamConfig() when $default != null:
return $default(_that.isKachinuki,_that.kachinukiUnlimitedType,_that.hasRepresentativeMatch,_that.isDaihyoIpponShobu);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeamConfig implements TeamConfig {
  const _TeamConfig({this.isKachinuki = false, this.kachinukiUnlimitedType = '大将対大将', this.hasRepresentativeMatch = true, this.isDaihyoIpponShobu = true});
  factory _TeamConfig.fromJson(Map<String, dynamic> json) => _$TeamConfigFromJson(json);

@override@JsonKey() final  bool isKachinuki;
@override@JsonKey() final  String kachinukiUnlimitedType;
@override@JsonKey() final  bool hasRepresentativeMatch;
@override@JsonKey() final  bool isDaihyoIpponShobu;

/// Create a copy of TeamConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamConfigCopyWith<_TeamConfig> get copyWith => __$TeamConfigCopyWithImpl<_TeamConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamConfig&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&(identical(other.kachinukiUnlimitedType, kachinukiUnlimitedType) || other.kachinukiUnlimitedType == kachinukiUnlimitedType)&&(identical(other.hasRepresentativeMatch, hasRepresentativeMatch) || other.hasRepresentativeMatch == hasRepresentativeMatch)&&(identical(other.isDaihyoIpponShobu, isDaihyoIpponShobu) || other.isDaihyoIpponShobu == isDaihyoIpponShobu));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isKachinuki,kachinukiUnlimitedType,hasRepresentativeMatch,isDaihyoIpponShobu);

@override
String toString() {
  return 'TeamConfig(isKachinuki: $isKachinuki, kachinukiUnlimitedType: $kachinukiUnlimitedType, hasRepresentativeMatch: $hasRepresentativeMatch, isDaihyoIpponShobu: $isDaihyoIpponShobu)';
}


}

/// @nodoc
abstract mixin class _$TeamConfigCopyWith<$Res> implements $TeamConfigCopyWith<$Res> {
  factory _$TeamConfigCopyWith(_TeamConfig value, $Res Function(_TeamConfig) _then) = __$TeamConfigCopyWithImpl;
@override @useResult
$Res call({
 bool isKachinuki, String kachinukiUnlimitedType, bool hasRepresentativeMatch, bool isDaihyoIpponShobu
});




}
/// @nodoc
class __$TeamConfigCopyWithImpl<$Res>
    implements _$TeamConfigCopyWith<$Res> {
  __$TeamConfigCopyWithImpl(this._self, this._then);

  final _TeamConfig _self;
  final $Res Function(_TeamConfig) _then;

/// Create a copy of TeamConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isKachinuki = null,Object? kachinukiUnlimitedType = null,Object? hasRepresentativeMatch = null,Object? isDaihyoIpponShobu = null,}) {
  return _then(_TeamConfig(
isKachinuki: null == isKachinuki ? _self.isKachinuki : isKachinuki // ignore: cast_nullable_to_non_nullable
as bool,kachinukiUnlimitedType: null == kachinukiUnlimitedType ? _self.kachinukiUnlimitedType : kachinukiUnlimitedType // ignore: cast_nullable_to_non_nullable
as String,hasRepresentativeMatch: null == hasRepresentativeMatch ? _self.hasRepresentativeMatch : hasRepresentativeMatch // ignore: cast_nullable_to_non_nullable
as bool,isDaihyoIpponShobu: null == isDaihyoIpponShobu ? _self.isDaihyoIpponShobu : isDaihyoIpponShobu // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DrawConfig {

 bool get hasHantei;
/// Create a copy of DrawConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawConfigCopyWith<DrawConfig> get copyWith => _$DrawConfigCopyWithImpl<DrawConfig>(this as DrawConfig, _$identity);

  /// Serializes this DrawConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawConfig&&(identical(other.hasHantei, hasHantei) || other.hasHantei == hasHantei));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hasHantei);

@override
String toString() {
  return 'DrawConfig(hasHantei: $hasHantei)';
}


}

/// @nodoc
abstract mixin class $DrawConfigCopyWith<$Res>  {
  factory $DrawConfigCopyWith(DrawConfig value, $Res Function(DrawConfig) _then) = _$DrawConfigCopyWithImpl;
@useResult
$Res call({
 bool hasHantei
});




}
/// @nodoc
class _$DrawConfigCopyWithImpl<$Res>
    implements $DrawConfigCopyWith<$Res> {
  _$DrawConfigCopyWithImpl(this._self, this._then);

  final DrawConfig _self;
  final $Res Function(DrawConfig) _then;

/// Create a copy of DrawConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasHantei = null,}) {
  return _then(_self.copyWith(
hasHantei: null == hasHantei ? _self.hasHantei : hasHantei // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DrawConfig].
extension DrawConfigPatterns on DrawConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrawConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrawConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrawConfig value)  $default,){
final _that = this;
switch (_that) {
case _DrawConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrawConfig value)?  $default,){
final _that = this;
switch (_that) {
case _DrawConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hasHantei)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrawConfig() when $default != null:
return $default(_that.hasHantei);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hasHantei)  $default,) {final _that = this;
switch (_that) {
case _DrawConfig():
return $default(_that.hasHantei);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hasHantei)?  $default,) {final _that = this;
switch (_that) {
case _DrawConfig() when $default != null:
return $default(_that.hasHantei);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DrawConfig implements DrawConfig {
  const _DrawConfig({this.hasHantei = false});
  factory _DrawConfig.fromJson(Map<String, dynamic> json) => _$DrawConfigFromJson(json);

@override@JsonKey() final  bool hasHantei;

/// Create a copy of DrawConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrawConfigCopyWith<_DrawConfig> get copyWith => __$DrawConfigCopyWithImpl<_DrawConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrawConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrawConfig&&(identical(other.hasHantei, hasHantei) || other.hasHantei == hasHantei));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hasHantei);

@override
String toString() {
  return 'DrawConfig(hasHantei: $hasHantei)';
}


}

/// @nodoc
abstract mixin class _$DrawConfigCopyWith<$Res> implements $DrawConfigCopyWith<$Res> {
  factory _$DrawConfigCopyWith(_DrawConfig value, $Res Function(_DrawConfig) _then) = __$DrawConfigCopyWithImpl;
@override @useResult
$Res call({
 bool hasHantei
});




}
/// @nodoc
class __$DrawConfigCopyWithImpl<$Res>
    implements _$DrawConfigCopyWith<$Res> {
  __$DrawConfigCopyWithImpl(this._self, this._then);

  final _DrawConfig _self;
  final $Res Function(_DrawConfig) _then;

/// Create a copy of DrawConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hasHantei = null,}) {
  return _then(_DrawConfig(
hasHantei: null == hasHantei ? _self.hasHantei : hasHantei // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$TournamentRuleConfig {

 int get schemaVersion;// ★ 5-4: Versioning
 TimeConfig get time; EnchoConfig get encho; ScoringConfig get scoring; HansokuConfig get hansoku; TeamConfig get team; DrawConfig get draw;
/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TournamentRuleConfigCopyWith<TournamentRuleConfig> get copyWith => _$TournamentRuleConfigCopyWithImpl<TournamentRuleConfig>(this as TournamentRuleConfig, _$identity);

  /// Serializes this TournamentRuleConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TournamentRuleConfig&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.time, time) || other.time == time)&&(identical(other.encho, encho) || other.encho == encho)&&(identical(other.scoring, scoring) || other.scoring == scoring)&&(identical(other.hansoku, hansoku) || other.hansoku == hansoku)&&(identical(other.team, team) || other.team == team)&&(identical(other.draw, draw) || other.draw == draw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,time,encho,scoring,hansoku,team,draw);

@override
String toString() {
  return 'TournamentRuleConfig(schemaVersion: $schemaVersion, time: $time, encho: $encho, scoring: $scoring, hansoku: $hansoku, team: $team, draw: $draw)';
}


}

/// @nodoc
abstract mixin class $TournamentRuleConfigCopyWith<$Res>  {
  factory $TournamentRuleConfigCopyWith(TournamentRuleConfig value, $Res Function(TournamentRuleConfig) _then) = _$TournamentRuleConfigCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, TimeConfig time, EnchoConfig encho, ScoringConfig scoring, HansokuConfig hansoku, TeamConfig team, DrawConfig draw
});


$TimeConfigCopyWith<$Res> get time;$EnchoConfigCopyWith<$Res> get encho;$ScoringConfigCopyWith<$Res> get scoring;$HansokuConfigCopyWith<$Res> get hansoku;$TeamConfigCopyWith<$Res> get team;$DrawConfigCopyWith<$Res> get draw;

}
/// @nodoc
class _$TournamentRuleConfigCopyWithImpl<$Res>
    implements $TournamentRuleConfigCopyWith<$Res> {
  _$TournamentRuleConfigCopyWithImpl(this._self, this._then);

  final TournamentRuleConfig _self;
  final $Res Function(TournamentRuleConfig) _then;

/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? time = null,Object? encho = null,Object? scoring = null,Object? hansoku = null,Object? team = null,Object? draw = null,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as TimeConfig,encho: null == encho ? _self.encho : encho // ignore: cast_nullable_to_non_nullable
as EnchoConfig,scoring: null == scoring ? _self.scoring : scoring // ignore: cast_nullable_to_non_nullable
as ScoringConfig,hansoku: null == hansoku ? _self.hansoku : hansoku // ignore: cast_nullable_to_non_nullable
as HansokuConfig,team: null == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as TeamConfig,draw: null == draw ? _self.draw : draw // ignore: cast_nullable_to_non_nullable
as DrawConfig,
  ));
}
/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeConfigCopyWith<$Res> get time {
  
  return $TimeConfigCopyWith<$Res>(_self.time, (value) {
    return _then(_self.copyWith(time: value));
  });
}/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnchoConfigCopyWith<$Res> get encho {
  
  return $EnchoConfigCopyWith<$Res>(_self.encho, (value) {
    return _then(_self.copyWith(encho: value));
  });
}/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoringConfigCopyWith<$Res> get scoring {
  
  return $ScoringConfigCopyWith<$Res>(_self.scoring, (value) {
    return _then(_self.copyWith(scoring: value));
  });
}/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HansokuConfigCopyWith<$Res> get hansoku {
  
  return $HansokuConfigCopyWith<$Res>(_self.hansoku, (value) {
    return _then(_self.copyWith(hansoku: value));
  });
}/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamConfigCopyWith<$Res> get team {
  
  return $TeamConfigCopyWith<$Res>(_self.team, (value) {
    return _then(_self.copyWith(team: value));
  });
}/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawConfigCopyWith<$Res> get draw {
  
  return $DrawConfigCopyWith<$Res>(_self.draw, (value) {
    return _then(_self.copyWith(draw: value));
  });
}
}


/// Adds pattern-matching-related methods to [TournamentRuleConfig].
extension TournamentRuleConfigPatterns on TournamentRuleConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TournamentRuleConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TournamentRuleConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TournamentRuleConfig value)  $default,){
final _that = this;
switch (_that) {
case _TournamentRuleConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TournamentRuleConfig value)?  $default,){
final _that = this;
switch (_that) {
case _TournamentRuleConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  TimeConfig time,  EnchoConfig encho,  ScoringConfig scoring,  HansokuConfig hansoku,  TeamConfig team,  DrawConfig draw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TournamentRuleConfig() when $default != null:
return $default(_that.schemaVersion,_that.time,_that.encho,_that.scoring,_that.hansoku,_that.team,_that.draw);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  TimeConfig time,  EnchoConfig encho,  ScoringConfig scoring,  HansokuConfig hansoku,  TeamConfig team,  DrawConfig draw)  $default,) {final _that = this;
switch (_that) {
case _TournamentRuleConfig():
return $default(_that.schemaVersion,_that.time,_that.encho,_that.scoring,_that.hansoku,_that.team,_that.draw);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  TimeConfig time,  EnchoConfig encho,  ScoringConfig scoring,  HansokuConfig hansoku,  TeamConfig team,  DrawConfig draw)?  $default,) {final _that = this;
switch (_that) {
case _TournamentRuleConfig() when $default != null:
return $default(_that.schemaVersion,_that.time,_that.encho,_that.scoring,_that.hansoku,_that.team,_that.draw);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TournamentRuleConfig implements TournamentRuleConfig {
  const _TournamentRuleConfig({this.schemaVersion = 1, this.time = const TimeConfig(), this.encho = const EnchoConfig(), this.scoring = const ScoringConfig(), this.hansoku = const HansokuConfig(), this.team = const TeamConfig(), this.draw = const DrawConfig()});
  factory _TournamentRuleConfig.fromJson(Map<String, dynamic> json) => _$TournamentRuleConfigFromJson(json);

@override@JsonKey() final  int schemaVersion;
// ★ 5-4: Versioning
@override@JsonKey() final  TimeConfig time;
@override@JsonKey() final  EnchoConfig encho;
@override@JsonKey() final  ScoringConfig scoring;
@override@JsonKey() final  HansokuConfig hansoku;
@override@JsonKey() final  TeamConfig team;
@override@JsonKey() final  DrawConfig draw;

/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TournamentRuleConfigCopyWith<_TournamentRuleConfig> get copyWith => __$TournamentRuleConfigCopyWithImpl<_TournamentRuleConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TournamentRuleConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TournamentRuleConfig&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.time, time) || other.time == time)&&(identical(other.encho, encho) || other.encho == encho)&&(identical(other.scoring, scoring) || other.scoring == scoring)&&(identical(other.hansoku, hansoku) || other.hansoku == hansoku)&&(identical(other.team, team) || other.team == team)&&(identical(other.draw, draw) || other.draw == draw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,time,encho,scoring,hansoku,team,draw);

@override
String toString() {
  return 'TournamentRuleConfig(schemaVersion: $schemaVersion, time: $time, encho: $encho, scoring: $scoring, hansoku: $hansoku, team: $team, draw: $draw)';
}


}

/// @nodoc
abstract mixin class _$TournamentRuleConfigCopyWith<$Res> implements $TournamentRuleConfigCopyWith<$Res> {
  factory _$TournamentRuleConfigCopyWith(_TournamentRuleConfig value, $Res Function(_TournamentRuleConfig) _then) = __$TournamentRuleConfigCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, TimeConfig time, EnchoConfig encho, ScoringConfig scoring, HansokuConfig hansoku, TeamConfig team, DrawConfig draw
});


@override $TimeConfigCopyWith<$Res> get time;@override $EnchoConfigCopyWith<$Res> get encho;@override $ScoringConfigCopyWith<$Res> get scoring;@override $HansokuConfigCopyWith<$Res> get hansoku;@override $TeamConfigCopyWith<$Res> get team;@override $DrawConfigCopyWith<$Res> get draw;

}
/// @nodoc
class __$TournamentRuleConfigCopyWithImpl<$Res>
    implements _$TournamentRuleConfigCopyWith<$Res> {
  __$TournamentRuleConfigCopyWithImpl(this._self, this._then);

  final _TournamentRuleConfig _self;
  final $Res Function(_TournamentRuleConfig) _then;

/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? time = null,Object? encho = null,Object? scoring = null,Object? hansoku = null,Object? team = null,Object? draw = null,}) {
  return _then(_TournamentRuleConfig(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as TimeConfig,encho: null == encho ? _self.encho : encho // ignore: cast_nullable_to_non_nullable
as EnchoConfig,scoring: null == scoring ? _self.scoring : scoring // ignore: cast_nullable_to_non_nullable
as ScoringConfig,hansoku: null == hansoku ? _self.hansoku : hansoku // ignore: cast_nullable_to_non_nullable
as HansokuConfig,team: null == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as TeamConfig,draw: null == draw ? _self.draw : draw // ignore: cast_nullable_to_non_nullable
as DrawConfig,
  ));
}

/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TimeConfigCopyWith<$Res> get time {
  
  return $TimeConfigCopyWith<$Res>(_self.time, (value) {
    return _then(_self.copyWith(time: value));
  });
}/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnchoConfigCopyWith<$Res> get encho {
  
  return $EnchoConfigCopyWith<$Res>(_self.encho, (value) {
    return _then(_self.copyWith(encho: value));
  });
}/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScoringConfigCopyWith<$Res> get scoring {
  
  return $ScoringConfigCopyWith<$Res>(_self.scoring, (value) {
    return _then(_self.copyWith(scoring: value));
  });
}/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HansokuConfigCopyWith<$Res> get hansoku {
  
  return $HansokuConfigCopyWith<$Res>(_self.hansoku, (value) {
    return _then(_self.copyWith(hansoku: value));
  });
}/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamConfigCopyWith<$Res> get team {
  
  return $TeamConfigCopyWith<$Res>(_self.team, (value) {
    return _then(_self.copyWith(team: value));
  });
}/// Create a copy of TournamentRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawConfigCopyWith<$Res> get draw {
  
  return $DrawConfigCopyWith<$Res>(_self.draw, (value) {
    return _then(_self.copyWith(draw: value));
  });
}
}

// dart format on
