// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kendo_match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TeamInfo {

 String get teamId; String get name; List<String> get memberIds;
/// Create a copy of TeamInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamInfoCopyWith<TeamInfo> get copyWith => _$TeamInfoCopyWithImpl<TeamInfo>(this as TeamInfo, _$identity);

  /// Serializes this TeamInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamInfo&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.memberIds, memberIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamId,name,const DeepCollectionEquality().hash(memberIds));

@override
String toString() {
  return 'TeamInfo(teamId: $teamId, name: $name, memberIds: $memberIds)';
}


}

/// @nodoc
abstract mixin class $TeamInfoCopyWith<$Res>  {
  factory $TeamInfoCopyWith(TeamInfo value, $Res Function(TeamInfo) _then) = _$TeamInfoCopyWithImpl;
@useResult
$Res call({
 String teamId, String name, List<String> memberIds
});




}
/// @nodoc
class _$TeamInfoCopyWithImpl<$Res>
    implements $TeamInfoCopyWith<$Res> {
  _$TeamInfoCopyWithImpl(this._self, this._then);

  final TeamInfo _self;
  final $Res Function(TeamInfo) _then;

/// Create a copy of TeamInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? teamId = null,Object? name = null,Object? memberIds = null,}) {
  return _then(_self.copyWith(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberIds: null == memberIds ? _self.memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamInfo].
extension TeamInfoPatterns on TeamInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamInfo value)  $default,){
final _that = this;
switch (_that) {
case _TeamInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamInfo value)?  $default,){
final _that = this;
switch (_that) {
case _TeamInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String teamId,  String name,  List<String> memberIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamInfo() when $default != null:
return $default(_that.teamId,_that.name,_that.memberIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String teamId,  String name,  List<String> memberIds)  $default,) {final _that = this;
switch (_that) {
case _TeamInfo():
return $default(_that.teamId,_that.name,_that.memberIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String teamId,  String name,  List<String> memberIds)?  $default,) {final _that = this;
switch (_that) {
case _TeamInfo() when $default != null:
return $default(_that.teamId,_that.name,_that.memberIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeamInfo implements TeamInfo {
  const _TeamInfo({required this.teamId, required this.name, final  List<String> memberIds = const []}): _memberIds = memberIds;
  factory _TeamInfo.fromJson(Map<String, dynamic> json) => _$TeamInfoFromJson(json);

@override final  String teamId;
@override final  String name;
 final  List<String> _memberIds;
@override@JsonKey() List<String> get memberIds {
  if (_memberIds is EqualUnmodifiableListView) return _memberIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberIds);
}


/// Create a copy of TeamInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamInfoCopyWith<_TeamInfo> get copyWith => __$TeamInfoCopyWithImpl<_TeamInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamInfo&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._memberIds, _memberIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamId,name,const DeepCollectionEquality().hash(_memberIds));

@override
String toString() {
  return 'TeamInfo(teamId: $teamId, name: $name, memberIds: $memberIds)';
}


}

/// @nodoc
abstract mixin class _$TeamInfoCopyWith<$Res> implements $TeamInfoCopyWith<$Res> {
  factory _$TeamInfoCopyWith(_TeamInfo value, $Res Function(_TeamInfo) _then) = __$TeamInfoCopyWithImpl;
@override @useResult
$Res call({
 String teamId, String name, List<String> memberIds
});




}
/// @nodoc
class __$TeamInfoCopyWithImpl<$Res>
    implements _$TeamInfoCopyWith<$Res> {
  __$TeamInfoCopyWithImpl(this._self, this._then);

  final _TeamInfo _self;
  final $Res Function(_TeamInfo) _then;

/// Create a copy of TeamInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? teamId = null,Object? name = null,Object? memberIds = null,}) {
  return _then(_TeamInfo(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberIds: null == memberIds ? _self._memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$SubMatch {

 String get id; String get positionName; String? get redPlayerId; String? get whitePlayerId; String get redPlayerName; String get whitePlayerName; MatchStatus get status; int get elapsedTime; bool get isTimerRunning; List<ScoreEvent> get events;
/// Create a copy of SubMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubMatchCopyWith<SubMatch> get copyWith => _$SubMatchCopyWithImpl<SubMatch>(this as SubMatch, _$identity);

  /// Serializes this SubMatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubMatch&&(identical(other.id, id) || other.id == id)&&(identical(other.positionName, positionName) || other.positionName == positionName)&&(identical(other.redPlayerId, redPlayerId) || other.redPlayerId == redPlayerId)&&(identical(other.whitePlayerId, whitePlayerId) || other.whitePlayerId == whitePlayerId)&&(identical(other.redPlayerName, redPlayerName) || other.redPlayerName == redPlayerName)&&(identical(other.whitePlayerName, whitePlayerName) || other.whitePlayerName == whitePlayerName)&&(identical(other.status, status) || other.status == status)&&(identical(other.elapsedTime, elapsedTime) || other.elapsedTime == elapsedTime)&&(identical(other.isTimerRunning, isTimerRunning) || other.isTimerRunning == isTimerRunning)&&const DeepCollectionEquality().equals(other.events, events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,positionName,redPlayerId,whitePlayerId,redPlayerName,whitePlayerName,status,elapsedTime,isTimerRunning,const DeepCollectionEquality().hash(events));

@override
String toString() {
  return 'SubMatch(id: $id, positionName: $positionName, redPlayerId: $redPlayerId, whitePlayerId: $whitePlayerId, redPlayerName: $redPlayerName, whitePlayerName: $whitePlayerName, status: $status, elapsedTime: $elapsedTime, isTimerRunning: $isTimerRunning, events: $events)';
}


}

/// @nodoc
abstract mixin class $SubMatchCopyWith<$Res>  {
  factory $SubMatchCopyWith(SubMatch value, $Res Function(SubMatch) _then) = _$SubMatchCopyWithImpl;
@useResult
$Res call({
 String id, String positionName, String? redPlayerId, String? whitePlayerId, String redPlayerName, String whitePlayerName, MatchStatus status, int elapsedTime, bool isTimerRunning, List<ScoreEvent> events
});




}
/// @nodoc
class _$SubMatchCopyWithImpl<$Res>
    implements $SubMatchCopyWith<$Res> {
  _$SubMatchCopyWithImpl(this._self, this._then);

  final SubMatch _self;
  final $Res Function(SubMatch) _then;

/// Create a copy of SubMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? positionName = null,Object? redPlayerId = freezed,Object? whitePlayerId = freezed,Object? redPlayerName = null,Object? whitePlayerName = null,Object? status = null,Object? elapsedTime = null,Object? isTimerRunning = null,Object? events = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,positionName: null == positionName ? _self.positionName : positionName // ignore: cast_nullable_to_non_nullable
as String,redPlayerId: freezed == redPlayerId ? _self.redPlayerId : redPlayerId // ignore: cast_nullable_to_non_nullable
as String?,whitePlayerId: freezed == whitePlayerId ? _self.whitePlayerId : whitePlayerId // ignore: cast_nullable_to_non_nullable
as String?,redPlayerName: null == redPlayerName ? _self.redPlayerName : redPlayerName // ignore: cast_nullable_to_non_nullable
as String,whitePlayerName: null == whitePlayerName ? _self.whitePlayerName : whitePlayerName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MatchStatus,elapsedTime: null == elapsedTime ? _self.elapsedTime : elapsedTime // ignore: cast_nullable_to_non_nullable
as int,isTimerRunning: null == isTimerRunning ? _self.isTimerRunning : isTimerRunning // ignore: cast_nullable_to_non_nullable
as bool,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<ScoreEvent>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubMatch].
extension SubMatchPatterns on SubMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubMatch value)  $default,){
final _that = this;
switch (_that) {
case _SubMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubMatch value)?  $default,){
final _that = this;
switch (_that) {
case _SubMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String positionName,  String? redPlayerId,  String? whitePlayerId,  String redPlayerName,  String whitePlayerName,  MatchStatus status,  int elapsedTime,  bool isTimerRunning,  List<ScoreEvent> events)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubMatch() when $default != null:
return $default(_that.id,_that.positionName,_that.redPlayerId,_that.whitePlayerId,_that.redPlayerName,_that.whitePlayerName,_that.status,_that.elapsedTime,_that.isTimerRunning,_that.events);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String positionName,  String? redPlayerId,  String? whitePlayerId,  String redPlayerName,  String whitePlayerName,  MatchStatus status,  int elapsedTime,  bool isTimerRunning,  List<ScoreEvent> events)  $default,) {final _that = this;
switch (_that) {
case _SubMatch():
return $default(_that.id,_that.positionName,_that.redPlayerId,_that.whitePlayerId,_that.redPlayerName,_that.whitePlayerName,_that.status,_that.elapsedTime,_that.isTimerRunning,_that.events);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String positionName,  String? redPlayerId,  String? whitePlayerId,  String redPlayerName,  String whitePlayerName,  MatchStatus status,  int elapsedTime,  bool isTimerRunning,  List<ScoreEvent> events)?  $default,) {final _that = this;
switch (_that) {
case _SubMatch() when $default != null:
return $default(_that.id,_that.positionName,_that.redPlayerId,_that.whitePlayerId,_that.redPlayerName,_that.whitePlayerName,_that.status,_that.elapsedTime,_that.isTimerRunning,_that.events);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubMatch implements SubMatch {
  const _SubMatch({required this.id, required this.positionName, this.redPlayerId, this.whitePlayerId, this.redPlayerName = '赤', this.whitePlayerName = '白', this.status = MatchStatus.waiting, this.elapsedTime = 0, this.isTimerRunning = false, final  List<ScoreEvent> events = const []}): _events = events;
  factory _SubMatch.fromJson(Map<String, dynamic> json) => _$SubMatchFromJson(json);

@override final  String id;
@override final  String positionName;
@override final  String? redPlayerId;
@override final  String? whitePlayerId;
@override@JsonKey() final  String redPlayerName;
@override@JsonKey() final  String whitePlayerName;
@override@JsonKey() final  MatchStatus status;
@override@JsonKey() final  int elapsedTime;
@override@JsonKey() final  bool isTimerRunning;
 final  List<ScoreEvent> _events;
@override@JsonKey() List<ScoreEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}


/// Create a copy of SubMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubMatchCopyWith<_SubMatch> get copyWith => __$SubMatchCopyWithImpl<_SubMatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubMatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubMatch&&(identical(other.id, id) || other.id == id)&&(identical(other.positionName, positionName) || other.positionName == positionName)&&(identical(other.redPlayerId, redPlayerId) || other.redPlayerId == redPlayerId)&&(identical(other.whitePlayerId, whitePlayerId) || other.whitePlayerId == whitePlayerId)&&(identical(other.redPlayerName, redPlayerName) || other.redPlayerName == redPlayerName)&&(identical(other.whitePlayerName, whitePlayerName) || other.whitePlayerName == whitePlayerName)&&(identical(other.status, status) || other.status == status)&&(identical(other.elapsedTime, elapsedTime) || other.elapsedTime == elapsedTime)&&(identical(other.isTimerRunning, isTimerRunning) || other.isTimerRunning == isTimerRunning)&&const DeepCollectionEquality().equals(other._events, _events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,positionName,redPlayerId,whitePlayerId,redPlayerName,whitePlayerName,status,elapsedTime,isTimerRunning,const DeepCollectionEquality().hash(_events));

@override
String toString() {
  return 'SubMatch(id: $id, positionName: $positionName, redPlayerId: $redPlayerId, whitePlayerId: $whitePlayerId, redPlayerName: $redPlayerName, whitePlayerName: $whitePlayerName, status: $status, elapsedTime: $elapsedTime, isTimerRunning: $isTimerRunning, events: $events)';
}


}

/// @nodoc
abstract mixin class _$SubMatchCopyWith<$Res> implements $SubMatchCopyWith<$Res> {
  factory _$SubMatchCopyWith(_SubMatch value, $Res Function(_SubMatch) _then) = __$SubMatchCopyWithImpl;
@override @useResult
$Res call({
 String id, String positionName, String? redPlayerId, String? whitePlayerId, String redPlayerName, String whitePlayerName, MatchStatus status, int elapsedTime, bool isTimerRunning, List<ScoreEvent> events
});




}
/// @nodoc
class __$SubMatchCopyWithImpl<$Res>
    implements _$SubMatchCopyWith<$Res> {
  __$SubMatchCopyWithImpl(this._self, this._then);

  final _SubMatch _self;
  final $Res Function(_SubMatch) _then;

/// Create a copy of SubMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? positionName = null,Object? redPlayerId = freezed,Object? whitePlayerId = freezed,Object? redPlayerName = null,Object? whitePlayerName = null,Object? status = null,Object? elapsedTime = null,Object? isTimerRunning = null,Object? events = null,}) {
  return _then(_SubMatch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,positionName: null == positionName ? _self.positionName : positionName // ignore: cast_nullable_to_non_nullable
as String,redPlayerId: freezed == redPlayerId ? _self.redPlayerId : redPlayerId // ignore: cast_nullable_to_non_nullable
as String?,whitePlayerId: freezed == whitePlayerId ? _self.whitePlayerId : whitePlayerId // ignore: cast_nullable_to_non_nullable
as String?,redPlayerName: null == redPlayerName ? _self.redPlayerName : redPlayerName // ignore: cast_nullable_to_non_nullable
as String,whitePlayerName: null == whitePlayerName ? _self.whitePlayerName : whitePlayerName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MatchStatus,elapsedTime: null == elapsedTime ? _self.elapsedTime : elapsedTime // ignore: cast_nullable_to_non_nullable
as int,isTimerRunning: null == isTimerRunning ? _self.isTimerRunning : isTimerRunning // ignore: cast_nullable_to_non_nullable
as bool,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<ScoreEvent>,
  ));
}


}


/// @nodoc
mixin _$KendoMatch {

 String get id; String get eventId; String get title; String get source; int get order; MatchFormat get type; TeamInfo? get teamA; TeamInfo? get teamB; MatchStatus get status; String? get scorerId; List<String> get referees; List<SubMatch> get subMatches;
/// Create a copy of KendoMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KendoMatchCopyWith<KendoMatch> get copyWith => _$KendoMatchCopyWithImpl<KendoMatch>(this as KendoMatch, _$identity);

  /// Serializes this KendoMatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KendoMatch&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.title, title) || other.title == title)&&(identical(other.source, source) || other.source == source)&&(identical(other.order, order) || other.order == order)&&(identical(other.type, type) || other.type == type)&&(identical(other.teamA, teamA) || other.teamA == teamA)&&(identical(other.teamB, teamB) || other.teamB == teamB)&&(identical(other.status, status) || other.status == status)&&(identical(other.scorerId, scorerId) || other.scorerId == scorerId)&&const DeepCollectionEquality().equals(other.referees, referees)&&const DeepCollectionEquality().equals(other.subMatches, subMatches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,title,source,order,type,teamA,teamB,status,scorerId,const DeepCollectionEquality().hash(referees),const DeepCollectionEquality().hash(subMatches));

@override
String toString() {
  return 'KendoMatch(id: $id, eventId: $eventId, title: $title, source: $source, order: $order, type: $type, teamA: $teamA, teamB: $teamB, status: $status, scorerId: $scorerId, referees: $referees, subMatches: $subMatches)';
}


}

/// @nodoc
abstract mixin class $KendoMatchCopyWith<$Res>  {
  factory $KendoMatchCopyWith(KendoMatch value, $Res Function(KendoMatch) _then) = _$KendoMatchCopyWithImpl;
@useResult
$Res call({
 String id, String eventId, String title, String source, int order, MatchFormat type, TeamInfo? teamA, TeamInfo? teamB, MatchStatus status, String? scorerId, List<String> referees, List<SubMatch> subMatches
});


$TeamInfoCopyWith<$Res>? get teamA;$TeamInfoCopyWith<$Res>? get teamB;

}
/// @nodoc
class _$KendoMatchCopyWithImpl<$Res>
    implements $KendoMatchCopyWith<$Res> {
  _$KendoMatchCopyWithImpl(this._self, this._then);

  final KendoMatch _self;
  final $Res Function(KendoMatch) _then;

/// Create a copy of KendoMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? title = null,Object? source = null,Object? order = null,Object? type = null,Object? teamA = freezed,Object? teamB = freezed,Object? status = null,Object? scorerId = freezed,Object? referees = null,Object? subMatches = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MatchFormat,teamA: freezed == teamA ? _self.teamA : teamA // ignore: cast_nullable_to_non_nullable
as TeamInfo?,teamB: freezed == teamB ? _self.teamB : teamB // ignore: cast_nullable_to_non_nullable
as TeamInfo?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MatchStatus,scorerId: freezed == scorerId ? _self.scorerId : scorerId // ignore: cast_nullable_to_non_nullable
as String?,referees: null == referees ? _self.referees : referees // ignore: cast_nullable_to_non_nullable
as List<String>,subMatches: null == subMatches ? _self.subMatches : subMatches // ignore: cast_nullable_to_non_nullable
as List<SubMatch>,
  ));
}
/// Create a copy of KendoMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamInfoCopyWith<$Res>? get teamA {
    if (_self.teamA == null) {
    return null;
  }

  return $TeamInfoCopyWith<$Res>(_self.teamA!, (value) {
    return _then(_self.copyWith(teamA: value));
  });
}/// Create a copy of KendoMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamInfoCopyWith<$Res>? get teamB {
    if (_self.teamB == null) {
    return null;
  }

  return $TeamInfoCopyWith<$Res>(_self.teamB!, (value) {
    return _then(_self.copyWith(teamB: value));
  });
}
}


/// Adds pattern-matching-related methods to [KendoMatch].
extension KendoMatchPatterns on KendoMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KendoMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KendoMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KendoMatch value)  $default,){
final _that = this;
switch (_that) {
case _KendoMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KendoMatch value)?  $default,){
final _that = this;
switch (_that) {
case _KendoMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventId,  String title,  String source,  int order,  MatchFormat type,  TeamInfo? teamA,  TeamInfo? teamB,  MatchStatus status,  String? scorerId,  List<String> referees,  List<SubMatch> subMatches)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KendoMatch() when $default != null:
return $default(_that.id,_that.eventId,_that.title,_that.source,_that.order,_that.type,_that.teamA,_that.teamB,_that.status,_that.scorerId,_that.referees,_that.subMatches);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventId,  String title,  String source,  int order,  MatchFormat type,  TeamInfo? teamA,  TeamInfo? teamB,  MatchStatus status,  String? scorerId,  List<String> referees,  List<SubMatch> subMatches)  $default,) {final _that = this;
switch (_that) {
case _KendoMatch():
return $default(_that.id,_that.eventId,_that.title,_that.source,_that.order,_that.type,_that.teamA,_that.teamB,_that.status,_that.scorerId,_that.referees,_that.subMatches);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventId,  String title,  String source,  int order,  MatchFormat type,  TeamInfo? teamA,  TeamInfo? teamB,  MatchStatus status,  String? scorerId,  List<String> referees,  List<SubMatch> subMatches)?  $default,) {final _that = this;
switch (_that) {
case _KendoMatch() when $default != null:
return $default(_that.id,_that.eventId,_that.title,_that.source,_that.order,_that.type,_that.teamA,_that.teamB,_that.status,_that.scorerId,_that.referees,_that.subMatches);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KendoMatch extends KendoMatch {
  const _KendoMatch({required this.id, required this.eventId, required this.title, this.source = 'manual', this.order = 0, this.type = MatchFormat.individual, this.teamA, this.teamB, this.status = MatchStatus.waiting, this.scorerId, final  List<String> referees = const [], final  List<SubMatch> subMatches = const []}): _referees = referees,_subMatches = subMatches,super._();
  factory _KendoMatch.fromJson(Map<String, dynamic> json) => _$KendoMatchFromJson(json);

@override final  String id;
@override final  String eventId;
@override final  String title;
@override@JsonKey() final  String source;
@override@JsonKey() final  int order;
@override@JsonKey() final  MatchFormat type;
@override final  TeamInfo? teamA;
@override final  TeamInfo? teamB;
@override@JsonKey() final  MatchStatus status;
@override final  String? scorerId;
 final  List<String> _referees;
@override@JsonKey() List<String> get referees {
  if (_referees is EqualUnmodifiableListView) return _referees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_referees);
}

 final  List<SubMatch> _subMatches;
@override@JsonKey() List<SubMatch> get subMatches {
  if (_subMatches is EqualUnmodifiableListView) return _subMatches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subMatches);
}


/// Create a copy of KendoMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KendoMatchCopyWith<_KendoMatch> get copyWith => __$KendoMatchCopyWithImpl<_KendoMatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KendoMatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KendoMatch&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.title, title) || other.title == title)&&(identical(other.source, source) || other.source == source)&&(identical(other.order, order) || other.order == order)&&(identical(other.type, type) || other.type == type)&&(identical(other.teamA, teamA) || other.teamA == teamA)&&(identical(other.teamB, teamB) || other.teamB == teamB)&&(identical(other.status, status) || other.status == status)&&(identical(other.scorerId, scorerId) || other.scorerId == scorerId)&&const DeepCollectionEquality().equals(other._referees, _referees)&&const DeepCollectionEquality().equals(other._subMatches, _subMatches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,title,source,order,type,teamA,teamB,status,scorerId,const DeepCollectionEquality().hash(_referees),const DeepCollectionEquality().hash(_subMatches));

@override
String toString() {
  return 'KendoMatch(id: $id, eventId: $eventId, title: $title, source: $source, order: $order, type: $type, teamA: $teamA, teamB: $teamB, status: $status, scorerId: $scorerId, referees: $referees, subMatches: $subMatches)';
}


}

/// @nodoc
abstract mixin class _$KendoMatchCopyWith<$Res> implements $KendoMatchCopyWith<$Res> {
  factory _$KendoMatchCopyWith(_KendoMatch value, $Res Function(_KendoMatch) _then) = __$KendoMatchCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventId, String title, String source, int order, MatchFormat type, TeamInfo? teamA, TeamInfo? teamB, MatchStatus status, String? scorerId, List<String> referees, List<SubMatch> subMatches
});


@override $TeamInfoCopyWith<$Res>? get teamA;@override $TeamInfoCopyWith<$Res>? get teamB;

}
/// @nodoc
class __$KendoMatchCopyWithImpl<$Res>
    implements _$KendoMatchCopyWith<$Res> {
  __$KendoMatchCopyWithImpl(this._self, this._then);

  final _KendoMatch _self;
  final $Res Function(_KendoMatch) _then;

/// Create a copy of KendoMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? title = null,Object? source = null,Object? order = null,Object? type = null,Object? teamA = freezed,Object? teamB = freezed,Object? status = null,Object? scorerId = freezed,Object? referees = null,Object? subMatches = null,}) {
  return _then(_KendoMatch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MatchFormat,teamA: freezed == teamA ? _self.teamA : teamA // ignore: cast_nullable_to_non_nullable
as TeamInfo?,teamB: freezed == teamB ? _self.teamB : teamB // ignore: cast_nullable_to_non_nullable
as TeamInfo?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MatchStatus,scorerId: freezed == scorerId ? _self.scorerId : scorerId // ignore: cast_nullable_to_non_nullable
as String?,referees: null == referees ? _self._referees : referees // ignore: cast_nullable_to_non_nullable
as List<String>,subMatches: null == subMatches ? _self._subMatches : subMatches // ignore: cast_nullable_to_non_nullable
as List<SubMatch>,
  ));
}

/// Create a copy of KendoMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamInfoCopyWith<$Res>? get teamA {
    if (_self.teamA == null) {
    return null;
  }

  return $TeamInfoCopyWith<$Res>(_self.teamA!, (value) {
    return _then(_self.copyWith(teamA: value));
  });
}/// Create a copy of KendoMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamInfoCopyWith<$Res>? get teamB {
    if (_self.teamB == null) {
    return null;
  }

  return $TeamInfoCopyWith<$Res>(_self.teamB!, (value) {
    return _then(_self.copyWith(teamB: value));
  });
}
}

// dart format on
