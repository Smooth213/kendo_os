// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchModel {

 String get id; String get matchType; String get redName; String get whiteName; int get redScore; int get whiteScore; String get status; List<ScoreEvent> get events;// ★ これが「真実のデータ（Single Source of Truth）」となる
 List<String> get refereeNames; bool get countForStandings; String? get scorerId; int get version; bool get isAutoAssigned;@DoubleConverter() double get order; String get source; String? get tournamentId; String? get category; String? get groupName; int? get matchOrder;// ★ intに戻します
 int get matchTimeMinutes; bool get isRunningTime; bool get hasExtension; int? get extensionTimeMinutes; int? get extensionCount; bool get hasHantei; int get remainingSeconds; bool get timerIsRunning; String get note; bool get isKachinuki; List<String> get redRemaining; List<String> get whiteRemaining;
/// Create a copy of MatchModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchModelCopyWith<MatchModel> get copyWith => _$MatchModelCopyWithImpl<MatchModel>(this as MatchModel, _$identity);

  /// Serializes this MatchModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchModel&&(identical(other.id, id) || other.id == id)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.redName, redName) || other.redName == redName)&&(identical(other.whiteName, whiteName) || other.whiteName == whiteName)&&(identical(other.redScore, redScore) || other.redScore == redScore)&&(identical(other.whiteScore, whiteScore) || other.whiteScore == whiteScore)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.events, events)&&const DeepCollectionEquality().equals(other.refereeNames, refereeNames)&&(identical(other.countForStandings, countForStandings) || other.countForStandings == countForStandings)&&(identical(other.scorerId, scorerId) || other.scorerId == scorerId)&&(identical(other.version, version) || other.version == version)&&(identical(other.isAutoAssigned, isAutoAssigned) || other.isAutoAssigned == isAutoAssigned)&&(identical(other.order, order) || other.order == order)&&(identical(other.source, source) || other.source == source)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.category, category) || other.category == category)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.matchOrder, matchOrder) || other.matchOrder == matchOrder)&&(identical(other.matchTimeMinutes, matchTimeMinutes) || other.matchTimeMinutes == matchTimeMinutes)&&(identical(other.isRunningTime, isRunningTime) || other.isRunningTime == isRunningTime)&&(identical(other.hasExtension, hasExtension) || other.hasExtension == hasExtension)&&(identical(other.extensionTimeMinutes, extensionTimeMinutes) || other.extensionTimeMinutes == extensionTimeMinutes)&&(identical(other.extensionCount, extensionCount) || other.extensionCount == extensionCount)&&(identical(other.hasHantei, hasHantei) || other.hasHantei == hasHantei)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.timerIsRunning, timerIsRunning) || other.timerIsRunning == timerIsRunning)&&(identical(other.note, note) || other.note == note)&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&const DeepCollectionEquality().equals(other.redRemaining, redRemaining)&&const DeepCollectionEquality().equals(other.whiteRemaining, whiteRemaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,matchType,redName,whiteName,redScore,whiteScore,status,const DeepCollectionEquality().hash(events),const DeepCollectionEquality().hash(refereeNames),countForStandings,scorerId,version,isAutoAssigned,order,source,tournamentId,category,groupName,matchOrder,matchTimeMinutes,isRunningTime,hasExtension,extensionTimeMinutes,extensionCount,hasHantei,remainingSeconds,timerIsRunning,note,isKachinuki,const DeepCollectionEquality().hash(redRemaining),const DeepCollectionEquality().hash(whiteRemaining)]);

@override
String toString() {
  return 'MatchModel(id: $id, matchType: $matchType, redName: $redName, whiteName: $whiteName, redScore: $redScore, whiteScore: $whiteScore, status: $status, events: $events, refereeNames: $refereeNames, countForStandings: $countForStandings, scorerId: $scorerId, version: $version, isAutoAssigned: $isAutoAssigned, order: $order, source: $source, tournamentId: $tournamentId, category: $category, groupName: $groupName, matchOrder: $matchOrder, matchTimeMinutes: $matchTimeMinutes, isRunningTime: $isRunningTime, hasExtension: $hasExtension, extensionTimeMinutes: $extensionTimeMinutes, extensionCount: $extensionCount, hasHantei: $hasHantei, remainingSeconds: $remainingSeconds, timerIsRunning: $timerIsRunning, note: $note, isKachinuki: $isKachinuki, redRemaining: $redRemaining, whiteRemaining: $whiteRemaining)';
}


}

/// @nodoc
abstract mixin class $MatchModelCopyWith<$Res>  {
  factory $MatchModelCopyWith(MatchModel value, $Res Function(MatchModel) _then) = _$MatchModelCopyWithImpl;
@useResult
$Res call({
 String id, String matchType, String redName, String whiteName, int redScore, int whiteScore, String status, List<ScoreEvent> events, List<String> refereeNames, bool countForStandings, String? scorerId, int version, bool isAutoAssigned,@DoubleConverter() double order, String source, String? tournamentId, String? category, String? groupName, int? matchOrder, int matchTimeMinutes, bool isRunningTime, bool hasExtension, int? extensionTimeMinutes, int? extensionCount, bool hasHantei, int remainingSeconds, bool timerIsRunning, String note, bool isKachinuki, List<String> redRemaining, List<String> whiteRemaining
});




}
/// @nodoc
class _$MatchModelCopyWithImpl<$Res>
    implements $MatchModelCopyWith<$Res> {
  _$MatchModelCopyWithImpl(this._self, this._then);

  final MatchModel _self;
  final $Res Function(MatchModel) _then;

/// Create a copy of MatchModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? matchType = null,Object? redName = null,Object? whiteName = null,Object? redScore = null,Object? whiteScore = null,Object? status = null,Object? events = null,Object? refereeNames = null,Object? countForStandings = null,Object? scorerId = freezed,Object? version = null,Object? isAutoAssigned = null,Object? order = null,Object? source = null,Object? tournamentId = freezed,Object? category = freezed,Object? groupName = freezed,Object? matchOrder = freezed,Object? matchTimeMinutes = null,Object? isRunningTime = null,Object? hasExtension = null,Object? extensionTimeMinutes = freezed,Object? extensionCount = freezed,Object? hasHantei = null,Object? remainingSeconds = null,Object? timerIsRunning = null,Object? note = null,Object? isKachinuki = null,Object? redRemaining = null,Object? whiteRemaining = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,redName: null == redName ? _self.redName : redName // ignore: cast_nullable_to_non_nullable
as String,whiteName: null == whiteName ? _self.whiteName : whiteName // ignore: cast_nullable_to_non_nullable
as String,redScore: null == redScore ? _self.redScore : redScore // ignore: cast_nullable_to_non_nullable
as int,whiteScore: null == whiteScore ? _self.whiteScore : whiteScore // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<ScoreEvent>,refereeNames: null == refereeNames ? _self.refereeNames : refereeNames // ignore: cast_nullable_to_non_nullable
as List<String>,countForStandings: null == countForStandings ? _self.countForStandings : countForStandings // ignore: cast_nullable_to_non_nullable
as bool,scorerId: freezed == scorerId ? _self.scorerId : scorerId // ignore: cast_nullable_to_non_nullable
as String?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,isAutoAssigned: null == isAutoAssigned ? _self.isAutoAssigned : isAutoAssigned // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,tournamentId: freezed == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,matchOrder: freezed == matchOrder ? _self.matchOrder : matchOrder // ignore: cast_nullable_to_non_nullable
as int?,matchTimeMinutes: null == matchTimeMinutes ? _self.matchTimeMinutes : matchTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isRunningTime: null == isRunningTime ? _self.isRunningTime : isRunningTime // ignore: cast_nullable_to_non_nullable
as bool,hasExtension: null == hasExtension ? _self.hasExtension : hasExtension // ignore: cast_nullable_to_non_nullable
as bool,extensionTimeMinutes: freezed == extensionTimeMinutes ? _self.extensionTimeMinutes : extensionTimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,extensionCount: freezed == extensionCount ? _self.extensionCount : extensionCount // ignore: cast_nullable_to_non_nullable
as int?,hasHantei: null == hasHantei ? _self.hasHantei : hasHantei // ignore: cast_nullable_to_non_nullable
as bool,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,timerIsRunning: null == timerIsRunning ? _self.timerIsRunning : timerIsRunning // ignore: cast_nullable_to_non_nullable
as bool,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,isKachinuki: null == isKachinuki ? _self.isKachinuki : isKachinuki // ignore: cast_nullable_to_non_nullable
as bool,redRemaining: null == redRemaining ? _self.redRemaining : redRemaining // ignore: cast_nullable_to_non_nullable
as List<String>,whiteRemaining: null == whiteRemaining ? _self.whiteRemaining : whiteRemaining // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchModel].
extension MatchModelPatterns on MatchModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchModel value)  $default,){
final _that = this;
switch (_that) {
case _MatchModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchModel value)?  $default,){
final _that = this;
switch (_that) {
case _MatchModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String matchType,  String redName,  String whiteName,  int redScore,  int whiteScore,  String status,  List<ScoreEvent> events,  List<String> refereeNames,  bool countForStandings,  String? scorerId,  int version,  bool isAutoAssigned, @DoubleConverter()  double order,  String source,  String? tournamentId,  String? category,  String? groupName,  int? matchOrder,  int matchTimeMinutes,  bool isRunningTime,  bool hasExtension,  int? extensionTimeMinutes,  int? extensionCount,  bool hasHantei,  int remainingSeconds,  bool timerIsRunning,  String note,  bool isKachinuki,  List<String> redRemaining,  List<String> whiteRemaining)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchModel() when $default != null:
return $default(_that.id,_that.matchType,_that.redName,_that.whiteName,_that.redScore,_that.whiteScore,_that.status,_that.events,_that.refereeNames,_that.countForStandings,_that.scorerId,_that.version,_that.isAutoAssigned,_that.order,_that.source,_that.tournamentId,_that.category,_that.groupName,_that.matchOrder,_that.matchTimeMinutes,_that.isRunningTime,_that.hasExtension,_that.extensionTimeMinutes,_that.extensionCount,_that.hasHantei,_that.remainingSeconds,_that.timerIsRunning,_that.note,_that.isKachinuki,_that.redRemaining,_that.whiteRemaining);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String matchType,  String redName,  String whiteName,  int redScore,  int whiteScore,  String status,  List<ScoreEvent> events,  List<String> refereeNames,  bool countForStandings,  String? scorerId,  int version,  bool isAutoAssigned, @DoubleConverter()  double order,  String source,  String? tournamentId,  String? category,  String? groupName,  int? matchOrder,  int matchTimeMinutes,  bool isRunningTime,  bool hasExtension,  int? extensionTimeMinutes,  int? extensionCount,  bool hasHantei,  int remainingSeconds,  bool timerIsRunning,  String note,  bool isKachinuki,  List<String> redRemaining,  List<String> whiteRemaining)  $default,) {final _that = this;
switch (_that) {
case _MatchModel():
return $default(_that.id,_that.matchType,_that.redName,_that.whiteName,_that.redScore,_that.whiteScore,_that.status,_that.events,_that.refereeNames,_that.countForStandings,_that.scorerId,_that.version,_that.isAutoAssigned,_that.order,_that.source,_that.tournamentId,_that.category,_that.groupName,_that.matchOrder,_that.matchTimeMinutes,_that.isRunningTime,_that.hasExtension,_that.extensionTimeMinutes,_that.extensionCount,_that.hasHantei,_that.remainingSeconds,_that.timerIsRunning,_that.note,_that.isKachinuki,_that.redRemaining,_that.whiteRemaining);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String matchType,  String redName,  String whiteName,  int redScore,  int whiteScore,  String status,  List<ScoreEvent> events,  List<String> refereeNames,  bool countForStandings,  String? scorerId,  int version,  bool isAutoAssigned, @DoubleConverter()  double order,  String source,  String? tournamentId,  String? category,  String? groupName,  int? matchOrder,  int matchTimeMinutes,  bool isRunningTime,  bool hasExtension,  int? extensionTimeMinutes,  int? extensionCount,  bool hasHantei,  int remainingSeconds,  bool timerIsRunning,  String note,  bool isKachinuki,  List<String> redRemaining,  List<String> whiteRemaining)?  $default,) {final _that = this;
switch (_that) {
case _MatchModel() when $default != null:
return $default(_that.id,_that.matchType,_that.redName,_that.whiteName,_that.redScore,_that.whiteScore,_that.status,_that.events,_that.refereeNames,_that.countForStandings,_that.scorerId,_that.version,_that.isAutoAssigned,_that.order,_that.source,_that.tournamentId,_that.category,_that.groupName,_that.matchOrder,_that.matchTimeMinutes,_that.isRunningTime,_that.hasExtension,_that.extensionTimeMinutes,_that.extensionCount,_that.hasHantei,_that.remainingSeconds,_that.timerIsRunning,_that.note,_that.isKachinuki,_that.redRemaining,_that.whiteRemaining);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchModel extends MatchModel {
  const _MatchModel({required this.id, required this.matchType, required this.redName, required this.whiteName, this.redScore = 0, this.whiteScore = 0, this.status = 'waiting', final  List<ScoreEvent> events = const [], final  List<String> refereeNames = const [], this.countForStandings = true, this.scorerId, this.version = 1, this.isAutoAssigned = false, @DoubleConverter() this.order = 0.0, this.source = 'manual', this.tournamentId, this.category, this.groupName, this.matchOrder, this.matchTimeMinutes = 3, this.isRunningTime = false, this.hasExtension = false, this.extensionTimeMinutes, this.extensionCount, this.hasHantei = false, this.remainingSeconds = 180, this.timerIsRunning = false, this.note = '', this.isKachinuki = false, final  List<String> redRemaining = const [], final  List<String> whiteRemaining = const []}): _events = events,_refereeNames = refereeNames,_redRemaining = redRemaining,_whiteRemaining = whiteRemaining,super._();
  factory _MatchModel.fromJson(Map<String, dynamic> json) => _$MatchModelFromJson(json);

@override final  String id;
@override final  String matchType;
@override final  String redName;
@override final  String whiteName;
@override@JsonKey() final  int redScore;
@override@JsonKey() final  int whiteScore;
@override@JsonKey() final  String status;
 final  List<ScoreEvent> _events;
@override@JsonKey() List<ScoreEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

// ★ これが「真実のデータ（Single Source of Truth）」となる
 final  List<String> _refereeNames;
// ★ これが「真実のデータ（Single Source of Truth）」となる
@override@JsonKey() List<String> get refereeNames {
  if (_refereeNames is EqualUnmodifiableListView) return _refereeNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_refereeNames);
}

@override@JsonKey() final  bool countForStandings;
@override final  String? scorerId;
@override@JsonKey() final  int version;
@override@JsonKey() final  bool isAutoAssigned;
@override@JsonKey()@DoubleConverter() final  double order;
@override@JsonKey() final  String source;
@override final  String? tournamentId;
@override final  String? category;
@override final  String? groupName;
@override final  int? matchOrder;
// ★ intに戻します
@override@JsonKey() final  int matchTimeMinutes;
@override@JsonKey() final  bool isRunningTime;
@override@JsonKey() final  bool hasExtension;
@override final  int? extensionTimeMinutes;
@override final  int? extensionCount;
@override@JsonKey() final  bool hasHantei;
@override@JsonKey() final  int remainingSeconds;
@override@JsonKey() final  bool timerIsRunning;
@override@JsonKey() final  String note;
@override@JsonKey() final  bool isKachinuki;
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


/// Create a copy of MatchModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchModelCopyWith<_MatchModel> get copyWith => __$MatchModelCopyWithImpl<_MatchModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchModel&&(identical(other.id, id) || other.id == id)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.redName, redName) || other.redName == redName)&&(identical(other.whiteName, whiteName) || other.whiteName == whiteName)&&(identical(other.redScore, redScore) || other.redScore == redScore)&&(identical(other.whiteScore, whiteScore) || other.whiteScore == whiteScore)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._events, _events)&&const DeepCollectionEquality().equals(other._refereeNames, _refereeNames)&&(identical(other.countForStandings, countForStandings) || other.countForStandings == countForStandings)&&(identical(other.scorerId, scorerId) || other.scorerId == scorerId)&&(identical(other.version, version) || other.version == version)&&(identical(other.isAutoAssigned, isAutoAssigned) || other.isAutoAssigned == isAutoAssigned)&&(identical(other.order, order) || other.order == order)&&(identical(other.source, source) || other.source == source)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.category, category) || other.category == category)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.matchOrder, matchOrder) || other.matchOrder == matchOrder)&&(identical(other.matchTimeMinutes, matchTimeMinutes) || other.matchTimeMinutes == matchTimeMinutes)&&(identical(other.isRunningTime, isRunningTime) || other.isRunningTime == isRunningTime)&&(identical(other.hasExtension, hasExtension) || other.hasExtension == hasExtension)&&(identical(other.extensionTimeMinutes, extensionTimeMinutes) || other.extensionTimeMinutes == extensionTimeMinutes)&&(identical(other.extensionCount, extensionCount) || other.extensionCount == extensionCount)&&(identical(other.hasHantei, hasHantei) || other.hasHantei == hasHantei)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.timerIsRunning, timerIsRunning) || other.timerIsRunning == timerIsRunning)&&(identical(other.note, note) || other.note == note)&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&const DeepCollectionEquality().equals(other._redRemaining, _redRemaining)&&const DeepCollectionEquality().equals(other._whiteRemaining, _whiteRemaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,matchType,redName,whiteName,redScore,whiteScore,status,const DeepCollectionEquality().hash(_events),const DeepCollectionEquality().hash(_refereeNames),countForStandings,scorerId,version,isAutoAssigned,order,source,tournamentId,category,groupName,matchOrder,matchTimeMinutes,isRunningTime,hasExtension,extensionTimeMinutes,extensionCount,hasHantei,remainingSeconds,timerIsRunning,note,isKachinuki,const DeepCollectionEquality().hash(_redRemaining),const DeepCollectionEquality().hash(_whiteRemaining)]);

@override
String toString() {
  return 'MatchModel(id: $id, matchType: $matchType, redName: $redName, whiteName: $whiteName, redScore: $redScore, whiteScore: $whiteScore, status: $status, events: $events, refereeNames: $refereeNames, countForStandings: $countForStandings, scorerId: $scorerId, version: $version, isAutoAssigned: $isAutoAssigned, order: $order, source: $source, tournamentId: $tournamentId, category: $category, groupName: $groupName, matchOrder: $matchOrder, matchTimeMinutes: $matchTimeMinutes, isRunningTime: $isRunningTime, hasExtension: $hasExtension, extensionTimeMinutes: $extensionTimeMinutes, extensionCount: $extensionCount, hasHantei: $hasHantei, remainingSeconds: $remainingSeconds, timerIsRunning: $timerIsRunning, note: $note, isKachinuki: $isKachinuki, redRemaining: $redRemaining, whiteRemaining: $whiteRemaining)';
}


}

/// @nodoc
abstract mixin class _$MatchModelCopyWith<$Res> implements $MatchModelCopyWith<$Res> {
  factory _$MatchModelCopyWith(_MatchModel value, $Res Function(_MatchModel) _then) = __$MatchModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String matchType, String redName, String whiteName, int redScore, int whiteScore, String status, List<ScoreEvent> events, List<String> refereeNames, bool countForStandings, String? scorerId, int version, bool isAutoAssigned,@DoubleConverter() double order, String source, String? tournamentId, String? category, String? groupName, int? matchOrder, int matchTimeMinutes, bool isRunningTime, bool hasExtension, int? extensionTimeMinutes, int? extensionCount, bool hasHantei, int remainingSeconds, bool timerIsRunning, String note, bool isKachinuki, List<String> redRemaining, List<String> whiteRemaining
});




}
/// @nodoc
class __$MatchModelCopyWithImpl<$Res>
    implements _$MatchModelCopyWith<$Res> {
  __$MatchModelCopyWithImpl(this._self, this._then);

  final _MatchModel _self;
  final $Res Function(_MatchModel) _then;

/// Create a copy of MatchModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? matchType = null,Object? redName = null,Object? whiteName = null,Object? redScore = null,Object? whiteScore = null,Object? status = null,Object? events = null,Object? refereeNames = null,Object? countForStandings = null,Object? scorerId = freezed,Object? version = null,Object? isAutoAssigned = null,Object? order = null,Object? source = null,Object? tournamentId = freezed,Object? category = freezed,Object? groupName = freezed,Object? matchOrder = freezed,Object? matchTimeMinutes = null,Object? isRunningTime = null,Object? hasExtension = null,Object? extensionTimeMinutes = freezed,Object? extensionCount = freezed,Object? hasHantei = null,Object? remainingSeconds = null,Object? timerIsRunning = null,Object? note = null,Object? isKachinuki = null,Object? redRemaining = null,Object? whiteRemaining = null,}) {
  return _then(_MatchModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,redName: null == redName ? _self.redName : redName // ignore: cast_nullable_to_non_nullable
as String,whiteName: null == whiteName ? _self.whiteName : whiteName // ignore: cast_nullable_to_non_nullable
as String,redScore: null == redScore ? _self.redScore : redScore // ignore: cast_nullable_to_non_nullable
as int,whiteScore: null == whiteScore ? _self.whiteScore : whiteScore // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<ScoreEvent>,refereeNames: null == refereeNames ? _self._refereeNames : refereeNames // ignore: cast_nullable_to_non_nullable
as List<String>,countForStandings: null == countForStandings ? _self.countForStandings : countForStandings // ignore: cast_nullable_to_non_nullable
as bool,scorerId: freezed == scorerId ? _self.scorerId : scorerId // ignore: cast_nullable_to_non_nullable
as String?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,isAutoAssigned: null == isAutoAssigned ? _self.isAutoAssigned : isAutoAssigned // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,tournamentId: freezed == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,matchOrder: freezed == matchOrder ? _self.matchOrder : matchOrder // ignore: cast_nullable_to_non_nullable
as int?,matchTimeMinutes: null == matchTimeMinutes ? _self.matchTimeMinutes : matchTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isRunningTime: null == isRunningTime ? _self.isRunningTime : isRunningTime // ignore: cast_nullable_to_non_nullable
as bool,hasExtension: null == hasExtension ? _self.hasExtension : hasExtension // ignore: cast_nullable_to_non_nullable
as bool,extensionTimeMinutes: freezed == extensionTimeMinutes ? _self.extensionTimeMinutes : extensionTimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,extensionCount: freezed == extensionCount ? _self.extensionCount : extensionCount // ignore: cast_nullable_to_non_nullable
as int?,hasHantei: null == hasHantei ? _self.hasHantei : hasHantei // ignore: cast_nullable_to_non_nullable
as bool,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,timerIsRunning: null == timerIsRunning ? _self.timerIsRunning : timerIsRunning // ignore: cast_nullable_to_non_nullable
as bool,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,isKachinuki: null == isKachinuki ? _self.isKachinuki : isKachinuki // ignore: cast_nullable_to_non_nullable
as bool,redRemaining: null == redRemaining ? _self._redRemaining : redRemaining // ignore: cast_nullable_to_non_nullable
as List<String>,whiteRemaining: null == whiteRemaining ? _self._whiteRemaining : whiteRemaining // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
