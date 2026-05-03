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
mixin _$MatchProjection {

 String get id; String get tournamentId; int get matchOrder; String get matchType; String get status;// 'waiting', 'in_progress', 'finished', 'approved' のString
// UI互換用プロパティ
 String get groupName;// ★追加
 bool get isKachinuki;// ★追加
// 選手情報
 String get redName; String get whiteName; List<String> get redRemaining; List<String> get whiteRemaining;// スコアと表示データ
 int get redScore; int get whiteScore; List<PointDisplay> get redDisplays; List<PointDisplay> get whiteDisplays;// UI特有の表示マーク（公式記録等用）
 String get firstPointSide; List<String> get redPointMarks; List<String> get whitePointMarks;// タイマー・その他
 int get remainingSeconds; bool get timerIsRunning; String get note;
/// Create a copy of MatchProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchProjectionCopyWith<MatchProjection> get copyWith => _$MatchProjectionCopyWithImpl<MatchProjection>(this as MatchProjection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchProjection&&(identical(other.id, id) || other.id == id)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.matchOrder, matchOrder) || other.matchOrder == matchOrder)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.status, status) || other.status == status)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&(identical(other.redName, redName) || other.redName == redName)&&(identical(other.whiteName, whiteName) || other.whiteName == whiteName)&&const DeepCollectionEquality().equals(other.redRemaining, redRemaining)&&const DeepCollectionEquality().equals(other.whiteRemaining, whiteRemaining)&&(identical(other.redScore, redScore) || other.redScore == redScore)&&(identical(other.whiteScore, whiteScore) || other.whiteScore == whiteScore)&&const DeepCollectionEquality().equals(other.redDisplays, redDisplays)&&const DeepCollectionEquality().equals(other.whiteDisplays, whiteDisplays)&&(identical(other.firstPointSide, firstPointSide) || other.firstPointSide == firstPointSide)&&const DeepCollectionEquality().equals(other.redPointMarks, redPointMarks)&&const DeepCollectionEquality().equals(other.whitePointMarks, whitePointMarks)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.timerIsRunning, timerIsRunning) || other.timerIsRunning == timerIsRunning)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,tournamentId,matchOrder,matchType,status,groupName,isKachinuki,redName,whiteName,const DeepCollectionEquality().hash(redRemaining),const DeepCollectionEquality().hash(whiteRemaining),redScore,whiteScore,const DeepCollectionEquality().hash(redDisplays),const DeepCollectionEquality().hash(whiteDisplays),firstPointSide,const DeepCollectionEquality().hash(redPointMarks),const DeepCollectionEquality().hash(whitePointMarks),remainingSeconds,timerIsRunning,note]);

@override
String toString() {
  return 'MatchProjection(id: $id, tournamentId: $tournamentId, matchOrder: $matchOrder, matchType: $matchType, status: $status, groupName: $groupName, isKachinuki: $isKachinuki, redName: $redName, whiteName: $whiteName, redRemaining: $redRemaining, whiteRemaining: $whiteRemaining, redScore: $redScore, whiteScore: $whiteScore, redDisplays: $redDisplays, whiteDisplays: $whiteDisplays, firstPointSide: $firstPointSide, redPointMarks: $redPointMarks, whitePointMarks: $whitePointMarks, remainingSeconds: $remainingSeconds, timerIsRunning: $timerIsRunning, note: $note)';
}


}

/// @nodoc
abstract mixin class $MatchProjectionCopyWith<$Res>  {
  factory $MatchProjectionCopyWith(MatchProjection value, $Res Function(MatchProjection) _then) = _$MatchProjectionCopyWithImpl;
@useResult
$Res call({
 String id, String tournamentId, int matchOrder, String matchType, String status, String groupName, bool isKachinuki, String redName, String whiteName, List<String> redRemaining, List<String> whiteRemaining, int redScore, int whiteScore, List<PointDisplay> redDisplays, List<PointDisplay> whiteDisplays, String firstPointSide, List<String> redPointMarks, List<String> whitePointMarks, int remainingSeconds, bool timerIsRunning, String note
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tournamentId = null,Object? matchOrder = null,Object? matchType = null,Object? status = null,Object? groupName = null,Object? isKachinuki = null,Object? redName = null,Object? whiteName = null,Object? redRemaining = null,Object? whiteRemaining = null,Object? redScore = null,Object? whiteScore = null,Object? redDisplays = null,Object? whiteDisplays = null,Object? firstPointSide = null,Object? redPointMarks = null,Object? whitePointMarks = null,Object? remainingSeconds = null,Object? timerIsRunning = null,Object? note = null,}) {
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
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tournamentId,  int matchOrder,  String matchType,  String status,  String groupName,  bool isKachinuki,  String redName,  String whiteName,  List<String> redRemaining,  List<String> whiteRemaining,  int redScore,  int whiteScore,  List<PointDisplay> redDisplays,  List<PointDisplay> whiteDisplays,  String firstPointSide,  List<String> redPointMarks,  List<String> whitePointMarks,  int remainingSeconds,  bool timerIsRunning,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchProjection() when $default != null:
return $default(_that.id,_that.tournamentId,_that.matchOrder,_that.matchType,_that.status,_that.groupName,_that.isKachinuki,_that.redName,_that.whiteName,_that.redRemaining,_that.whiteRemaining,_that.redScore,_that.whiteScore,_that.redDisplays,_that.whiteDisplays,_that.firstPointSide,_that.redPointMarks,_that.whitePointMarks,_that.remainingSeconds,_that.timerIsRunning,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tournamentId,  int matchOrder,  String matchType,  String status,  String groupName,  bool isKachinuki,  String redName,  String whiteName,  List<String> redRemaining,  List<String> whiteRemaining,  int redScore,  int whiteScore,  List<PointDisplay> redDisplays,  List<PointDisplay> whiteDisplays,  String firstPointSide,  List<String> redPointMarks,  List<String> whitePointMarks,  int remainingSeconds,  bool timerIsRunning,  String note)  $default,) {final _that = this;
switch (_that) {
case _MatchProjection():
return $default(_that.id,_that.tournamentId,_that.matchOrder,_that.matchType,_that.status,_that.groupName,_that.isKachinuki,_that.redName,_that.whiteName,_that.redRemaining,_that.whiteRemaining,_that.redScore,_that.whiteScore,_that.redDisplays,_that.whiteDisplays,_that.firstPointSide,_that.redPointMarks,_that.whitePointMarks,_that.remainingSeconds,_that.timerIsRunning,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tournamentId,  int matchOrder,  String matchType,  String status,  String groupName,  bool isKachinuki,  String redName,  String whiteName,  List<String> redRemaining,  List<String> whiteRemaining,  int redScore,  int whiteScore,  List<PointDisplay> redDisplays,  List<PointDisplay> whiteDisplays,  String firstPointSide,  List<String> redPointMarks,  List<String> whitePointMarks,  int remainingSeconds,  bool timerIsRunning,  String note)?  $default,) {final _that = this;
switch (_that) {
case _MatchProjection() when $default != null:
return $default(_that.id,_that.tournamentId,_that.matchOrder,_that.matchType,_that.status,_that.groupName,_that.isKachinuki,_that.redName,_that.whiteName,_that.redRemaining,_that.whiteRemaining,_that.redScore,_that.whiteScore,_that.redDisplays,_that.whiteDisplays,_that.firstPointSide,_that.redPointMarks,_that.whitePointMarks,_that.remainingSeconds,_that.timerIsRunning,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _MatchProjection implements MatchProjection {
  const _MatchProjection({required this.id, required this.tournamentId, required this.matchOrder, required this.matchType, required this.status, required this.groupName, required this.isKachinuki, required this.redName, required this.whiteName, final  List<String> redRemaining = const [], final  List<String> whiteRemaining = const [], required this.redScore, required this.whiteScore, final  List<PointDisplay> redDisplays = const [], final  List<PointDisplay> whiteDisplays = const [], this.firstPointSide = '', final  List<String> redPointMarks = const [], final  List<String> whitePointMarks = const [], required this.remainingSeconds, required this.timerIsRunning, required this.note}): _redRemaining = redRemaining,_whiteRemaining = whiteRemaining,_redDisplays = redDisplays,_whiteDisplays = whiteDisplays,_redPointMarks = redPointMarks,_whitePointMarks = whitePointMarks;
  

@override final  String id;
@override final  String tournamentId;
@override final  int matchOrder;
@override final  String matchType;
@override final  String status;
// 'waiting', 'in_progress', 'finished', 'approved' のString
// UI互換用プロパティ
@override final  String groupName;
// ★追加
@override final  bool isKachinuki;
// ★追加
// 選手情報
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

// スコアと表示データ
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

// UI特有の表示マーク（公式記録等用）
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

// タイマー・その他
@override final  int remainingSeconds;
@override final  bool timerIsRunning;
@override final  String note;

/// Create a copy of MatchProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchProjectionCopyWith<_MatchProjection> get copyWith => __$MatchProjectionCopyWithImpl<_MatchProjection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchProjection&&(identical(other.id, id) || other.id == id)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.matchOrder, matchOrder) || other.matchOrder == matchOrder)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.status, status) || other.status == status)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&(identical(other.redName, redName) || other.redName == redName)&&(identical(other.whiteName, whiteName) || other.whiteName == whiteName)&&const DeepCollectionEquality().equals(other._redRemaining, _redRemaining)&&const DeepCollectionEquality().equals(other._whiteRemaining, _whiteRemaining)&&(identical(other.redScore, redScore) || other.redScore == redScore)&&(identical(other.whiteScore, whiteScore) || other.whiteScore == whiteScore)&&const DeepCollectionEquality().equals(other._redDisplays, _redDisplays)&&const DeepCollectionEquality().equals(other._whiteDisplays, _whiteDisplays)&&(identical(other.firstPointSide, firstPointSide) || other.firstPointSide == firstPointSide)&&const DeepCollectionEquality().equals(other._redPointMarks, _redPointMarks)&&const DeepCollectionEquality().equals(other._whitePointMarks, _whitePointMarks)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.timerIsRunning, timerIsRunning) || other.timerIsRunning == timerIsRunning)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,tournamentId,matchOrder,matchType,status,groupName,isKachinuki,redName,whiteName,const DeepCollectionEquality().hash(_redRemaining),const DeepCollectionEquality().hash(_whiteRemaining),redScore,whiteScore,const DeepCollectionEquality().hash(_redDisplays),const DeepCollectionEquality().hash(_whiteDisplays),firstPointSide,const DeepCollectionEquality().hash(_redPointMarks),const DeepCollectionEquality().hash(_whitePointMarks),remainingSeconds,timerIsRunning,note]);

@override
String toString() {
  return 'MatchProjection(id: $id, tournamentId: $tournamentId, matchOrder: $matchOrder, matchType: $matchType, status: $status, groupName: $groupName, isKachinuki: $isKachinuki, redName: $redName, whiteName: $whiteName, redRemaining: $redRemaining, whiteRemaining: $whiteRemaining, redScore: $redScore, whiteScore: $whiteScore, redDisplays: $redDisplays, whiteDisplays: $whiteDisplays, firstPointSide: $firstPointSide, redPointMarks: $redPointMarks, whitePointMarks: $whitePointMarks, remainingSeconds: $remainingSeconds, timerIsRunning: $timerIsRunning, note: $note)';
}


}

/// @nodoc
abstract mixin class _$MatchProjectionCopyWith<$Res> implements $MatchProjectionCopyWith<$Res> {
  factory _$MatchProjectionCopyWith(_MatchProjection value, $Res Function(_MatchProjection) _then) = __$MatchProjectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String tournamentId, int matchOrder, String matchType, String status, String groupName, bool isKachinuki, String redName, String whiteName, List<String> redRemaining, List<String> whiteRemaining, int redScore, int whiteScore, List<PointDisplay> redDisplays, List<PointDisplay> whiteDisplays, String firstPointSide, List<String> redPointMarks, List<String> whitePointMarks, int remainingSeconds, bool timerIsRunning, String note
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tournamentId = null,Object? matchOrder = null,Object? matchType = null,Object? status = null,Object? groupName = null,Object? isKachinuki = null,Object? redName = null,Object? whiteName = null,Object? redRemaining = null,Object? whiteRemaining = null,Object? redScore = null,Object? whiteScore = null,Object? redDisplays = null,Object? whiteDisplays = null,Object? firstPointSide = null,Object? redPointMarks = null,Object? whitePointMarks = null,Object? remainingSeconds = null,Object? timerIsRunning = null,Object? note = null,}) {
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
as String,
  ));
}


}

// dart format on
