// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_projection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TimelineEvent {

 String get id; DateTime get timestamp; String get side; String get actionName; bool get isImportant;
/// Create a copy of TimelineEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimelineEventCopyWith<TimelineEvent> get copyWith => _$TimelineEventCopyWithImpl<TimelineEvent>(this as TimelineEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimelineEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.side, side) || other.side == side)&&(identical(other.actionName, actionName) || other.actionName == actionName)&&(identical(other.isImportant, isImportant) || other.isImportant == isImportant));
}


@override
int get hashCode => Object.hash(runtimeType,id,timestamp,side,actionName,isImportant);

@override
String toString() {
  return 'TimelineEvent(id: $id, timestamp: $timestamp, side: $side, actionName: $actionName, isImportant: $isImportant)';
}


}

/// @nodoc
abstract mixin class $TimelineEventCopyWith<$Res>  {
  factory $TimelineEventCopyWith(TimelineEvent value, $Res Function(TimelineEvent) _then) = _$TimelineEventCopyWithImpl;
@useResult
$Res call({
 String id, DateTime timestamp, String side, String actionName, bool isImportant
});




}
/// @nodoc
class _$TimelineEventCopyWithImpl<$Res>
    implements $TimelineEventCopyWith<$Res> {
  _$TimelineEventCopyWithImpl(this._self, this._then);

  final TimelineEvent _self;
  final $Res Function(TimelineEvent) _then;

/// Create a copy of TimelineEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? timestamp = null,Object? side = null,Object? actionName = null,Object? isImportant = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as String,actionName: null == actionName ? _self.actionName : actionName // ignore: cast_nullable_to_non_nullable
as String,isImportant: null == isImportant ? _self.isImportant : isImportant // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TimelineEvent].
extension TimelineEventPatterns on TimelineEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimelineEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimelineEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimelineEvent value)  $default,){
final _that = this;
switch (_that) {
case _TimelineEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimelineEvent value)?  $default,){
final _that = this;
switch (_that) {
case _TimelineEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime timestamp,  String side,  String actionName,  bool isImportant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimelineEvent() when $default != null:
return $default(_that.id,_that.timestamp,_that.side,_that.actionName,_that.isImportant);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime timestamp,  String side,  String actionName,  bool isImportant)  $default,) {final _that = this;
switch (_that) {
case _TimelineEvent():
return $default(_that.id,_that.timestamp,_that.side,_that.actionName,_that.isImportant);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime timestamp,  String side,  String actionName,  bool isImportant)?  $default,) {final _that = this;
switch (_that) {
case _TimelineEvent() when $default != null:
return $default(_that.id,_that.timestamp,_that.side,_that.actionName,_that.isImportant);case _:
  return null;

}
}

}

/// @nodoc


class _TimelineEvent implements TimelineEvent {
  const _TimelineEvent({required this.id, required this.timestamp, required this.side, required this.actionName, required this.isImportant});
  

@override final  String id;
@override final  DateTime timestamp;
@override final  String side;
@override final  String actionName;
@override final  bool isImportant;

/// Create a copy of TimelineEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimelineEventCopyWith<_TimelineEvent> get copyWith => __$TimelineEventCopyWithImpl<_TimelineEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimelineEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.side, side) || other.side == side)&&(identical(other.actionName, actionName) || other.actionName == actionName)&&(identical(other.isImportant, isImportant) || other.isImportant == isImportant));
}


@override
int get hashCode => Object.hash(runtimeType,id,timestamp,side,actionName,isImportant);

@override
String toString() {
  return 'TimelineEvent(id: $id, timestamp: $timestamp, side: $side, actionName: $actionName, isImportant: $isImportant)';
}


}

/// @nodoc
abstract mixin class _$TimelineEventCopyWith<$Res> implements $TimelineEventCopyWith<$Res> {
  factory _$TimelineEventCopyWith(_TimelineEvent value, $Res Function(_TimelineEvent) _then) = __$TimelineEventCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime timestamp, String side, String actionName, bool isImportant
});




}
/// @nodoc
class __$TimelineEventCopyWithImpl<$Res>
    implements _$TimelineEventCopyWith<$Res> {
  __$TimelineEventCopyWithImpl(this._self, this._then);

  final _TimelineEvent _self;
  final $Res Function(_TimelineEvent) _then;

/// Create a copy of TimelineEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? timestamp = null,Object? side = null,Object? actionName = null,Object? isImportant = null,}) {
  return _then(_TimelineEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as String,actionName: null == actionName ? _self.actionName : actionName // ignore: cast_nullable_to_non_nullable
as String,isImportant: null == isImportant ? _self.isImportant : isImportant // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$MatchListProjection {

 String get id; String get tournamentId; int get matchOrder; String get matchType; String get status; String get redName; String get whiteName; int get redScore; int get whiteScore;// 集計・表示用に必須のフィールドを追加
 String get groupName; bool get isKachinuki; String get note; String get firstPointSide; List<String> get redPointMarks; List<String> get whitePointMarks;
/// Create a copy of MatchListProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchListProjectionCopyWith<MatchListProjection> get copyWith => _$MatchListProjectionCopyWithImpl<MatchListProjection>(this as MatchListProjection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchListProjection&&(identical(other.id, id) || other.id == id)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.matchOrder, matchOrder) || other.matchOrder == matchOrder)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.status, status) || other.status == status)&&(identical(other.redName, redName) || other.redName == redName)&&(identical(other.whiteName, whiteName) || other.whiteName == whiteName)&&(identical(other.redScore, redScore) || other.redScore == redScore)&&(identical(other.whiteScore, whiteScore) || other.whiteScore == whiteScore)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&(identical(other.note, note) || other.note == note)&&(identical(other.firstPointSide, firstPointSide) || other.firstPointSide == firstPointSide)&&const DeepCollectionEquality().equals(other.redPointMarks, redPointMarks)&&const DeepCollectionEquality().equals(other.whitePointMarks, whitePointMarks));
}


@override
int get hashCode => Object.hash(runtimeType,id,tournamentId,matchOrder,matchType,status,redName,whiteName,redScore,whiteScore,groupName,isKachinuki,note,firstPointSide,const DeepCollectionEquality().hash(redPointMarks),const DeepCollectionEquality().hash(whitePointMarks));

@override
String toString() {
  return 'MatchListProjection(id: $id, tournamentId: $tournamentId, matchOrder: $matchOrder, matchType: $matchType, status: $status, redName: $redName, whiteName: $whiteName, redScore: $redScore, whiteScore: $whiteScore, groupName: $groupName, isKachinuki: $isKachinuki, note: $note, firstPointSide: $firstPointSide, redPointMarks: $redPointMarks, whitePointMarks: $whitePointMarks)';
}


}

/// @nodoc
abstract mixin class $MatchListProjectionCopyWith<$Res>  {
  factory $MatchListProjectionCopyWith(MatchListProjection value, $Res Function(MatchListProjection) _then) = _$MatchListProjectionCopyWithImpl;
@useResult
$Res call({
 String id, String tournamentId, int matchOrder, String matchType, String status, String redName, String whiteName, int redScore, int whiteScore, String groupName, bool isKachinuki, String note, String firstPointSide, List<String> redPointMarks, List<String> whitePointMarks
});




}
/// @nodoc
class _$MatchListProjectionCopyWithImpl<$Res>
    implements $MatchListProjectionCopyWith<$Res> {
  _$MatchListProjectionCopyWithImpl(this._self, this._then);

  final MatchListProjection _self;
  final $Res Function(MatchListProjection) _then;

/// Create a copy of MatchListProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tournamentId = null,Object? matchOrder = null,Object? matchType = null,Object? status = null,Object? redName = null,Object? whiteName = null,Object? redScore = null,Object? whiteScore = null,Object? groupName = null,Object? isKachinuki = null,Object? note = null,Object? firstPointSide = null,Object? redPointMarks = null,Object? whitePointMarks = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tournamentId: null == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String,matchOrder: null == matchOrder ? _self.matchOrder : matchOrder // ignore: cast_nullable_to_non_nullable
as int,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,redName: null == redName ? _self.redName : redName // ignore: cast_nullable_to_non_nullable
as String,whiteName: null == whiteName ? _self.whiteName : whiteName // ignore: cast_nullable_to_non_nullable
as String,redScore: null == redScore ? _self.redScore : redScore // ignore: cast_nullable_to_non_nullable
as int,whiteScore: null == whiteScore ? _self.whiteScore : whiteScore // ignore: cast_nullable_to_non_nullable
as int,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,isKachinuki: null == isKachinuki ? _self.isKachinuki : isKachinuki // ignore: cast_nullable_to_non_nullable
as bool,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,firstPointSide: null == firstPointSide ? _self.firstPointSide : firstPointSide // ignore: cast_nullable_to_non_nullable
as String,redPointMarks: null == redPointMarks ? _self.redPointMarks : redPointMarks // ignore: cast_nullable_to_non_nullable
as List<String>,whitePointMarks: null == whitePointMarks ? _self.whitePointMarks : whitePointMarks // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchListProjection].
extension MatchListProjectionPatterns on MatchListProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchListProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchListProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchListProjection value)  $default,){
final _that = this;
switch (_that) {
case _MatchListProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchListProjection value)?  $default,){
final _that = this;
switch (_that) {
case _MatchListProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tournamentId,  int matchOrder,  String matchType,  String status,  String redName,  String whiteName,  int redScore,  int whiteScore,  String groupName,  bool isKachinuki,  String note,  String firstPointSide,  List<String> redPointMarks,  List<String> whitePointMarks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchListProjection() when $default != null:
return $default(_that.id,_that.tournamentId,_that.matchOrder,_that.matchType,_that.status,_that.redName,_that.whiteName,_that.redScore,_that.whiteScore,_that.groupName,_that.isKachinuki,_that.note,_that.firstPointSide,_that.redPointMarks,_that.whitePointMarks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tournamentId,  int matchOrder,  String matchType,  String status,  String redName,  String whiteName,  int redScore,  int whiteScore,  String groupName,  bool isKachinuki,  String note,  String firstPointSide,  List<String> redPointMarks,  List<String> whitePointMarks)  $default,) {final _that = this;
switch (_that) {
case _MatchListProjection():
return $default(_that.id,_that.tournamentId,_that.matchOrder,_that.matchType,_that.status,_that.redName,_that.whiteName,_that.redScore,_that.whiteScore,_that.groupName,_that.isKachinuki,_that.note,_that.firstPointSide,_that.redPointMarks,_that.whitePointMarks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tournamentId,  int matchOrder,  String matchType,  String status,  String redName,  String whiteName,  int redScore,  int whiteScore,  String groupName,  bool isKachinuki,  String note,  String firstPointSide,  List<String> redPointMarks,  List<String> whitePointMarks)?  $default,) {final _that = this;
switch (_that) {
case _MatchListProjection() when $default != null:
return $default(_that.id,_that.tournamentId,_that.matchOrder,_that.matchType,_that.status,_that.redName,_that.whiteName,_that.redScore,_that.whiteScore,_that.groupName,_that.isKachinuki,_that.note,_that.firstPointSide,_that.redPointMarks,_that.whitePointMarks);case _:
  return null;

}
}

}

/// @nodoc


class _MatchListProjection implements MatchListProjection {
  const _MatchListProjection({required this.id, required this.tournamentId, required this.matchOrder, required this.matchType, required this.status, required this.redName, required this.whiteName, required this.redScore, required this.whiteScore, this.groupName = '', this.isKachinuki = false, this.note = '', this.firstPointSide = '', final  List<String> redPointMarks = const [], final  List<String> whitePointMarks = const []}): _redPointMarks = redPointMarks,_whitePointMarks = whitePointMarks;
  

@override final  String id;
@override final  String tournamentId;
@override final  int matchOrder;
@override final  String matchType;
@override final  String status;
@override final  String redName;
@override final  String whiteName;
@override final  int redScore;
@override final  int whiteScore;
// 集計・表示用に必須のフィールドを追加
@override@JsonKey() final  String groupName;
@override@JsonKey() final  bool isKachinuki;
@override@JsonKey() final  String note;
@override@JsonKey() final  String firstPointSide;
 final  List<String> _redPointMarks;
@override@JsonKey() List<String> get redPointMarks {
  if (_redPointMarks is EqualUnmodifiableListView) return _redPointMarks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_redPointMarks);
}

 final  List<String> _whitePointMarks;
@override@JsonKey() List<String> get whitePointMarks {
  if (_whitePointMarks is EqualUnmodifiableListView) return _whitePointMarks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_whitePointMarks);
}


/// Create a copy of MatchListProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchListProjectionCopyWith<_MatchListProjection> get copyWith => __$MatchListProjectionCopyWithImpl<_MatchListProjection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchListProjection&&(identical(other.id, id) || other.id == id)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.matchOrder, matchOrder) || other.matchOrder == matchOrder)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.status, status) || other.status == status)&&(identical(other.redName, redName) || other.redName == redName)&&(identical(other.whiteName, whiteName) || other.whiteName == whiteName)&&(identical(other.redScore, redScore) || other.redScore == redScore)&&(identical(other.whiteScore, whiteScore) || other.whiteScore == whiteScore)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&(identical(other.note, note) || other.note == note)&&(identical(other.firstPointSide, firstPointSide) || other.firstPointSide == firstPointSide)&&const DeepCollectionEquality().equals(other._redPointMarks, _redPointMarks)&&const DeepCollectionEquality().equals(other._whitePointMarks, _whitePointMarks));
}


@override
int get hashCode => Object.hash(runtimeType,id,tournamentId,matchOrder,matchType,status,redName,whiteName,redScore,whiteScore,groupName,isKachinuki,note,firstPointSide,const DeepCollectionEquality().hash(_redPointMarks),const DeepCollectionEquality().hash(_whitePointMarks));

@override
String toString() {
  return 'MatchListProjection(id: $id, tournamentId: $tournamentId, matchOrder: $matchOrder, matchType: $matchType, status: $status, redName: $redName, whiteName: $whiteName, redScore: $redScore, whiteScore: $whiteScore, groupName: $groupName, isKachinuki: $isKachinuki, note: $note, firstPointSide: $firstPointSide, redPointMarks: $redPointMarks, whitePointMarks: $whitePointMarks)';
}


}

/// @nodoc
abstract mixin class _$MatchListProjectionCopyWith<$Res> implements $MatchListProjectionCopyWith<$Res> {
  factory _$MatchListProjectionCopyWith(_MatchListProjection value, $Res Function(_MatchListProjection) _then) = __$MatchListProjectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String tournamentId, int matchOrder, String matchType, String status, String redName, String whiteName, int redScore, int whiteScore, String groupName, bool isKachinuki, String note, String firstPointSide, List<String> redPointMarks, List<String> whitePointMarks
});




}
/// @nodoc
class __$MatchListProjectionCopyWithImpl<$Res>
    implements _$MatchListProjectionCopyWith<$Res> {
  __$MatchListProjectionCopyWithImpl(this._self, this._then);

  final _MatchListProjection _self;
  final $Res Function(_MatchListProjection) _then;

/// Create a copy of MatchListProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tournamentId = null,Object? matchOrder = null,Object? matchType = null,Object? status = null,Object? redName = null,Object? whiteName = null,Object? redScore = null,Object? whiteScore = null,Object? groupName = null,Object? isKachinuki = null,Object? note = null,Object? firstPointSide = null,Object? redPointMarks = null,Object? whitePointMarks = null,}) {
  return _then(_MatchListProjection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tournamentId: null == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String,matchOrder: null == matchOrder ? _self.matchOrder : matchOrder // ignore: cast_nullable_to_non_nullable
as int,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,redName: null == redName ? _self.redName : redName // ignore: cast_nullable_to_non_nullable
as String,whiteName: null == whiteName ? _self.whiteName : whiteName // ignore: cast_nullable_to_non_nullable
as String,redScore: null == redScore ? _self.redScore : redScore // ignore: cast_nullable_to_non_nullable
as int,whiteScore: null == whiteScore ? _self.whiteScore : whiteScore // ignore: cast_nullable_to_non_nullable
as int,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,isKachinuki: null == isKachinuki ? _self.isKachinuki : isKachinuki // ignore: cast_nullable_to_non_nullable
as bool,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,firstPointSide: null == firstPointSide ? _self.firstPointSide : firstPointSide // ignore: cast_nullable_to_non_nullable
as String,redPointMarks: null == redPointMarks ? _self._redPointMarks : redPointMarks // ignore: cast_nullable_to_non_nullable
as List<String>,whitePointMarks: null == whitePointMarks ? _self._whitePointMarks : whitePointMarks // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$MatchProjection {

 String get id; String get tournamentId; int get matchOrder; String get matchType; String get status; String get groupName; bool get isKachinuki; String get redName; String get whiteName; List<String> get redRemaining; List<String> get whiteRemaining; int get redScore; int get whiteScore; List<PointDisplay> get redDisplays; List<PointDisplay> get whiteDisplays;// ★ 復元: 公式記録画面やスコアボードで必須の表示用フィールド
 String get firstPointSide; List<String> get redPointMarks; List<String> get whitePointMarks; int get remainingSeconds; bool get timerIsRunning; String get note; List<TimelineEvent> get timeline; double get momentum;
/// Create a copy of MatchProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchProjectionCopyWith<MatchProjection> get copyWith => _$MatchProjectionCopyWithImpl<MatchProjection>(this as MatchProjection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchProjection&&(identical(other.id, id) || other.id == id)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.matchOrder, matchOrder) || other.matchOrder == matchOrder)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.status, status) || other.status == status)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&(identical(other.redName, redName) || other.redName == redName)&&(identical(other.whiteName, whiteName) || other.whiteName == whiteName)&&const DeepCollectionEquality().equals(other.redRemaining, redRemaining)&&const DeepCollectionEquality().equals(other.whiteRemaining, whiteRemaining)&&(identical(other.redScore, redScore) || other.redScore == redScore)&&(identical(other.whiteScore, whiteScore) || other.whiteScore == whiteScore)&&const DeepCollectionEquality().equals(other.redDisplays, redDisplays)&&const DeepCollectionEquality().equals(other.whiteDisplays, whiteDisplays)&&(identical(other.firstPointSide, firstPointSide) || other.firstPointSide == firstPointSide)&&const DeepCollectionEquality().equals(other.redPointMarks, redPointMarks)&&const DeepCollectionEquality().equals(other.whitePointMarks, whitePointMarks)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.timerIsRunning, timerIsRunning) || other.timerIsRunning == timerIsRunning)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.timeline, timeline)&&(identical(other.momentum, momentum) || other.momentum == momentum));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,tournamentId,matchOrder,matchType,status,groupName,isKachinuki,redName,whiteName,const DeepCollectionEquality().hash(redRemaining),const DeepCollectionEquality().hash(whiteRemaining),redScore,whiteScore,const DeepCollectionEquality().hash(redDisplays),const DeepCollectionEquality().hash(whiteDisplays),firstPointSide,const DeepCollectionEquality().hash(redPointMarks),const DeepCollectionEquality().hash(whitePointMarks),remainingSeconds,timerIsRunning,note,const DeepCollectionEquality().hash(timeline),momentum]);

@override
String toString() {
  return 'MatchProjection(id: $id, tournamentId: $tournamentId, matchOrder: $matchOrder, matchType: $matchType, status: $status, groupName: $groupName, isKachinuki: $isKachinuki, redName: $redName, whiteName: $whiteName, redRemaining: $redRemaining, whiteRemaining: $whiteRemaining, redScore: $redScore, whiteScore: $whiteScore, redDisplays: $redDisplays, whiteDisplays: $whiteDisplays, firstPointSide: $firstPointSide, redPointMarks: $redPointMarks, whitePointMarks: $whitePointMarks, remainingSeconds: $remainingSeconds, timerIsRunning: $timerIsRunning, note: $note, timeline: $timeline, momentum: $momentum)';
}


}

/// @nodoc
abstract mixin class $MatchProjectionCopyWith<$Res>  {
  factory $MatchProjectionCopyWith(MatchProjection value, $Res Function(MatchProjection) _then) = _$MatchProjectionCopyWithImpl;
@useResult
$Res call({
 String id, String tournamentId, int matchOrder, String matchType, String status, String groupName, bool isKachinuki, String redName, String whiteName, List<String> redRemaining, List<String> whiteRemaining, int redScore, int whiteScore, List<PointDisplay> redDisplays, List<PointDisplay> whiteDisplays, String firstPointSide, List<String> redPointMarks, List<String> whitePointMarks, int remainingSeconds, bool timerIsRunning, String note, List<TimelineEvent> timeline, double momentum
});




}
/// @nodoc
class _$MatchProjectionCopyWithImpl<$Res>
    implements $MatchProjectionCopyWith<$Res> {
  _$MatchProjectionCopyWithImpl(this._self, this._then);

  final MatchProjection _self;
  final $Res Function(MatchProjection) _then;

/// Create a copy of MatchProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tournamentId = null,Object? matchOrder = null,Object? matchType = null,Object? status = null,Object? groupName = null,Object? isKachinuki = null,Object? redName = null,Object? whiteName = null,Object? redRemaining = null,Object? whiteRemaining = null,Object? redScore = null,Object? whiteScore = null,Object? redDisplays = null,Object? whiteDisplays = null,Object? firstPointSide = null,Object? redPointMarks = null,Object? whitePointMarks = null,Object? remainingSeconds = null,Object? timerIsRunning = null,Object? note = null,Object? timeline = null,Object? momentum = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tournamentId: null == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String,matchOrder: null == matchOrder ? _self.matchOrder : matchOrder // ignore: cast_nullable_to_non_nullable
as int,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,isKachinuki: null == isKachinuki ? _self.isKachinuki : isKachinuki // ignore: cast_nullable_to_non_nullable
as bool,redName: null == redName ? _self.redName : redName // ignore: cast_nullable_to_non_nullable
as String,whiteName: null == whiteName ? _self.whiteName : whiteName // ignore: cast_nullable_to_non_nullable
as String,redRemaining: null == redRemaining ? _self.redRemaining : redRemaining // ignore: cast_nullable_to_non_nullable
as List<String>,whiteRemaining: null == whiteRemaining ? _self.whiteRemaining : whiteRemaining // ignore: cast_nullable_to_non_nullable
as List<String>,redScore: null == redScore ? _self.redScore : redScore // ignore: cast_nullable_to_non_nullable
as int,whiteScore: null == whiteScore ? _self.whiteScore : whiteScore // ignore: cast_nullable_to_non_nullable
as int,redDisplays: null == redDisplays ? _self.redDisplays : redDisplays // ignore: cast_nullable_to_non_nullable
as List<PointDisplay>,whiteDisplays: null == whiteDisplays ? _self.whiteDisplays : whiteDisplays // ignore: cast_nullable_to_non_nullable
as List<PointDisplay>,firstPointSide: null == firstPointSide ? _self.firstPointSide : firstPointSide // ignore: cast_nullable_to_non_nullable
as String,redPointMarks: null == redPointMarks ? _self.redPointMarks : redPointMarks // ignore: cast_nullable_to_non_nullable
as List<String>,whitePointMarks: null == whitePointMarks ? _self.whitePointMarks : whitePointMarks // ignore: cast_nullable_to_non_nullable
as List<String>,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,timerIsRunning: null == timerIsRunning ? _self.timerIsRunning : timerIsRunning // ignore: cast_nullable_to_non_nullable
as bool,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,timeline: null == timeline ? _self.timeline : timeline // ignore: cast_nullable_to_non_nullable
as List<TimelineEvent>,momentum: null == momentum ? _self.momentum : momentum // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchProjection].
extension MatchProjectionPatterns on MatchProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchProjection value)  $default,){
final _that = this;
switch (_that) {
case _MatchProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchProjection value)?  $default,){
final _that = this;
switch (_that) {
case _MatchProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tournamentId,  int matchOrder,  String matchType,  String status,  String groupName,  bool isKachinuki,  String redName,  String whiteName,  List<String> redRemaining,  List<String> whiteRemaining,  int redScore,  int whiteScore,  List<PointDisplay> redDisplays,  List<PointDisplay> whiteDisplays,  String firstPointSide,  List<String> redPointMarks,  List<String> whitePointMarks,  int remainingSeconds,  bool timerIsRunning,  String note,  List<TimelineEvent> timeline,  double momentum)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchProjection() when $default != null:
return $default(_that.id,_that.tournamentId,_that.matchOrder,_that.matchType,_that.status,_that.groupName,_that.isKachinuki,_that.redName,_that.whiteName,_that.redRemaining,_that.whiteRemaining,_that.redScore,_that.whiteScore,_that.redDisplays,_that.whiteDisplays,_that.firstPointSide,_that.redPointMarks,_that.whitePointMarks,_that.remainingSeconds,_that.timerIsRunning,_that.note,_that.timeline,_that.momentum);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tournamentId,  int matchOrder,  String matchType,  String status,  String groupName,  bool isKachinuki,  String redName,  String whiteName,  List<String> redRemaining,  List<String> whiteRemaining,  int redScore,  int whiteScore,  List<PointDisplay> redDisplays,  List<PointDisplay> whiteDisplays,  String firstPointSide,  List<String> redPointMarks,  List<String> whitePointMarks,  int remainingSeconds,  bool timerIsRunning,  String note,  List<TimelineEvent> timeline,  double momentum)  $default,) {final _that = this;
switch (_that) {
case _MatchProjection():
return $default(_that.id,_that.tournamentId,_that.matchOrder,_that.matchType,_that.status,_that.groupName,_that.isKachinuki,_that.redName,_that.whiteName,_that.redRemaining,_that.whiteRemaining,_that.redScore,_that.whiteScore,_that.redDisplays,_that.whiteDisplays,_that.firstPointSide,_that.redPointMarks,_that.whitePointMarks,_that.remainingSeconds,_that.timerIsRunning,_that.note,_that.timeline,_that.momentum);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tournamentId,  int matchOrder,  String matchType,  String status,  String groupName,  bool isKachinuki,  String redName,  String whiteName,  List<String> redRemaining,  List<String> whiteRemaining,  int redScore,  int whiteScore,  List<PointDisplay> redDisplays,  List<PointDisplay> whiteDisplays,  String firstPointSide,  List<String> redPointMarks,  List<String> whitePointMarks,  int remainingSeconds,  bool timerIsRunning,  String note,  List<TimelineEvent> timeline,  double momentum)?  $default,) {final _that = this;
switch (_that) {
case _MatchProjection() when $default != null:
return $default(_that.id,_that.tournamentId,_that.matchOrder,_that.matchType,_that.status,_that.groupName,_that.isKachinuki,_that.redName,_that.whiteName,_that.redRemaining,_that.whiteRemaining,_that.redScore,_that.whiteScore,_that.redDisplays,_that.whiteDisplays,_that.firstPointSide,_that.redPointMarks,_that.whitePointMarks,_that.remainingSeconds,_that.timerIsRunning,_that.note,_that.timeline,_that.momentum);case _:
  return null;

}
}

}

/// @nodoc


class _MatchProjection implements MatchProjection {
  const _MatchProjection({required this.id, required this.tournamentId, required this.matchOrder, required this.matchType, required this.status, required this.groupName, required this.isKachinuki, required this.redName, required this.whiteName, final  List<String> redRemaining = const [], final  List<String> whiteRemaining = const [], required this.redScore, required this.whiteScore, final  List<PointDisplay> redDisplays = const [], final  List<PointDisplay> whiteDisplays = const [], this.firstPointSide = '', final  List<String> redPointMarks = const [], final  List<String> whitePointMarks = const [], required this.remainingSeconds, required this.timerIsRunning, required this.note, final  List<TimelineEvent> timeline = const [], this.momentum = 0.0}): _redRemaining = redRemaining,_whiteRemaining = whiteRemaining,_redDisplays = redDisplays,_whiteDisplays = whiteDisplays,_redPointMarks = redPointMarks,_whitePointMarks = whitePointMarks,_timeline = timeline;
  

@override final  String id;
@override final  String tournamentId;
@override final  int matchOrder;
@override final  String matchType;
@override final  String status;
@override final  String groupName;
@override final  bool isKachinuki;
@override final  String redName;
@override final  String whiteName;
 final  List<String> _redRemaining;
@override@JsonKey() List<String> get redRemaining {
  if (_redRemaining is EqualUnmodifiableListView) return _redRemaining;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_redRemaining);
}

 final  List<String> _whiteRemaining;
@override@JsonKey() List<String> get whiteRemaining {
  if (_whiteRemaining is EqualUnmodifiableListView) return _whiteRemaining;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_whiteRemaining);
}

@override final  int redScore;
@override final  int whiteScore;
 final  List<PointDisplay> _redDisplays;
@override@JsonKey() List<PointDisplay> get redDisplays {
  if (_redDisplays is EqualUnmodifiableListView) return _redDisplays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_redDisplays);
}

 final  List<PointDisplay> _whiteDisplays;
@override@JsonKey() List<PointDisplay> get whiteDisplays {
  if (_whiteDisplays is EqualUnmodifiableListView) return _whiteDisplays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_whiteDisplays);
}

// ★ 復元: 公式記録画面やスコアボードで必須の表示用フィールド
@override@JsonKey() final  String firstPointSide;
 final  List<String> _redPointMarks;
@override@JsonKey() List<String> get redPointMarks {
  if (_redPointMarks is EqualUnmodifiableListView) return _redPointMarks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_redPointMarks);
}

 final  List<String> _whitePointMarks;
@override@JsonKey() List<String> get whitePointMarks {
  if (_whitePointMarks is EqualUnmodifiableListView) return _whitePointMarks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_whitePointMarks);
}

@override final  int remainingSeconds;
@override final  bool timerIsRunning;
@override final  String note;
 final  List<TimelineEvent> _timeline;
@override@JsonKey() List<TimelineEvent> get timeline {
  if (_timeline is EqualUnmodifiableListView) return _timeline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_timeline);
}

@override@JsonKey() final  double momentum;

/// Create a copy of MatchProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchProjectionCopyWith<_MatchProjection> get copyWith => __$MatchProjectionCopyWithImpl<_MatchProjection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchProjection&&(identical(other.id, id) || other.id == id)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.matchOrder, matchOrder) || other.matchOrder == matchOrder)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.status, status) || other.status == status)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&(identical(other.redName, redName) || other.redName == redName)&&(identical(other.whiteName, whiteName) || other.whiteName == whiteName)&&const DeepCollectionEquality().equals(other._redRemaining, _redRemaining)&&const DeepCollectionEquality().equals(other._whiteRemaining, _whiteRemaining)&&(identical(other.redScore, redScore) || other.redScore == redScore)&&(identical(other.whiteScore, whiteScore) || other.whiteScore == whiteScore)&&const DeepCollectionEquality().equals(other._redDisplays, _redDisplays)&&const DeepCollectionEquality().equals(other._whiteDisplays, _whiteDisplays)&&(identical(other.firstPointSide, firstPointSide) || other.firstPointSide == firstPointSide)&&const DeepCollectionEquality().equals(other._redPointMarks, _redPointMarks)&&const DeepCollectionEquality().equals(other._whitePointMarks, _whitePointMarks)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.timerIsRunning, timerIsRunning) || other.timerIsRunning == timerIsRunning)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other._timeline, _timeline)&&(identical(other.momentum, momentum) || other.momentum == momentum));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,tournamentId,matchOrder,matchType,status,groupName,isKachinuki,redName,whiteName,const DeepCollectionEquality().hash(_redRemaining),const DeepCollectionEquality().hash(_whiteRemaining),redScore,whiteScore,const DeepCollectionEquality().hash(_redDisplays),const DeepCollectionEquality().hash(_whiteDisplays),firstPointSide,const DeepCollectionEquality().hash(_redPointMarks),const DeepCollectionEquality().hash(_whitePointMarks),remainingSeconds,timerIsRunning,note,const DeepCollectionEquality().hash(_timeline),momentum]);

@override
String toString() {
  return 'MatchProjection(id: $id, tournamentId: $tournamentId, matchOrder: $matchOrder, matchType: $matchType, status: $status, groupName: $groupName, isKachinuki: $isKachinuki, redName: $redName, whiteName: $whiteName, redRemaining: $redRemaining, whiteRemaining: $whiteRemaining, redScore: $redScore, whiteScore: $whiteScore, redDisplays: $redDisplays, whiteDisplays: $whiteDisplays, firstPointSide: $firstPointSide, redPointMarks: $redPointMarks, whitePointMarks: $whitePointMarks, remainingSeconds: $remainingSeconds, timerIsRunning: $timerIsRunning, note: $note, timeline: $timeline, momentum: $momentum)';
}


}

/// @nodoc
abstract mixin class _$MatchProjectionCopyWith<$Res> implements $MatchProjectionCopyWith<$Res> {
  factory _$MatchProjectionCopyWith(_MatchProjection value, $Res Function(_MatchProjection) _then) = __$MatchProjectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String tournamentId, int matchOrder, String matchType, String status, String groupName, bool isKachinuki, String redName, String whiteName, List<String> redRemaining, List<String> whiteRemaining, int redScore, int whiteScore, List<PointDisplay> redDisplays, List<PointDisplay> whiteDisplays, String firstPointSide, List<String> redPointMarks, List<String> whitePointMarks, int remainingSeconds, bool timerIsRunning, String note, List<TimelineEvent> timeline, double momentum
});




}
/// @nodoc
class __$MatchProjectionCopyWithImpl<$Res>
    implements _$MatchProjectionCopyWith<$Res> {
  __$MatchProjectionCopyWithImpl(this._self, this._then);

  final _MatchProjection _self;
  final $Res Function(_MatchProjection) _then;

/// Create a copy of MatchProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tournamentId = null,Object? matchOrder = null,Object? matchType = null,Object? status = null,Object? groupName = null,Object? isKachinuki = null,Object? redName = null,Object? whiteName = null,Object? redRemaining = null,Object? whiteRemaining = null,Object? redScore = null,Object? whiteScore = null,Object? redDisplays = null,Object? whiteDisplays = null,Object? firstPointSide = null,Object? redPointMarks = null,Object? whitePointMarks = null,Object? remainingSeconds = null,Object? timerIsRunning = null,Object? note = null,Object? timeline = null,Object? momentum = null,}) {
  return _then(_MatchProjection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tournamentId: null == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String,matchOrder: null == matchOrder ? _self.matchOrder : matchOrder // ignore: cast_nullable_to_non_nullable
as int,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,isKachinuki: null == isKachinuki ? _self.isKachinuki : isKachinuki // ignore: cast_nullable_to_non_nullable
as bool,redName: null == redName ? _self.redName : redName // ignore: cast_nullable_to_non_nullable
as String,whiteName: null == whiteName ? _self.whiteName : whiteName // ignore: cast_nullable_to_non_nullable
as String,redRemaining: null == redRemaining ? _self._redRemaining : redRemaining // ignore: cast_nullable_to_non_nullable
as List<String>,whiteRemaining: null == whiteRemaining ? _self._whiteRemaining : whiteRemaining // ignore: cast_nullable_to_non_nullable
as List<String>,redScore: null == redScore ? _self.redScore : redScore // ignore: cast_nullable_to_non_nullable
as int,whiteScore: null == whiteScore ? _self.whiteScore : whiteScore // ignore: cast_nullable_to_non_nullable
as int,redDisplays: null == redDisplays ? _self._redDisplays : redDisplays // ignore: cast_nullable_to_non_nullable
as List<PointDisplay>,whiteDisplays: null == whiteDisplays ? _self._whiteDisplays : whiteDisplays // ignore: cast_nullable_to_non_nullable
as List<PointDisplay>,firstPointSide: null == firstPointSide ? _self.firstPointSide : firstPointSide // ignore: cast_nullable_to_non_nullable
as String,redPointMarks: null == redPointMarks ? _self._redPointMarks : redPointMarks // ignore: cast_nullable_to_non_nullable
as List<String>,whitePointMarks: null == whitePointMarks ? _self._whitePointMarks : whitePointMarks // ignore: cast_nullable_to_non_nullable
as List<String>,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,timerIsRunning: null == timerIsRunning ? _self.timerIsRunning : timerIsRunning // ignore: cast_nullable_to_non_nullable
as bool,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,timeline: null == timeline ? _self._timeline : timeline // ignore: cast_nullable_to_non_nullable
as List<TimelineEvent>,momentum: null == momentum ? _self.momentum : momentum // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$MatchAuditProjection {

 String get id; String get status; List<TimelineEvent> get fullHistory; String? get scorerId; int get eventCount; SyncStatus get syncStatus;
/// Create a copy of MatchAuditProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchAuditProjectionCopyWith<MatchAuditProjection> get copyWith => _$MatchAuditProjectionCopyWithImpl<MatchAuditProjection>(this as MatchAuditProjection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchAuditProjection&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.fullHistory, fullHistory)&&(identical(other.scorerId, scorerId) || other.scorerId == scorerId)&&(identical(other.eventCount, eventCount) || other.eventCount == eventCount)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hash(runtimeType,id,status,const DeepCollectionEquality().hash(fullHistory),scorerId,eventCount,syncStatus);

@override
String toString() {
  return 'MatchAuditProjection(id: $id, status: $status, fullHistory: $fullHistory, scorerId: $scorerId, eventCount: $eventCount, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $MatchAuditProjectionCopyWith<$Res>  {
  factory $MatchAuditProjectionCopyWith(MatchAuditProjection value, $Res Function(MatchAuditProjection) _then) = _$MatchAuditProjectionCopyWithImpl;
@useResult
$Res call({
 String id, String status, List<TimelineEvent> fullHistory, String? scorerId, int eventCount, SyncStatus syncStatus
});




}
/// @nodoc
class _$MatchAuditProjectionCopyWithImpl<$Res>
    implements $MatchAuditProjectionCopyWith<$Res> {
  _$MatchAuditProjectionCopyWithImpl(this._self, this._then);

  final MatchAuditProjection _self;
  final $Res Function(MatchAuditProjection) _then;

/// Create a copy of MatchAuditProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? fullHistory = null,Object? scorerId = freezed,Object? eventCount = null,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,fullHistory: null == fullHistory ? _self.fullHistory : fullHistory // ignore: cast_nullable_to_non_nullable
as List<TimelineEvent>,scorerId: freezed == scorerId ? _self.scorerId : scorerId // ignore: cast_nullable_to_non_nullable
as String?,eventCount: null == eventCount ? _self.eventCount : eventCount // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchAuditProjection].
extension MatchAuditProjectionPatterns on MatchAuditProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchAuditProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchAuditProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchAuditProjection value)  $default,){
final _that = this;
switch (_that) {
case _MatchAuditProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchAuditProjection value)?  $default,){
final _that = this;
switch (_that) {
case _MatchAuditProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String status,  List<TimelineEvent> fullHistory,  String? scorerId,  int eventCount,  SyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchAuditProjection() when $default != null:
return $default(_that.id,_that.status,_that.fullHistory,_that.scorerId,_that.eventCount,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String status,  List<TimelineEvent> fullHistory,  String? scorerId,  int eventCount,  SyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _MatchAuditProjection():
return $default(_that.id,_that.status,_that.fullHistory,_that.scorerId,_that.eventCount,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String status,  List<TimelineEvent> fullHistory,  String? scorerId,  int eventCount,  SyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _MatchAuditProjection() when $default != null:
return $default(_that.id,_that.status,_that.fullHistory,_that.scorerId,_that.eventCount,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _MatchAuditProjection implements MatchAuditProjection {
  const _MatchAuditProjection({required this.id, required this.status, final  List<TimelineEvent> fullHistory = const [], this.scorerId, this.eventCount = 0, this.syncStatus = SyncStatus.synced}): _fullHistory = fullHistory;
  

@override final  String id;
@override final  String status;
 final  List<TimelineEvent> _fullHistory;
@override@JsonKey() List<TimelineEvent> get fullHistory {
  if (_fullHistory is EqualUnmodifiableListView) return _fullHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fullHistory);
}

@override final  String? scorerId;
@override@JsonKey() final  int eventCount;
@override@JsonKey() final  SyncStatus syncStatus;

/// Create a copy of MatchAuditProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchAuditProjectionCopyWith<_MatchAuditProjection> get copyWith => __$MatchAuditProjectionCopyWithImpl<_MatchAuditProjection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchAuditProjection&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._fullHistory, _fullHistory)&&(identical(other.scorerId, scorerId) || other.scorerId == scorerId)&&(identical(other.eventCount, eventCount) || other.eventCount == eventCount)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hash(runtimeType,id,status,const DeepCollectionEquality().hash(_fullHistory),scorerId,eventCount,syncStatus);

@override
String toString() {
  return 'MatchAuditProjection(id: $id, status: $status, fullHistory: $fullHistory, scorerId: $scorerId, eventCount: $eventCount, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$MatchAuditProjectionCopyWith<$Res> implements $MatchAuditProjectionCopyWith<$Res> {
  factory _$MatchAuditProjectionCopyWith(_MatchAuditProjection value, $Res Function(_MatchAuditProjection) _then) = __$MatchAuditProjectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String status, List<TimelineEvent> fullHistory, String? scorerId, int eventCount, SyncStatus syncStatus
});




}
/// @nodoc
class __$MatchAuditProjectionCopyWithImpl<$Res>
    implements _$MatchAuditProjectionCopyWith<$Res> {
  __$MatchAuditProjectionCopyWithImpl(this._self, this._then);

  final _MatchAuditProjection _self;
  final $Res Function(_MatchAuditProjection) _then;

/// Create a copy of MatchAuditProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? fullHistory = null,Object? scorerId = freezed,Object? eventCount = null,Object? syncStatus = null,}) {
  return _then(_MatchAuditProjection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,fullHistory: null == fullHistory ? _self._fullHistory : fullHistory // ignore: cast_nullable_to_non_nullable
as List<TimelineEvent>,scorerId: freezed == scorerId ? _self.scorerId : scorerId // ignore: cast_nullable_to_non_nullable
as String?,eventCount: null == eventCount ? _self.eventCount : eventCount // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}


}

// dart format on
