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

 String get id;// ★ 修正: JSONにschemaVersionが無い昔のデータは「1」として読み込み、
// 新しくDart内で生成されるイベントは最新の「2(currentEventVersion)」にする魔法の記述
@JsonKey(defaultValue: 1) int get schemaVersion; Side get side;// --- 新しいDDDの意味ベース構造 ---
 StrikeType get strikeType; bool get isIppon; bool get isHansoku; bool get isFusen; bool get isHantei; bool get isUndo; bool get isRestore;@TimestampConverter() DateTime get timestamp; String? get userId; int get sequence; bool get isCanceled;// ==========================================
// ★ Phase 3-Step 1: 分散同期のためのメタデータを追加
// ==========================================
 String get deviceId;// どの端末から発火したか
 int get logicalClock;// ランポート論理時計（順序解決用）
// ==========================================
// ★ Phase 1-Step 3: ゼロトラスト（改ざん防止）のための署名
// ==========================================
 String get signature;
/// Create a copy of ScoreEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScoreEventCopyWith<ScoreEvent> get copyWith => _$ScoreEventCopyWithImpl<ScoreEvent>(this as ScoreEvent, _$identity);

  /// Serializes this ScoreEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScoreEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.side, side) || other.side == side)&&(identical(other.strikeType, strikeType) || other.strikeType == strikeType)&&(identical(other.isIppon, isIppon) || other.isIppon == isIppon)&&(identical(other.isHansoku, isHansoku) || other.isHansoku == isHansoku)&&(identical(other.isFusen, isFusen) || other.isFusen == isFusen)&&(identical(other.isHantei, isHantei) || other.isHantei == isHantei)&&(identical(other.isUndo, isUndo) || other.isUndo == isUndo)&&(identical(other.isRestore, isRestore) || other.isRestore == isRestore)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.isCanceled, isCanceled) || other.isCanceled == isCanceled)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.logicalClock, logicalClock) || other.logicalClock == logicalClock)&&(identical(other.signature, signature) || other.signature == signature));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,schemaVersion,side,strikeType,isIppon,isHansoku,isFusen,isHantei,isUndo,isRestore,timestamp,userId,sequence,isCanceled,deviceId,logicalClock,signature);

@override
String toString() {
  return 'ScoreEvent(id: $id, schemaVersion: $schemaVersion, side: $side, strikeType: $strikeType, isIppon: $isIppon, isHansoku: $isHansoku, isFusen: $isFusen, isHantei: $isHantei, isUndo: $isUndo, isRestore: $isRestore, timestamp: $timestamp, userId: $userId, sequence: $sequence, isCanceled: $isCanceled, deviceId: $deviceId, logicalClock: $logicalClock, signature: $signature)';
}


}

/// @nodoc
abstract mixin class $ScoreEventCopyWith<$Res>  {
  factory $ScoreEventCopyWith(ScoreEvent value, $Res Function(ScoreEvent) _then) = _$ScoreEventCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(defaultValue: 1) int schemaVersion, Side side, StrikeType strikeType, bool isIppon, bool isHansoku, bool isFusen, bool isHantei, bool isUndo, bool isRestore,@TimestampConverter() DateTime timestamp, String? userId, int sequence, bool isCanceled, String deviceId, int logicalClock, String signature
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? schemaVersion = null,Object? side = null,Object? strikeType = null,Object? isIppon = null,Object? isHansoku = null,Object? isFusen = null,Object? isHantei = null,Object? isUndo = null,Object? isRestore = null,Object? timestamp = null,Object? userId = freezed,Object? sequence = null,Object? isCanceled = null,Object? deviceId = null,Object? logicalClock = null,Object? signature = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as Side,strikeType: null == strikeType ? _self.strikeType : strikeType // ignore: cast_nullable_to_non_nullable
as StrikeType,isIppon: null == isIppon ? _self.isIppon : isIppon // ignore: cast_nullable_to_non_nullable
as bool,isHansoku: null == isHansoku ? _self.isHansoku : isHansoku // ignore: cast_nullable_to_non_nullable
as bool,isFusen: null == isFusen ? _self.isFusen : isFusen // ignore: cast_nullable_to_non_nullable
as bool,isHantei: null == isHantei ? _self.isHantei : isHantei // ignore: cast_nullable_to_non_nullable
as bool,isUndo: null == isUndo ? _self.isUndo : isUndo // ignore: cast_nullable_to_non_nullable
as bool,isRestore: null == isRestore ? _self.isRestore : isRestore // ignore: cast_nullable_to_non_nullable
as bool,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,isCanceled: null == isCanceled ? _self.isCanceled : isCanceled // ignore: cast_nullable_to_non_nullable
as bool,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,logicalClock: null == logicalClock ? _self.logicalClock : logicalClock // ignore: cast_nullable_to_non_nullable
as int,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(defaultValue: 1)  int schemaVersion,  Side side,  StrikeType strikeType,  bool isIppon,  bool isHansoku,  bool isFusen,  bool isHantei,  bool isUndo,  bool isRestore, @TimestampConverter()  DateTime timestamp,  String? userId,  int sequence,  bool isCanceled,  String deviceId,  int logicalClock,  String signature)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScoreEvent() when $default != null:
return $default(_that.id,_that.schemaVersion,_that.side,_that.strikeType,_that.isIppon,_that.isHansoku,_that.isFusen,_that.isHantei,_that.isUndo,_that.isRestore,_that.timestamp,_that.userId,_that.sequence,_that.isCanceled,_that.deviceId,_that.logicalClock,_that.signature);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(defaultValue: 1)  int schemaVersion,  Side side,  StrikeType strikeType,  bool isIppon,  bool isHansoku,  bool isFusen,  bool isHantei,  bool isUndo,  bool isRestore, @TimestampConverter()  DateTime timestamp,  String? userId,  int sequence,  bool isCanceled,  String deviceId,  int logicalClock,  String signature)  $default,) {final _that = this;
switch (_that) {
case _ScoreEvent():
return $default(_that.id,_that.schemaVersion,_that.side,_that.strikeType,_that.isIppon,_that.isHansoku,_that.isFusen,_that.isHantei,_that.isUndo,_that.isRestore,_that.timestamp,_that.userId,_that.sequence,_that.isCanceled,_that.deviceId,_that.logicalClock,_that.signature);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(defaultValue: 1)  int schemaVersion,  Side side,  StrikeType strikeType,  bool isIppon,  bool isHansoku,  bool isFusen,  bool isHantei,  bool isUndo,  bool isRestore, @TimestampConverter()  DateTime timestamp,  String? userId,  int sequence,  bool isCanceled,  String deviceId,  int logicalClock,  String signature)?  $default,) {final _that = this;
switch (_that) {
case _ScoreEvent() when $default != null:
return $default(_that.id,_that.schemaVersion,_that.side,_that.strikeType,_that.isIppon,_that.isHansoku,_that.isFusen,_that.isHantei,_that.isUndo,_that.isRestore,_that.timestamp,_that.userId,_that.sequence,_that.isCanceled,_that.deviceId,_that.logicalClock,_that.signature);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScoreEvent extends ScoreEvent {
  const _ScoreEvent({this.id = '', @JsonKey(defaultValue: 1) this.schemaVersion = currentEventVersion, required this.side, this.strikeType = StrikeType.none, this.isIppon = false, this.isHansoku = false, this.isFusen = false, this.isHantei = false, this.isUndo = false, this.isRestore = false, @TimestampConverter() required this.timestamp, this.userId, this.sequence = 0, this.isCanceled = false, this.deviceId = 'local_device', this.logicalClock = 0, this.signature = ''}): super._();
  factory _ScoreEvent.fromJson(Map<String, dynamic> json) => _$ScoreEventFromJson(json);

@override@JsonKey() final  String id;
// ★ 修正: JSONにschemaVersionが無い昔のデータは「1」として読み込み、
// 新しくDart内で生成されるイベントは最新の「2(currentEventVersion)」にする魔法の記述
@override@JsonKey(defaultValue: 1) final  int schemaVersion;
@override final  Side side;
// --- 新しいDDDの意味ベース構造 ---
@override@JsonKey() final  StrikeType strikeType;
@override@JsonKey() final  bool isIppon;
@override@JsonKey() final  bool isHansoku;
@override@JsonKey() final  bool isFusen;
@override@JsonKey() final  bool isHantei;
@override@JsonKey() final  bool isUndo;
@override@JsonKey() final  bool isRestore;
@override@TimestampConverter() final  DateTime timestamp;
@override final  String? userId;
@override@JsonKey() final  int sequence;
@override@JsonKey() final  bool isCanceled;
// ==========================================
// ★ Phase 3-Step 1: 分散同期のためのメタデータを追加
// ==========================================
@override@JsonKey() final  String deviceId;
// どの端末から発火したか
@override@JsonKey() final  int logicalClock;
// ランポート論理時計（順序解決用）
// ==========================================
// ★ Phase 1-Step 3: ゼロトラスト（改ざん防止）のための署名
// ==========================================
@override@JsonKey() final  String signature;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScoreEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.side, side) || other.side == side)&&(identical(other.strikeType, strikeType) || other.strikeType == strikeType)&&(identical(other.isIppon, isIppon) || other.isIppon == isIppon)&&(identical(other.isHansoku, isHansoku) || other.isHansoku == isHansoku)&&(identical(other.isFusen, isFusen) || other.isFusen == isFusen)&&(identical(other.isHantei, isHantei) || other.isHantei == isHantei)&&(identical(other.isUndo, isUndo) || other.isUndo == isUndo)&&(identical(other.isRestore, isRestore) || other.isRestore == isRestore)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.isCanceled, isCanceled) || other.isCanceled == isCanceled)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.logicalClock, logicalClock) || other.logicalClock == logicalClock)&&(identical(other.signature, signature) || other.signature == signature));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,schemaVersion,side,strikeType,isIppon,isHansoku,isFusen,isHantei,isUndo,isRestore,timestamp,userId,sequence,isCanceled,deviceId,logicalClock,signature);

@override
String toString() {
  return 'ScoreEvent(id: $id, schemaVersion: $schemaVersion, side: $side, strikeType: $strikeType, isIppon: $isIppon, isHansoku: $isHansoku, isFusen: $isFusen, isHantei: $isHantei, isUndo: $isUndo, isRestore: $isRestore, timestamp: $timestamp, userId: $userId, sequence: $sequence, isCanceled: $isCanceled, deviceId: $deviceId, logicalClock: $logicalClock, signature: $signature)';
}


}

/// @nodoc
abstract mixin class _$ScoreEventCopyWith<$Res> implements $ScoreEventCopyWith<$Res> {
  factory _$ScoreEventCopyWith(_ScoreEvent value, $Res Function(_ScoreEvent) _then) = __$ScoreEventCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(defaultValue: 1) int schemaVersion, Side side, StrikeType strikeType, bool isIppon, bool isHansoku, bool isFusen, bool isHantei, bool isUndo, bool isRestore,@TimestampConverter() DateTime timestamp, String? userId, int sequence, bool isCanceled, String deviceId, int logicalClock, String signature
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? schemaVersion = null,Object? side = null,Object? strikeType = null,Object? isIppon = null,Object? isHansoku = null,Object? isFusen = null,Object? isHantei = null,Object? isUndo = null,Object? isRestore = null,Object? timestamp = null,Object? userId = freezed,Object? sequence = null,Object? isCanceled = null,Object? deviceId = null,Object? logicalClock = null,Object? signature = null,}) {
  return _then(_ScoreEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as Side,strikeType: null == strikeType ? _self.strikeType : strikeType // ignore: cast_nullable_to_non_nullable
as StrikeType,isIppon: null == isIppon ? _self.isIppon : isIppon // ignore: cast_nullable_to_non_nullable
as bool,isHansoku: null == isHansoku ? _self.isHansoku : isHansoku // ignore: cast_nullable_to_non_nullable
as bool,isFusen: null == isFusen ? _self.isFusen : isFusen // ignore: cast_nullable_to_non_nullable
as bool,isHantei: null == isHantei ? _self.isHantei : isHantei // ignore: cast_nullable_to_non_nullable
as bool,isUndo: null == isUndo ? _self.isUndo : isUndo // ignore: cast_nullable_to_non_nullable
as bool,isRestore: null == isRestore ? _self.isRestore : isRestore // ignore: cast_nullable_to_non_nullable
as bool,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,isCanceled: null == isCanceled ? _self.isCanceled : isCanceled // ignore: cast_nullable_to_non_nullable
as bool,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,logicalClock: null == logicalClock ? _self.logicalClock : logicalClock // ignore: cast_nullable_to_non_nullable
as int,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
