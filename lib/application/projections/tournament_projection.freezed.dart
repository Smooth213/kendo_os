// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tournament_projection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TeamMatchProjection {

 String get groupName; String get redTeamName; String get whiteTeamName; String get matchType; String get note; bool get isKachinuki; bool get isLeague; List<MatchProjection> get matches; TeamMatchResult get result; List<LeagueTeamStat> get leagueStandings;
/// Create a copy of TeamMatchProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamMatchProjectionCopyWith<TeamMatchProjection> get copyWith => _$TeamMatchProjectionCopyWithImpl<TeamMatchProjection>(this as TeamMatchProjection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamMatchProjection&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.redTeamName, redTeamName) || other.redTeamName == redTeamName)&&(identical(other.whiteTeamName, whiteTeamName) || other.whiteTeamName == whiteTeamName)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.note, note) || other.note == note)&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&(identical(other.isLeague, isLeague) || other.isLeague == isLeague)&&const DeepCollectionEquality().equals(other.matches, matches)&&(identical(other.result, result) || other.result == result)&&const DeepCollectionEquality().equals(other.leagueStandings, leagueStandings));
}


@override
int get hashCode => Object.hash(runtimeType,groupName,redTeamName,whiteTeamName,matchType,note,isKachinuki,isLeague,const DeepCollectionEquality().hash(matches),result,const DeepCollectionEquality().hash(leagueStandings));

@override
String toString() {
  return 'TeamMatchProjection(groupName: $groupName, redTeamName: $redTeamName, whiteTeamName: $whiteTeamName, matchType: $matchType, note: $note, isKachinuki: $isKachinuki, isLeague: $isLeague, matches: $matches, result: $result, leagueStandings: $leagueStandings)';
}


}

/// @nodoc
abstract mixin class $TeamMatchProjectionCopyWith<$Res>  {
  factory $TeamMatchProjectionCopyWith(TeamMatchProjection value, $Res Function(TeamMatchProjection) _then) = _$TeamMatchProjectionCopyWithImpl;
@useResult
$Res call({
 String groupName, String redTeamName, String whiteTeamName, String matchType, String note, bool isKachinuki, bool isLeague, List<MatchProjection> matches, TeamMatchResult result, List<LeagueTeamStat> leagueStandings
});




}
/// @nodoc
class _$TeamMatchProjectionCopyWithImpl<$Res>
    implements $TeamMatchProjectionCopyWith<$Res> {
  _$TeamMatchProjectionCopyWithImpl(this._self, this._then);

  final TeamMatchProjection _self;
  final $Res Function(TeamMatchProjection) _then;

/// Create a copy of TeamMatchProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupName = null,Object? redTeamName = null,Object? whiteTeamName = null,Object? matchType = null,Object? note = null,Object? isKachinuki = null,Object? isLeague = null,Object? matches = null,Object? result = null,Object? leagueStandings = null,}) {
  return _then(_self.copyWith(
groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,redTeamName: null == redTeamName ? _self.redTeamName : redTeamName // ignore: cast_nullable_to_non_nullable
as String,whiteTeamName: null == whiteTeamName ? _self.whiteTeamName : whiteTeamName // ignore: cast_nullable_to_non_nullable
as String,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,isKachinuki: null == isKachinuki ? _self.isKachinuki : isKachinuki // ignore: cast_nullable_to_non_nullable
as bool,isLeague: null == isLeague ? _self.isLeague : isLeague // ignore: cast_nullable_to_non_nullable
as bool,matches: null == matches ? _self.matches : matches // ignore: cast_nullable_to_non_nullable
as List<MatchProjection>,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as TeamMatchResult,leagueStandings: null == leagueStandings ? _self.leagueStandings : leagueStandings // ignore: cast_nullable_to_non_nullable
as List<LeagueTeamStat>,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamMatchProjection].
extension TeamMatchProjectionPatterns on TeamMatchProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamMatchProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamMatchProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamMatchProjection value)  $default,){
final _that = this;
switch (_that) {
case _TeamMatchProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamMatchProjection value)?  $default,){
final _that = this;
switch (_that) {
case _TeamMatchProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String groupName,  String redTeamName,  String whiteTeamName,  String matchType,  String note,  bool isKachinuki,  bool isLeague,  List<MatchProjection> matches,  TeamMatchResult result,  List<LeagueTeamStat> leagueStandings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamMatchProjection() when $default != null:
return $default(_that.groupName,_that.redTeamName,_that.whiteTeamName,_that.matchType,_that.note,_that.isKachinuki,_that.isLeague,_that.matches,_that.result,_that.leagueStandings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String groupName,  String redTeamName,  String whiteTeamName,  String matchType,  String note,  bool isKachinuki,  bool isLeague,  List<MatchProjection> matches,  TeamMatchResult result,  List<LeagueTeamStat> leagueStandings)  $default,) {final _that = this;
switch (_that) {
case _TeamMatchProjection():
return $default(_that.groupName,_that.redTeamName,_that.whiteTeamName,_that.matchType,_that.note,_that.isKachinuki,_that.isLeague,_that.matches,_that.result,_that.leagueStandings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String groupName,  String redTeamName,  String whiteTeamName,  String matchType,  String note,  bool isKachinuki,  bool isLeague,  List<MatchProjection> matches,  TeamMatchResult result,  List<LeagueTeamStat> leagueStandings)?  $default,) {final _that = this;
switch (_that) {
case _TeamMatchProjection() when $default != null:
return $default(_that.groupName,_that.redTeamName,_that.whiteTeamName,_that.matchType,_that.note,_that.isKachinuki,_that.isLeague,_that.matches,_that.result,_that.leagueStandings);case _:
  return null;

}
}

}

/// @nodoc


class _TeamMatchProjection implements TeamMatchProjection {
  const _TeamMatchProjection({required this.groupName, required this.redTeamName, required this.whiteTeamName, required this.matchType, required this.note, required this.isKachinuki, required this.isLeague, required final  List<MatchProjection> matches, required this.result, final  List<LeagueTeamStat> leagueStandings = const []}): _matches = matches,_leagueStandings = leagueStandings;
  

@override final  String groupName;
@override final  String redTeamName;
@override final  String whiteTeamName;
@override final  String matchType;
@override final  String note;
@override final  bool isKachinuki;
@override final  bool isLeague;
 final  List<MatchProjection> _matches;
@override List<MatchProjection> get matches {
  if (_matches is EqualUnmodifiableListView) return _matches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matches);
}

@override final  TeamMatchResult result;
 final  List<LeagueTeamStat> _leagueStandings;
@override@JsonKey() List<LeagueTeamStat> get leagueStandings {
  if (_leagueStandings is EqualUnmodifiableListView) return _leagueStandings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_leagueStandings);
}


/// Create a copy of TeamMatchProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamMatchProjectionCopyWith<_TeamMatchProjection> get copyWith => __$TeamMatchProjectionCopyWithImpl<_TeamMatchProjection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamMatchProjection&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.redTeamName, redTeamName) || other.redTeamName == redTeamName)&&(identical(other.whiteTeamName, whiteTeamName) || other.whiteTeamName == whiteTeamName)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.note, note) || other.note == note)&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&(identical(other.isLeague, isLeague) || other.isLeague == isLeague)&&const DeepCollectionEquality().equals(other._matches, _matches)&&(identical(other.result, result) || other.result == result)&&const DeepCollectionEquality().equals(other._leagueStandings, _leagueStandings));
}


@override
int get hashCode => Object.hash(runtimeType,groupName,redTeamName,whiteTeamName,matchType,note,isKachinuki,isLeague,const DeepCollectionEquality().hash(_matches),result,const DeepCollectionEquality().hash(_leagueStandings));

@override
String toString() {
  return 'TeamMatchProjection(groupName: $groupName, redTeamName: $redTeamName, whiteTeamName: $whiteTeamName, matchType: $matchType, note: $note, isKachinuki: $isKachinuki, isLeague: $isLeague, matches: $matches, result: $result, leagueStandings: $leagueStandings)';
}


}

/// @nodoc
abstract mixin class _$TeamMatchProjectionCopyWith<$Res> implements $TeamMatchProjectionCopyWith<$Res> {
  factory _$TeamMatchProjectionCopyWith(_TeamMatchProjection value, $Res Function(_TeamMatchProjection) _then) = __$TeamMatchProjectionCopyWithImpl;
@override @useResult
$Res call({
 String groupName, String redTeamName, String whiteTeamName, String matchType, String note, bool isKachinuki, bool isLeague, List<MatchProjection> matches, TeamMatchResult result, List<LeagueTeamStat> leagueStandings
});




}
/// @nodoc
class __$TeamMatchProjectionCopyWithImpl<$Res>
    implements _$TeamMatchProjectionCopyWith<$Res> {
  __$TeamMatchProjectionCopyWithImpl(this._self, this._then);

  final _TeamMatchProjection _self;
  final $Res Function(_TeamMatchProjection) _then;

/// Create a copy of TeamMatchProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupName = null,Object? redTeamName = null,Object? whiteTeamName = null,Object? matchType = null,Object? note = null,Object? isKachinuki = null,Object? isLeague = null,Object? matches = null,Object? result = null,Object? leagueStandings = null,}) {
  return _then(_TeamMatchProjection(
groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,redTeamName: null == redTeamName ? _self.redTeamName : redTeamName // ignore: cast_nullable_to_non_nullable
as String,whiteTeamName: null == whiteTeamName ? _self.whiteTeamName : whiteTeamName // ignore: cast_nullable_to_non_nullable
as String,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,isKachinuki: null == isKachinuki ? _self.isKachinuki : isKachinuki // ignore: cast_nullable_to_non_nullable
as bool,isLeague: null == isLeague ? _self.isLeague : isLeague // ignore: cast_nullable_to_non_nullable
as bool,matches: null == matches ? _self._matches : matches // ignore: cast_nullable_to_non_nullable
as List<MatchProjection>,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as TeamMatchResult,leagueStandings: null == leagueStandings ? _self._leagueStandings : leagueStandings // ignore: cast_nullable_to_non_nullable
as List<LeagueTeamStat>,
  ));
}


}

/// @nodoc
mixin _$TournamentProjection {

 TournamentModel get tournament; List<MatchProjection> get allMatches; Map<String, TeamMatchProjection> get teamMatches;// --- 追加: 公式記録用の集計データ ---
 Map<String, List<String>> get categoryToGroupKeys;
/// Create a copy of TournamentProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TournamentProjectionCopyWith<TournamentProjection> get copyWith => _$TournamentProjectionCopyWithImpl<TournamentProjection>(this as TournamentProjection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TournamentProjection&&(identical(other.tournament, tournament) || other.tournament == tournament)&&const DeepCollectionEquality().equals(other.allMatches, allMatches)&&const DeepCollectionEquality().equals(other.teamMatches, teamMatches)&&const DeepCollectionEquality().equals(other.categoryToGroupKeys, categoryToGroupKeys));
}


@override
int get hashCode => Object.hash(runtimeType,tournament,const DeepCollectionEquality().hash(allMatches),const DeepCollectionEquality().hash(teamMatches),const DeepCollectionEquality().hash(categoryToGroupKeys));

@override
String toString() {
  return 'TournamentProjection(tournament: $tournament, allMatches: $allMatches, teamMatches: $teamMatches, categoryToGroupKeys: $categoryToGroupKeys)';
}


}

/// @nodoc
abstract mixin class $TournamentProjectionCopyWith<$Res>  {
  factory $TournamentProjectionCopyWith(TournamentProjection value, $Res Function(TournamentProjection) _then) = _$TournamentProjectionCopyWithImpl;
@useResult
$Res call({
 TournamentModel tournament, List<MatchProjection> allMatches, Map<String, TeamMatchProjection> teamMatches, Map<String, List<String>> categoryToGroupKeys
});


$TournamentModelCopyWith<$Res> get tournament;

}
/// @nodoc
class _$TournamentProjectionCopyWithImpl<$Res>
    implements $TournamentProjectionCopyWith<$Res> {
  _$TournamentProjectionCopyWithImpl(this._self, this._then);

  final TournamentProjection _self;
  final $Res Function(TournamentProjection) _then;

/// Create a copy of TournamentProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tournament = null,Object? allMatches = null,Object? teamMatches = null,Object? categoryToGroupKeys = null,}) {
  return _then(_self.copyWith(
tournament: null == tournament ? _self.tournament : tournament // ignore: cast_nullable_to_non_nullable
as TournamentModel,allMatches: null == allMatches ? _self.allMatches : allMatches // ignore: cast_nullable_to_non_nullable
as List<MatchProjection>,teamMatches: null == teamMatches ? _self.teamMatches : teamMatches // ignore: cast_nullable_to_non_nullable
as Map<String, TeamMatchProjection>,categoryToGroupKeys: null == categoryToGroupKeys ? _self.categoryToGroupKeys : categoryToGroupKeys // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,
  ));
}
/// Create a copy of TournamentProjection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TournamentModelCopyWith<$Res> get tournament {
  
  return $TournamentModelCopyWith<$Res>(_self.tournament, (value) {
    return _then(_self.copyWith(tournament: value));
  });
}
}


/// Adds pattern-matching-related methods to [TournamentProjection].
extension TournamentProjectionPatterns on TournamentProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TournamentProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TournamentProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TournamentProjection value)  $default,){
final _that = this;
switch (_that) {
case _TournamentProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TournamentProjection value)?  $default,){
final _that = this;
switch (_that) {
case _TournamentProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TournamentModel tournament,  List<MatchProjection> allMatches,  Map<String, TeamMatchProjection> teamMatches,  Map<String, List<String>> categoryToGroupKeys)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TournamentProjection() when $default != null:
return $default(_that.tournament,_that.allMatches,_that.teamMatches,_that.categoryToGroupKeys);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TournamentModel tournament,  List<MatchProjection> allMatches,  Map<String, TeamMatchProjection> teamMatches,  Map<String, List<String>> categoryToGroupKeys)  $default,) {final _that = this;
switch (_that) {
case _TournamentProjection():
return $default(_that.tournament,_that.allMatches,_that.teamMatches,_that.categoryToGroupKeys);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TournamentModel tournament,  List<MatchProjection> allMatches,  Map<String, TeamMatchProjection> teamMatches,  Map<String, List<String>> categoryToGroupKeys)?  $default,) {final _that = this;
switch (_that) {
case _TournamentProjection() when $default != null:
return $default(_that.tournament,_that.allMatches,_that.teamMatches,_that.categoryToGroupKeys);case _:
  return null;

}
}

}

/// @nodoc


class _TournamentProjection implements TournamentProjection {
  const _TournamentProjection({required this.tournament, required final  List<MatchProjection> allMatches, required final  Map<String, TeamMatchProjection> teamMatches, required final  Map<String, List<String>> categoryToGroupKeys}): _allMatches = allMatches,_teamMatches = teamMatches,_categoryToGroupKeys = categoryToGroupKeys;
  

@override final  TournamentModel tournament;
 final  List<MatchProjection> _allMatches;
@override List<MatchProjection> get allMatches {
  if (_allMatches is EqualUnmodifiableListView) return _allMatches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allMatches);
}

 final  Map<String, TeamMatchProjection> _teamMatches;
@override Map<String, TeamMatchProjection> get teamMatches {
  if (_teamMatches is EqualUnmodifiableMapView) return _teamMatches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_teamMatches);
}

// --- 追加: 公式記録用の集計データ ---
 final  Map<String, List<String>> _categoryToGroupKeys;
// --- 追加: 公式記録用の集計データ ---
@override Map<String, List<String>> get categoryToGroupKeys {
  if (_categoryToGroupKeys is EqualUnmodifiableMapView) return _categoryToGroupKeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categoryToGroupKeys);
}


/// Create a copy of TournamentProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TournamentProjectionCopyWith<_TournamentProjection> get copyWith => __$TournamentProjectionCopyWithImpl<_TournamentProjection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TournamentProjection&&(identical(other.tournament, tournament) || other.tournament == tournament)&&const DeepCollectionEquality().equals(other._allMatches, _allMatches)&&const DeepCollectionEquality().equals(other._teamMatches, _teamMatches)&&const DeepCollectionEquality().equals(other._categoryToGroupKeys, _categoryToGroupKeys));
}


@override
int get hashCode => Object.hash(runtimeType,tournament,const DeepCollectionEquality().hash(_allMatches),const DeepCollectionEquality().hash(_teamMatches),const DeepCollectionEquality().hash(_categoryToGroupKeys));

@override
String toString() {
  return 'TournamentProjection(tournament: $tournament, allMatches: $allMatches, teamMatches: $teamMatches, categoryToGroupKeys: $categoryToGroupKeys)';
}


}

/// @nodoc
abstract mixin class _$TournamentProjectionCopyWith<$Res> implements $TournamentProjectionCopyWith<$Res> {
  factory _$TournamentProjectionCopyWith(_TournamentProjection value, $Res Function(_TournamentProjection) _then) = __$TournamentProjectionCopyWithImpl;
@override @useResult
$Res call({
 TournamentModel tournament, List<MatchProjection> allMatches, Map<String, TeamMatchProjection> teamMatches, Map<String, List<String>> categoryToGroupKeys
});


@override $TournamentModelCopyWith<$Res> get tournament;

}
/// @nodoc
class __$TournamentProjectionCopyWithImpl<$Res>
    implements _$TournamentProjectionCopyWith<$Res> {
  __$TournamentProjectionCopyWithImpl(this._self, this._then);

  final _TournamentProjection _self;
  final $Res Function(_TournamentProjection) _then;

/// Create a copy of TournamentProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tournament = null,Object? allMatches = null,Object? teamMatches = null,Object? categoryToGroupKeys = null,}) {
  return _then(_TournamentProjection(
tournament: null == tournament ? _self.tournament : tournament // ignore: cast_nullable_to_non_nullable
as TournamentModel,allMatches: null == allMatches ? _self._allMatches : allMatches // ignore: cast_nullable_to_non_nullable
as List<MatchProjection>,teamMatches: null == teamMatches ? _self._teamMatches : teamMatches // ignore: cast_nullable_to_non_nullable
as Map<String, TeamMatchProjection>,categoryToGroupKeys: null == categoryToGroupKeys ? _self._categoryToGroupKeys : categoryToGroupKeys // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,
  ));
}

/// Create a copy of TournamentProjection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TournamentModelCopyWith<$Res> get tournament {
  
  return $TournamentModelCopyWith<$Res>(_self.tournament, (value) {
    return _then(_self.copyWith(tournament: value));
  });
}
}

// dart format on
