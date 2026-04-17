// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuditLog {

 String get id; String get matchId; String get userId;// 誰が操作したか
 String get action;// 例: 'add_score', 'undo', 'finish', 'approved'
 String get details;// 例: '赤 メ', '試合終了'
@TimestampConverter() DateTime get timestamp;
/// Create a copy of AuditLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditLogCopyWith<AuditLog> get copyWith => _$AuditLogCopyWithImpl<AuditLog>(this as AuditLog, _$identity);

  /// Serializes this AuditLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditLog&&(identical(other.id, id) || other.id == id)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.action, action) || other.action == action)&&(identical(other.details, details) || other.details == details)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,matchId,userId,action,details,timestamp);

@override
String toString() {
  return 'AuditLog(id: $id, matchId: $matchId, userId: $userId, action: $action, details: $details, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $AuditLogCopyWith<$Res>  {
  factory $AuditLogCopyWith(AuditLog value, $Res Function(AuditLog) _then) = _$AuditLogCopyWithImpl;
@useResult
$Res call({
 String id, String matchId, String userId, String action, String details,@TimestampConverter() DateTime timestamp
});




}
/// @nodoc
class _$AuditLogCopyWithImpl<$Res>
    implements $AuditLogCopyWith<$Res> {
  _$AuditLogCopyWithImpl(this._self, this._then);

  final AuditLog _self;
  final $Res Function(AuditLog) _then;

/// Create a copy of AuditLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? matchId = null,Object? userId = null,Object? action = null,Object? details = null,Object? timestamp = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditLog].
extension AuditLogPatterns on AuditLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditLog value)  $default,){
final _that = this;
switch (_that) {
case _AuditLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditLog value)?  $default,){
final _that = this;
switch (_that) {
case _AuditLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String matchId,  String userId,  String action,  String details, @TimestampConverter()  DateTime timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditLog() when $default != null:
return $default(_that.id,_that.matchId,_that.userId,_that.action,_that.details,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String matchId,  String userId,  String action,  String details, @TimestampConverter()  DateTime timestamp)  $default,) {final _that = this;
switch (_that) {
case _AuditLog():
return $default(_that.id,_that.matchId,_that.userId,_that.action,_that.details,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String matchId,  String userId,  String action,  String details, @TimestampConverter()  DateTime timestamp)?  $default,) {final _that = this;
switch (_that) {
case _AuditLog() when $default != null:
return $default(_that.id,_that.matchId,_that.userId,_that.action,_that.details,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditLog implements AuditLog {
  const _AuditLog({required this.id, required this.matchId, required this.userId, required this.action, required this.details, @TimestampConverter() required this.timestamp});
  factory _AuditLog.fromJson(Map<String, dynamic> json) => _$AuditLogFromJson(json);

@override final  String id;
@override final  String matchId;
@override final  String userId;
// 誰が操作したか
@override final  String action;
// 例: 'add_score', 'undo', 'finish', 'approved'
@override final  String details;
// 例: '赤 メ', '試合終了'
@override@TimestampConverter() final  DateTime timestamp;

/// Create a copy of AuditLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditLogCopyWith<_AuditLog> get copyWith => __$AuditLogCopyWithImpl<_AuditLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditLog&&(identical(other.id, id) || other.id == id)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.action, action) || other.action == action)&&(identical(other.details, details) || other.details == details)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,matchId,userId,action,details,timestamp);

@override
String toString() {
  return 'AuditLog(id: $id, matchId: $matchId, userId: $userId, action: $action, details: $details, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$AuditLogCopyWith<$Res> implements $AuditLogCopyWith<$Res> {
  factory _$AuditLogCopyWith(_AuditLog value, $Res Function(_AuditLog) _then) = __$AuditLogCopyWithImpl;
@override @useResult
$Res call({
 String id, String matchId, String userId, String action, String details,@TimestampConverter() DateTime timestamp
});




}
/// @nodoc
class __$AuditLogCopyWithImpl<$Res>
    implements _$AuditLogCopyWith<$Res> {
  __$AuditLogCopyWithImpl(this._self, this._then);

  final _AuditLog _self;
  final $Res Function(_AuditLog) _then;

/// Create a copy of AuditLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? matchId = null,Object? userId = null,Object? action = null,Object? details = null,Object? timestamp = null,}) {
  return _then(_AuditLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
