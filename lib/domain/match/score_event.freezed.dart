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

 String get id; Side get side;// ★ 新しい責務分割
 StrikeType get strikeType; bool get isIppon; bool get isHansoku; bool get isFusen; bool get isHantei;// ★ 旧コードとの互換性維持のためのフィールド（既存のDBデータ読み込み用）
 PointType get type;@TimestampConverter() DateTime get timestamp; String? get userId; int get sequence; bool get isCanceled;
/// Create a copy of ScoreEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScoreEventCopyWith<ScoreEvent> get copyWith => _$ScoreEventCopyWithImpl<ScoreEvent>(this as ScoreEvent, _$identity);

  /// Serializes this ScoreEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScoreEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.side, side) || other.side == side)&&(identical(other.strikeType, strikeType) || other.strikeType == strikeType)&&(identical(other.isIppon, isIppon) || other.isIppon == isIppon)&&(identical(other.isHansoku, isHansoku) || other.isHansoku == isHansoku)&&(identical(other.isFusen, isFusen) || other.isFusen == isFusen)&&(identical(other.isHantei, isHantei) || other.isHantei == isHantei)&&(identical(other.type, type) || other.type == type)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.isCanceled, isCanceled) || other.isCanceled == isCanceled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,side,strikeType,isIppon,isHansoku,isFusen,isHantei,type,timestamp,userId,sequence,isCanceled);

@override
String toString() {
  return 'ScoreEvent(id: $id, side: $side, strikeType: $strikeType, isIppon: $isIppon, isHansoku: $isHansoku, isFusen: $isFusen, isHantei: $isHantei, type: $type, timestamp: $timestamp, userId: $userId, sequence: $sequence, isCanceled: $isCanceled)';
}


}

/// @nodoc
abstract mixin class $ScoreEventCopyWith<$Res>  {
  factory $ScoreEventCopyWith(ScoreEvent value, $Res Function(ScoreEvent) _then) = _$ScoreEventCopyWithImpl;
@useResult
$Res call({
 String id, Side side, StrikeType strikeType, bool isIppon, bool isHansoku, bool isFusen, bool isHantei, PointType type,@TimestampConverter() DateTime timestamp, String? userId, int sequence, bool isCanceled
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? side = null,Object? strikeType = null,Object? isIppon = null,Object? isHansoku = null,Object? isFusen = null,Object? isHantei = null,Object? type = null,Object? timestamp = null,Object? userId = freezed,Object? sequence = null,Object? isCanceled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as Side,strikeType: null == strikeType ? _self.strikeType : strikeType // ignore: cast_nullable_to_non_nullable
as StrikeType,isIppon: null == isIppon ? _self.isIppon : isIppon // ignore: cast_nullable_to_non_nullable
as bool,isHansoku: null == isHansoku ? _self.isHansoku : isHansoku // ignore: cast_nullable_to_non_nullable
as bool,isFusen: null == isFusen ? _self.isFusen : isFusen // ignore: cast_nullable_to_non_nullable
as bool,isHantei: null == isHantei ? _self.isHantei : isHantei // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PointType,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,isCanceled: null == isCanceled ? _self.isCanceled : isCanceled // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Side side,  StrikeType strikeType,  bool isIppon,  bool isHansoku,  bool isFusen,  bool isHantei,  PointType type, @TimestampConverter()  DateTime timestamp,  String? userId,  int sequence,  bool isCanceled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScoreEvent() when $default != null:
return $default(_that.id,_that.side,_that.strikeType,_that.isIppon,_that.isHansoku,_that.isFusen,_that.isHantei,_that.type,_that.timestamp,_that.userId,_that.sequence,_that.isCanceled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Side side,  StrikeType strikeType,  bool isIppon,  bool isHansoku,  bool isFusen,  bool isHantei,  PointType type, @TimestampConverter()  DateTime timestamp,  String? userId,  int sequence,  bool isCanceled)  $default,) {final _that = this;
switch (_that) {
case _ScoreEvent():
return $default(_that.id,_that.side,_that.strikeType,_that.isIppon,_that.isHansoku,_that.isFusen,_that.isHantei,_that.type,_that.timestamp,_that.userId,_that.sequence,_that.isCanceled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Side side,  StrikeType strikeType,  bool isIppon,  bool isHansoku,  bool isFusen,  bool isHantei,  PointType type, @TimestampConverter()  DateTime timestamp,  String? userId,  int sequence,  bool isCanceled)?  $default,) {final _that = this;
switch (_that) {
case _ScoreEvent() when $default != null:
return $default(_that.id,_that.side,_that.strikeType,_that.isIppon,_that.isHansoku,_that.isFusen,_that.isHantei,_that.type,_that.timestamp,_that.userId,_that.sequence,_that.isCanceled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScoreEvent extends ScoreEvent {
  const _ScoreEvent({this.id = '', required this.side, this.strikeType = StrikeType.none, this.isIppon = false, this.isHansoku = false, this.isFusen = false, this.isHantei = false, required this.type, @TimestampConverter() required this.timestamp, this.userId, this.sequence = 0, this.isCanceled = false}): super._();
  factory _ScoreEvent.fromJson(Map<String, dynamic> json) => _$ScoreEventFromJson(json);

@override@JsonKey() final  String id;
@override final  Side side;
// ★ 新しい責務分割
@override@JsonKey() final  StrikeType strikeType;
@override@JsonKey() final  bool isIppon;
@override@JsonKey() final  bool isHansoku;
@override@JsonKey() final  bool isFusen;
@override@JsonKey() final  bool isHantei;
// ★ 旧コードとの互換性維持のためのフィールド（既存のDBデータ読み込み用）
@override final  PointType type;
@override@TimestampConverter() final  DateTime timestamp;
@override final  String? userId;
@override@JsonKey() final  int sequence;
@override@JsonKey() final  bool isCanceled;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScoreEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.side, side) || other.side == side)&&(identical(other.strikeType, strikeType) || other.strikeType == strikeType)&&(identical(other.isIppon, isIppon) || other.isIppon == isIppon)&&(identical(other.isHansoku, isHansoku) || other.isHansoku == isHansoku)&&(identical(other.isFusen, isFusen) || other.isFusen == isFusen)&&(identical(other.isHantei, isHantei) || other.isHantei == isHantei)&&(identical(other.type, type) || other.type == type)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.isCanceled, isCanceled) || other.isCanceled == isCanceled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,side,strikeType,isIppon,isHansoku,isFusen,isHantei,type,timestamp,userId,sequence,isCanceled);

@override
String toString() {
  return 'ScoreEvent(id: $id, side: $side, strikeType: $strikeType, isIppon: $isIppon, isHansoku: $isHansoku, isFusen: $isFusen, isHantei: $isHantei, type: $type, timestamp: $timestamp, userId: $userId, sequence: $sequence, isCanceled: $isCanceled)';
}


}

/// @nodoc
abstract mixin class _$ScoreEventCopyWith<$Res> implements $ScoreEventCopyWith<$Res> {
  factory _$ScoreEventCopyWith(_ScoreEvent value, $Res Function(_ScoreEvent) _then) = __$ScoreEventCopyWithImpl;
@override @useResult
$Res call({
 String id, Side side, StrikeType strikeType, bool isIppon, bool isHansoku, bool isFusen, bool isHantei, PointType type,@TimestampConverter() DateTime timestamp, String? userId, int sequence, bool isCanceled
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? side = null,Object? strikeType = null,Object? isIppon = null,Object? isHansoku = null,Object? isFusen = null,Object? isHantei = null,Object? type = null,Object? timestamp = null,Object? userId = freezed,Object? sequence = null,Object? isCanceled = null,}) {
  return _then(_ScoreEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as Side,strikeType: null == strikeType ? _self.strikeType : strikeType // ignore: cast_nullable_to_non_nullable
as StrikeType,isIppon: null == isIppon ? _self.isIppon : isIppon // ignore: cast_nullable_to_non_nullable
as bool,isHansoku: null == isHansoku ? _self.isHansoku : isHansoku // ignore: cast_nullable_to_non_nullable
as bool,isFusen: null == isFusen ? _self.isFusen : isFusen // ignore: cast_nullable_to_non_nullable
as bool,isHantei: null == isHantei ? _self.isHantei : isHantei // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PointType,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,isCanceled: null == isCanceled ? _self.isCanceled : isCanceled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
