// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'score_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScoreEvent {

 String get id; Side get side;// ★ String から Side(Enum) へ変更
 PointType get type;@TimestampConverter() DateTime get timestamp; String? get userId; int get sequence;
/// Create a copy of ScoreEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScoreEventCopyWith<ScoreEvent> get copyWith => _$ScoreEventCopyWithImpl<ScoreEvent>(this as ScoreEvent, _$identity);

  /// Serializes this ScoreEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScoreEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.side, side) || other.side == side)&&(identical(other.type, type) || other.type == type)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sequence, sequence) || other.sequence == sequence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,side,type,timestamp,userId,sequence);

@override
String toString() {
  return 'ScoreEvent(id: $id, side: $side, type: $type, timestamp: $timestamp, userId: $userId, sequence: $sequence)';
}


}

/// @nodoc
abstract mixin class $ScoreEventCopyWith<$Res>  {
  factory $ScoreEventCopyWith(ScoreEvent value, $Res Function(ScoreEvent) _then) = _$ScoreEventCopyWithImpl;
@useResult
$Res call({
 String id, Side side, PointType type,@TimestampConverter() DateTime timestamp, String? userId, int sequence
});




}
/// @nodoc
class _$ScoreEventCopyWithImpl<$Res>
    implements $ScoreEventCopyWith<$Res> {
  _$ScoreEventCopyWithImpl(this._self, this._then);

  final ScoreEvent _self;
  final $Res Function(ScoreEvent) _then;

/// Create a copy of ScoreEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? side = null,Object? type = null,Object? timestamp = null,Object? userId = freezed,Object? sequence = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as Side,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PointType,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ScoreEvent].
extension ScoreEventPatterns on ScoreEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScoreEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScoreEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScoreEvent value)  $default,){
final _that = this;
switch (_that) {
case _ScoreEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScoreEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ScoreEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Side side,  PointType type, @TimestampConverter()  DateTime timestamp,  String? userId,  int sequence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScoreEvent() when $default != null:
return $default(_that.id,_that.side,_that.type,_that.timestamp,_that.userId,_that.sequence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Side side,  PointType type, @TimestampConverter()  DateTime timestamp,  String? userId,  int sequence)  $default,) {final _that = this;
switch (_that) {
case _ScoreEvent():
return $default(_that.id,_that.side,_that.type,_that.timestamp,_that.userId,_that.sequence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Side side,  PointType type, @TimestampConverter()  DateTime timestamp,  String? userId,  int sequence)?  $default,) {final _that = this;
switch (_that) {
case _ScoreEvent() when $default != null:
return $default(_that.id,_that.side,_that.type,_that.timestamp,_that.userId,_that.sequence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScoreEvent implements ScoreEvent {
  const _ScoreEvent({this.id = '', required this.side, required this.type, @TimestampConverter() required this.timestamp, this.userId, this.sequence = 0});
  factory _ScoreEvent.fromJson(Map<String, dynamic> json) => _$ScoreEventFromJson(json);

@override@JsonKey() final  String id;
@override final  Side side;
// ★ String から Side(Enum) へ変更
@override final  PointType type;
@override@TimestampConverter() final  DateTime timestamp;
@override final  String? userId;
@override@JsonKey() final  int sequence;

/// Create a copy of ScoreEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScoreEventCopyWith<_ScoreEvent> get copyWith => __$ScoreEventCopyWithImpl<_ScoreEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScoreEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScoreEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.side, side) || other.side == side)&&(identical(other.type, type) || other.type == type)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sequence, sequence) || other.sequence == sequence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,side,type,timestamp,userId,sequence);

@override
String toString() {
  return 'ScoreEvent(id: $id, side: $side, type: $type, timestamp: $timestamp, userId: $userId, sequence: $sequence)';
}


}

/// @nodoc
abstract mixin class _$ScoreEventCopyWith<$Res> implements $ScoreEventCopyWith<$Res> {
  factory _$ScoreEventCopyWith(_ScoreEvent value, $Res Function(_ScoreEvent) _then) = __$ScoreEventCopyWithImpl;
@override @useResult
$Res call({
 String id, Side side, PointType type,@TimestampConverter() DateTime timestamp, String? userId, int sequence
});




}
/// @nodoc
class __$ScoreEventCopyWithImpl<$Res>
    implements _$ScoreEventCopyWith<$Res> {
  __$ScoreEventCopyWithImpl(this._self, this._then);

  final _ScoreEvent _self;
  final $Res Function(_ScoreEvent) _then;

/// Create a copy of ScoreEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? side = null,Object? type = null,Object? timestamp = null,Object? userId = freezed,Object? sequence = null,}) {
  return _then(_ScoreEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as Side,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PointType,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
