// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_command.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchCommand {

 String get id; String get matchId; String get commandType; Map<String, dynamic> get payload; String get operatorId; DateTime get createdAt;
/// Create a copy of MatchCommand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchCommandCopyWith<MatchCommand> get copyWith => _$MatchCommandCopyWithImpl<MatchCommand>(this as MatchCommand, _$identity);

  /// Serializes this MatchCommand to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchCommand&&(identical(other.id, id) || other.id == id)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.commandType, commandType) || other.commandType == commandType)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.operatorId, operatorId) || other.operatorId == operatorId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,matchId,commandType,const DeepCollectionEquality().hash(payload),operatorId,createdAt);

@override
String toString() {
  return 'MatchCommand(id: $id, matchId: $matchId, commandType: $commandType, payload: $payload, operatorId: $operatorId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MatchCommandCopyWith<$Res>  {
  factory $MatchCommandCopyWith(MatchCommand value, $Res Function(MatchCommand) _then) = _$MatchCommandCopyWithImpl;
@useResult
$Res call({
 String id, String matchId, String commandType, Map<String, dynamic> payload, String operatorId, DateTime createdAt
});




}
/// @nodoc
class _$MatchCommandCopyWithImpl<$Res>
    implements $MatchCommandCopyWith<$Res> {
  _$MatchCommandCopyWithImpl(this._self, this._then);

  final MatchCommand _self;
  final $Res Function(MatchCommand) _then;

/// Create a copy of MatchCommand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? matchId = null,Object? commandType = null,Object? payload = null,Object? operatorId = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,commandType: null == commandType ? _self.commandType : commandType // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,operatorId: null == operatorId ? _self.operatorId : operatorId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchCommand].
extension MatchCommandPatterns on MatchCommand {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchCommand value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchCommand() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchCommand value)  $default,){
final _that = this;
switch (_that) {
case _MatchCommand():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchCommand value)?  $default,){
final _that = this;
switch (_that) {
case _MatchCommand() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String matchId,  String commandType,  Map<String, dynamic> payload,  String operatorId,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchCommand() when $default != null:
return $default(_that.id,_that.matchId,_that.commandType,_that.payload,_that.operatorId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String matchId,  String commandType,  Map<String, dynamic> payload,  String operatorId,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MatchCommand():
return $default(_that.id,_that.matchId,_that.commandType,_that.payload,_that.operatorId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String matchId,  String commandType,  Map<String, dynamic> payload,  String operatorId,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MatchCommand() when $default != null:
return $default(_that.id,_that.matchId,_that.commandType,_that.payload,_that.operatorId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchCommand implements MatchCommand {
  const _MatchCommand({required this.id, required this.matchId, required this.commandType, required final  Map<String, dynamic> payload, required this.operatorId, required this.createdAt}): _payload = payload;
  factory _MatchCommand.fromJson(Map<String, dynamic> json) => _$MatchCommandFromJson(json);

@override final  String id;
@override final  String matchId;
@override final  String commandType;
 final  Map<String, dynamic> _payload;
@override Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  String operatorId;
@override final  DateTime createdAt;

/// Create a copy of MatchCommand
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchCommandCopyWith<_MatchCommand> get copyWith => __$MatchCommandCopyWithImpl<_MatchCommand>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchCommandToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchCommand&&(identical(other.id, id) || other.id == id)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.commandType, commandType) || other.commandType == commandType)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.operatorId, operatorId) || other.operatorId == operatorId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,matchId,commandType,const DeepCollectionEquality().hash(_payload),operatorId,createdAt);

@override
String toString() {
  return 'MatchCommand(id: $id, matchId: $matchId, commandType: $commandType, payload: $payload, operatorId: $operatorId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MatchCommandCopyWith<$Res> implements $MatchCommandCopyWith<$Res> {
  factory _$MatchCommandCopyWith(_MatchCommand value, $Res Function(_MatchCommand) _then) = __$MatchCommandCopyWithImpl;
@override @useResult
$Res call({
 String id, String matchId, String commandType, Map<String, dynamic> payload, String operatorId, DateTime createdAt
});




}
/// @nodoc
class __$MatchCommandCopyWithImpl<$Res>
    implements _$MatchCommandCopyWith<$Res> {
  __$MatchCommandCopyWithImpl(this._self, this._then);

  final _MatchCommand _self;
  final $Res Function(_MatchCommand) _then;

/// Create a copy of MatchCommand
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? matchId = null,Object? commandType = null,Object? payload = null,Object? operatorId = null,Object? createdAt = null,}) {
  return _then(_MatchCommand(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,commandType: null == commandType ? _self.commandType : commandType // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,operatorId: null == operatorId ? _self.operatorId : operatorId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
