// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'league_standing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LeagueStanding {

 String get playerName; int get matchesPlayed; int get wins; int get losses; int get draws; int get pointsFor;// 取得本数
 int get pointsAgainst;
/// Create a copy of LeagueStanding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeagueStandingCopyWith<LeagueStanding> get copyWith => _$LeagueStandingCopyWithImpl<LeagueStanding>(this as LeagueStanding, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeagueStanding&&(identical(other.playerName, playerName) || other.playerName == playerName)&&(identical(other.matchesPlayed, matchesPlayed) || other.matchesPlayed == matchesPlayed)&&(identical(other.wins, wins) || other.wins == wins)&&(identical(other.losses, losses) || other.losses == losses)&&(identical(other.draws, draws) || other.draws == draws)&&(identical(other.pointsFor, pointsFor) || other.pointsFor == pointsFor)&&(identical(other.pointsAgainst, pointsAgainst) || other.pointsAgainst == pointsAgainst));
}


@override
int get hashCode => Object.hash(runtimeType,playerName,matchesPlayed,wins,losses,draws,pointsFor,pointsAgainst);

@override
String toString() {
  return 'LeagueStanding(playerName: $playerName, matchesPlayed: $matchesPlayed, wins: $wins, losses: $losses, draws: $draws, pointsFor: $pointsFor, pointsAgainst: $pointsAgainst)';
}


}

/// @nodoc
abstract mixin class $LeagueStandingCopyWith<$Res>  {
  factory $LeagueStandingCopyWith(LeagueStanding value, $Res Function(LeagueStanding) _then) = _$LeagueStandingCopyWithImpl;
@useResult
$Res call({
 String playerName, int matchesPlayed, int wins, int losses, int draws, int pointsFor, int pointsAgainst
});




}
/// @nodoc
class _$LeagueStandingCopyWithImpl<$Res>
    implements $LeagueStandingCopyWith<$Res> {
  _$LeagueStandingCopyWithImpl(this._self, this._then);

  final LeagueStanding _self;
  final $Res Function(LeagueStanding) _then;

/// Create a copy of LeagueStanding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerName = null,Object? matchesPlayed = null,Object? wins = null,Object? losses = null,Object? draws = null,Object? pointsFor = null,Object? pointsAgainst = null,}) {
  return _then(_self.copyWith(
playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,matchesPlayed: null == matchesPlayed ? _self.matchesPlayed : matchesPlayed // ignore: cast_nullable_to_non_nullable
as int,wins: null == wins ? _self.wins : wins // ignore: cast_nullable_to_non_nullable
as int,losses: null == losses ? _self.losses : losses // ignore: cast_nullable_to_non_nullable
as int,draws: null == draws ? _self.draws : draws // ignore: cast_nullable_to_non_nullable
as int,pointsFor: null == pointsFor ? _self.pointsFor : pointsFor // ignore: cast_nullable_to_non_nullable
as int,pointsAgainst: null == pointsAgainst ? _self.pointsAgainst : pointsAgainst // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LeagueStanding].
extension LeagueStandingPatterns on LeagueStanding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeagueStanding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeagueStanding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeagueStanding value)  $default,){
final _that = this;
switch (_that) {
case _LeagueStanding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeagueStanding value)?  $default,){
final _that = this;
switch (_that) {
case _LeagueStanding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerName,  int matchesPlayed,  int wins,  int losses,  int draws,  int pointsFor,  int pointsAgainst)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeagueStanding() when $default != null:
return $default(_that.playerName,_that.matchesPlayed,_that.wins,_that.losses,_that.draws,_that.pointsFor,_that.pointsAgainst);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerName,  int matchesPlayed,  int wins,  int losses,  int draws,  int pointsFor,  int pointsAgainst)  $default,) {final _that = this;
switch (_that) {
case _LeagueStanding():
return $default(_that.playerName,_that.matchesPlayed,_that.wins,_that.losses,_that.draws,_that.pointsFor,_that.pointsAgainst);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerName,  int matchesPlayed,  int wins,  int losses,  int draws,  int pointsFor,  int pointsAgainst)?  $default,) {final _that = this;
switch (_that) {
case _LeagueStanding() when $default != null:
return $default(_that.playerName,_that.matchesPlayed,_that.wins,_that.losses,_that.draws,_that.pointsFor,_that.pointsAgainst);case _:
  return null;

}
}

}

/// @nodoc


class _LeagueStanding implements LeagueStanding {
  const _LeagueStanding({required this.playerName, this.matchesPlayed = 0, this.wins = 0, this.losses = 0, this.draws = 0, this.pointsFor = 0, this.pointsAgainst = 0});
  

@override final  String playerName;
@override@JsonKey() final  int matchesPlayed;
@override@JsonKey() final  int wins;
@override@JsonKey() final  int losses;
@override@JsonKey() final  int draws;
@override@JsonKey() final  int pointsFor;
// 取得本数
@override@JsonKey() final  int pointsAgainst;

/// Create a copy of LeagueStanding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeagueStandingCopyWith<_LeagueStanding> get copyWith => __$LeagueStandingCopyWithImpl<_LeagueStanding>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeagueStanding&&(identical(other.playerName, playerName) || other.playerName == playerName)&&(identical(other.matchesPlayed, matchesPlayed) || other.matchesPlayed == matchesPlayed)&&(identical(other.wins, wins) || other.wins == wins)&&(identical(other.losses, losses) || other.losses == losses)&&(identical(other.draws, draws) || other.draws == draws)&&(identical(other.pointsFor, pointsFor) || other.pointsFor == pointsFor)&&(identical(other.pointsAgainst, pointsAgainst) || other.pointsAgainst == pointsAgainst));
}


@override
int get hashCode => Object.hash(runtimeType,playerName,matchesPlayed,wins,losses,draws,pointsFor,pointsAgainst);

@override
String toString() {
  return 'LeagueStanding(playerName: $playerName, matchesPlayed: $matchesPlayed, wins: $wins, losses: $losses, draws: $draws, pointsFor: $pointsFor, pointsAgainst: $pointsAgainst)';
}


}

/// @nodoc
abstract mixin class _$LeagueStandingCopyWith<$Res> implements $LeagueStandingCopyWith<$Res> {
  factory _$LeagueStandingCopyWith(_LeagueStanding value, $Res Function(_LeagueStanding) _then) = __$LeagueStandingCopyWithImpl;
@override @useResult
$Res call({
 String playerName, int matchesPlayed, int wins, int losses, int draws, int pointsFor, int pointsAgainst
});




}
/// @nodoc
class __$LeagueStandingCopyWithImpl<$Res>
    implements _$LeagueStandingCopyWith<$Res> {
  __$LeagueStandingCopyWithImpl(this._self, this._then);

  final _LeagueStanding _self;
  final $Res Function(_LeagueStanding) _then;

/// Create a copy of LeagueStanding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerName = null,Object? matchesPlayed = null,Object? wins = null,Object? losses = null,Object? draws = null,Object? pointsFor = null,Object? pointsAgainst = null,}) {
  return _then(_LeagueStanding(
playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,matchesPlayed: null == matchesPlayed ? _self.matchesPlayed : matchesPlayed // ignore: cast_nullable_to_non_nullable
as int,wins: null == wins ? _self.wins : wins // ignore: cast_nullable_to_non_nullable
as int,losses: null == losses ? _self.losses : losses // ignore: cast_nullable_to_non_nullable
as int,draws: null == draws ? _self.draws : draws // ignore: cast_nullable_to_non_nullable
as int,pointsFor: null == pointsFor ? _self.pointsFor : pointsFor // ignore: cast_nullable_to_non_nullable
as int,pointsAgainst: null == pointsAgainst ? _self.pointsAgainst : pointsAgainst // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
