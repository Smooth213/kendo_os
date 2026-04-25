// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchRule {

 List<String> get positions; double get matchTimeMinutes;// ★ 修正：1.5分などの小数に対応するため double に変更
 bool get isRunningTime; bool get isLeague; String get category; String get note; bool get isRenseikai; List<String> get baseOrder; String get teamName; bool get isKachinuki; String get kachinukiUnlimitedType; bool get hasLeagueDaihyo; String get renseikaiType; int get overallTimeMinutes; bool get isDaihyoIpponShobu; bool get hasRepresentativeMatch; bool get isEnchoUnlimited;// ★ 修正：デフォルトを「無制限ではない（回数指定）」に変更
 double get enchoTimeMinutes;// ★ 修正：小数を許容する
 int get enchoCount;// ★ 追加：延長回数を記憶する引き出し
 bool get hasHantei; List<String> get leagueOrder; double get winPoint; double get lossPoint; double get drawPoint;
/// Create a copy of MatchRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchRuleCopyWith<MatchRule> get copyWith => _$MatchRuleCopyWithImpl<MatchRule>(this as MatchRule, _$identity);

  /// Serializes this MatchRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchRule&&const DeepCollectionEquality().equals(other.positions, positions)&&(identical(other.matchTimeMinutes, matchTimeMinutes) || other.matchTimeMinutes == matchTimeMinutes)&&(identical(other.isRunningTime, isRunningTime) || other.isRunningTime == isRunningTime)&&(identical(other.isLeague, isLeague) || other.isLeague == isLeague)&&(identical(other.category, category) || other.category == category)&&(identical(other.note, note) || other.note == note)&&(identical(other.isRenseikai, isRenseikai) || other.isRenseikai == isRenseikai)&&const DeepCollectionEquality().equals(other.baseOrder, baseOrder)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&(identical(other.kachinukiUnlimitedType, kachinukiUnlimitedType) || other.kachinukiUnlimitedType == kachinukiUnlimitedType)&&(identical(other.hasLeagueDaihyo, hasLeagueDaihyo) || other.hasLeagueDaihyo == hasLeagueDaihyo)&&(identical(other.renseikaiType, renseikaiType) || other.renseikaiType == renseikaiType)&&(identical(other.overallTimeMinutes, overallTimeMinutes) || other.overallTimeMinutes == overallTimeMinutes)&&(identical(other.isDaihyoIpponShobu, isDaihyoIpponShobu) || other.isDaihyoIpponShobu == isDaihyoIpponShobu)&&(identical(other.hasRepresentativeMatch, hasRepresentativeMatch) || other.hasRepresentativeMatch == hasRepresentativeMatch)&&(identical(other.isEnchoUnlimited, isEnchoUnlimited) || other.isEnchoUnlimited == isEnchoUnlimited)&&(identical(other.enchoTimeMinutes, enchoTimeMinutes) || other.enchoTimeMinutes == enchoTimeMinutes)&&(identical(other.enchoCount, enchoCount) || other.enchoCount == enchoCount)&&(identical(other.hasHantei, hasHantei) || other.hasHantei == hasHantei)&&const DeepCollectionEquality().equals(other.leagueOrder, leagueOrder)&&(identical(other.winPoint, winPoint) || other.winPoint == winPoint)&&(identical(other.lossPoint, lossPoint) || other.lossPoint == lossPoint)&&(identical(other.drawPoint, drawPoint) || other.drawPoint == drawPoint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,const DeepCollectionEquality().hash(positions),matchTimeMinutes,isRunningTime,isLeague,category,note,isRenseikai,const DeepCollectionEquality().hash(baseOrder),teamName,isKachinuki,kachinukiUnlimitedType,hasLeagueDaihyo,renseikaiType,overallTimeMinutes,isDaihyoIpponShobu,hasRepresentativeMatch,isEnchoUnlimited,enchoTimeMinutes,enchoCount,hasHantei,const DeepCollectionEquality().hash(leagueOrder),winPoint,lossPoint,drawPoint]);

@override
String toString() {
  return 'MatchRule(positions: $positions, matchTimeMinutes: $matchTimeMinutes, isRunningTime: $isRunningTime, isLeague: $isLeague, category: $category, note: $note, isRenseikai: $isRenseikai, baseOrder: $baseOrder, teamName: $teamName, isKachinuki: $isKachinuki, kachinukiUnlimitedType: $kachinukiUnlimitedType, hasLeagueDaihyo: $hasLeagueDaihyo, renseikaiType: $renseikaiType, overallTimeMinutes: $overallTimeMinutes, isDaihyoIpponShobu: $isDaihyoIpponShobu, hasRepresentativeMatch: $hasRepresentativeMatch, isEnchoUnlimited: $isEnchoUnlimited, enchoTimeMinutes: $enchoTimeMinutes, enchoCount: $enchoCount, hasHantei: $hasHantei, leagueOrder: $leagueOrder, winPoint: $winPoint, lossPoint: $lossPoint, drawPoint: $drawPoint)';
}


}

/// @nodoc
abstract mixin class $MatchRuleCopyWith<$Res>  {
  factory $MatchRuleCopyWith(MatchRule value, $Res Function(MatchRule) _then) = _$MatchRuleCopyWithImpl;
@useResult
$Res call({
 List<String> positions, double matchTimeMinutes, bool isRunningTime, bool isLeague, String category, String note, bool isRenseikai, List<String> baseOrder, String teamName, bool isKachinuki, String kachinukiUnlimitedType, bool hasLeagueDaihyo, String renseikaiType, int overallTimeMinutes, bool isDaihyoIpponShobu, bool hasRepresentativeMatch, bool isEnchoUnlimited, double enchoTimeMinutes, int enchoCount, bool hasHantei, List<String> leagueOrder, double winPoint, double lossPoint, double drawPoint
});




}
/// @nodoc
class _$MatchRuleCopyWithImpl<$Res>
    implements $MatchRuleCopyWith<$Res> {
  _$MatchRuleCopyWithImpl(this._self, this._then);

  final MatchRule _self;
  final $Res Function(MatchRule) _then;

/// Create a copy of MatchRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? positions = null,Object? matchTimeMinutes = null,Object? isRunningTime = null,Object? isLeague = null,Object? category = null,Object? note = null,Object? isRenseikai = null,Object? baseOrder = null,Object? teamName = null,Object? isKachinuki = null,Object? kachinukiUnlimitedType = null,Object? hasLeagueDaihyo = null,Object? renseikaiType = null,Object? overallTimeMinutes = null,Object? isDaihyoIpponShobu = null,Object? hasRepresentativeMatch = null,Object? isEnchoUnlimited = null,Object? enchoTimeMinutes = null,Object? enchoCount = null,Object? hasHantei = null,Object? leagueOrder = null,Object? winPoint = null,Object? lossPoint = null,Object? drawPoint = null,}) {
  return _then(_self.copyWith(
positions: null == positions ? _self.positions : positions // ignore: cast_nullable_to_non_nullable
as List<String>,matchTimeMinutes: null == matchTimeMinutes ? _self.matchTimeMinutes : matchTimeMinutes // ignore: cast_nullable_to_non_nullable
as double,isRunningTime: null == isRunningTime ? _self.isRunningTime : isRunningTime // ignore: cast_nullable_to_non_nullable
as bool,isLeague: null == isLeague ? _self.isLeague : isLeague // ignore: cast_nullable_to_non_nullable
as bool,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,isRenseikai: null == isRenseikai ? _self.isRenseikai : isRenseikai // ignore: cast_nullable_to_non_nullable
as bool,baseOrder: null == baseOrder ? _self.baseOrder : baseOrder // ignore: cast_nullable_to_non_nullable
as List<String>,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,isKachinuki: null == isKachinuki ? _self.isKachinuki : isKachinuki // ignore: cast_nullable_to_non_nullable
as bool,kachinukiUnlimitedType: null == kachinukiUnlimitedType ? _self.kachinukiUnlimitedType : kachinukiUnlimitedType // ignore: cast_nullable_to_non_nullable
as String,hasLeagueDaihyo: null == hasLeagueDaihyo ? _self.hasLeagueDaihyo : hasLeagueDaihyo // ignore: cast_nullable_to_non_nullable
as bool,renseikaiType: null == renseikaiType ? _self.renseikaiType : renseikaiType // ignore: cast_nullable_to_non_nullable
as String,overallTimeMinutes: null == overallTimeMinutes ? _self.overallTimeMinutes : overallTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isDaihyoIpponShobu: null == isDaihyoIpponShobu ? _self.isDaihyoIpponShobu : isDaihyoIpponShobu // ignore: cast_nullable_to_non_nullable
as bool,hasRepresentativeMatch: null == hasRepresentativeMatch ? _self.hasRepresentativeMatch : hasRepresentativeMatch // ignore: cast_nullable_to_non_nullable
as bool,isEnchoUnlimited: null == isEnchoUnlimited ? _self.isEnchoUnlimited : isEnchoUnlimited // ignore: cast_nullable_to_non_nullable
as bool,enchoTimeMinutes: null == enchoTimeMinutes ? _self.enchoTimeMinutes : enchoTimeMinutes // ignore: cast_nullable_to_non_nullable
as double,enchoCount: null == enchoCount ? _self.enchoCount : enchoCount // ignore: cast_nullable_to_non_nullable
as int,hasHantei: null == hasHantei ? _self.hasHantei : hasHantei // ignore: cast_nullable_to_non_nullable
as bool,leagueOrder: null == leagueOrder ? _self.leagueOrder : leagueOrder // ignore: cast_nullable_to_non_nullable
as List<String>,winPoint: null == winPoint ? _self.winPoint : winPoint // ignore: cast_nullable_to_non_nullable
as double,lossPoint: null == lossPoint ? _self.lossPoint : lossPoint // ignore: cast_nullable_to_non_nullable
as double,drawPoint: null == drawPoint ? _self.drawPoint : drawPoint // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchRule].
extension MatchRulePatterns on MatchRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchRule value)  $default,){
final _that = this;
switch (_that) {
case _MatchRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchRule value)?  $default,){
final _that = this;
switch (_that) {
case _MatchRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> positions,  double matchTimeMinutes,  bool isRunningTime,  bool isLeague,  String category,  String note,  bool isRenseikai,  List<String> baseOrder,  String teamName,  bool isKachinuki,  String kachinukiUnlimitedType,  bool hasLeagueDaihyo,  String renseikaiType,  int overallTimeMinutes,  bool isDaihyoIpponShobu,  bool hasRepresentativeMatch,  bool isEnchoUnlimited,  double enchoTimeMinutes,  int enchoCount,  bool hasHantei,  List<String> leagueOrder,  double winPoint,  double lossPoint,  double drawPoint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchRule() when $default != null:
return $default(_that.positions,_that.matchTimeMinutes,_that.isRunningTime,_that.isLeague,_that.category,_that.note,_that.isRenseikai,_that.baseOrder,_that.teamName,_that.isKachinuki,_that.kachinukiUnlimitedType,_that.hasLeagueDaihyo,_that.renseikaiType,_that.overallTimeMinutes,_that.isDaihyoIpponShobu,_that.hasRepresentativeMatch,_that.isEnchoUnlimited,_that.enchoTimeMinutes,_that.enchoCount,_that.hasHantei,_that.leagueOrder,_that.winPoint,_that.lossPoint,_that.drawPoint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> positions,  double matchTimeMinutes,  bool isRunningTime,  bool isLeague,  String category,  String note,  bool isRenseikai,  List<String> baseOrder,  String teamName,  bool isKachinuki,  String kachinukiUnlimitedType,  bool hasLeagueDaihyo,  String renseikaiType,  int overallTimeMinutes,  bool isDaihyoIpponShobu,  bool hasRepresentativeMatch,  bool isEnchoUnlimited,  double enchoTimeMinutes,  int enchoCount,  bool hasHantei,  List<String> leagueOrder,  double winPoint,  double lossPoint,  double drawPoint)  $default,) {final _that = this;
switch (_that) {
case _MatchRule():
return $default(_that.positions,_that.matchTimeMinutes,_that.isRunningTime,_that.isLeague,_that.category,_that.note,_that.isRenseikai,_that.baseOrder,_that.teamName,_that.isKachinuki,_that.kachinukiUnlimitedType,_that.hasLeagueDaihyo,_that.renseikaiType,_that.overallTimeMinutes,_that.isDaihyoIpponShobu,_that.hasRepresentativeMatch,_that.isEnchoUnlimited,_that.enchoTimeMinutes,_that.enchoCount,_that.hasHantei,_that.leagueOrder,_that.winPoint,_that.lossPoint,_that.drawPoint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> positions,  double matchTimeMinutes,  bool isRunningTime,  bool isLeague,  String category,  String note,  bool isRenseikai,  List<String> baseOrder,  String teamName,  bool isKachinuki,  String kachinukiUnlimitedType,  bool hasLeagueDaihyo,  String renseikaiType,  int overallTimeMinutes,  bool isDaihyoIpponShobu,  bool hasRepresentativeMatch,  bool isEnchoUnlimited,  double enchoTimeMinutes,  int enchoCount,  bool hasHantei,  List<String> leagueOrder,  double winPoint,  double lossPoint,  double drawPoint)?  $default,) {final _that = this;
switch (_that) {
case _MatchRule() when $default != null:
return $default(_that.positions,_that.matchTimeMinutes,_that.isRunningTime,_that.isLeague,_that.category,_that.note,_that.isRenseikai,_that.baseOrder,_that.teamName,_that.isKachinuki,_that.kachinukiUnlimitedType,_that.hasLeagueDaihyo,_that.renseikaiType,_that.overallTimeMinutes,_that.isDaihyoIpponShobu,_that.hasRepresentativeMatch,_that.isEnchoUnlimited,_that.enchoTimeMinutes,_that.enchoCount,_that.hasHantei,_that.leagueOrder,_that.winPoint,_that.lossPoint,_that.drawPoint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchRule implements MatchRule {
  const _MatchRule({final  List<String> positions = const ['選手'], this.matchTimeMinutes = 3.0, this.isRunningTime = false, this.isLeague = false, this.category = '', this.note = '', this.isRenseikai = false, final  List<String> baseOrder = const [], this.teamName = '', this.isKachinuki = false, this.kachinukiUnlimitedType = '大将対大将', this.hasLeagueDaihyo = false, this.renseikaiType = '一試合制', this.overallTimeMinutes = 30, this.isDaihyoIpponShobu = true, this.hasRepresentativeMatch = true, this.isEnchoUnlimited = false, this.enchoTimeMinutes = 3.0, this.enchoCount = 1, this.hasHantei = false, final  List<String> leagueOrder = const [], this.winPoint = 0.0, this.lossPoint = 0.0, this.drawPoint = 0.0}): _positions = positions,_baseOrder = baseOrder,_leagueOrder = leagueOrder;
  factory _MatchRule.fromJson(Map<String, dynamic> json) => _$MatchRuleFromJson(json);

 final  List<String> _positions;
@override@JsonKey() List<String> get positions {
  if (_positions is EqualUnmodifiableListView) return _positions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_positions);
}

@override@JsonKey() final  double matchTimeMinutes;
// ★ 修正：1.5分などの小数に対応するため double に変更
@override@JsonKey() final  bool isRunningTime;
@override@JsonKey() final  bool isLeague;
@override@JsonKey() final  String category;
@override@JsonKey() final  String note;
@override@JsonKey() final  bool isRenseikai;
 final  List<String> _baseOrder;
@override@JsonKey() List<String> get baseOrder {
  if (_baseOrder is EqualUnmodifiableListView) return _baseOrder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_baseOrder);
}

@override@JsonKey() final  String teamName;
@override@JsonKey() final  bool isKachinuki;
@override@JsonKey() final  String kachinukiUnlimitedType;
@override@JsonKey() final  bool hasLeagueDaihyo;
@override@JsonKey() final  String renseikaiType;
@override@JsonKey() final  int overallTimeMinutes;
@override@JsonKey() final  bool isDaihyoIpponShobu;
@override@JsonKey() final  bool hasRepresentativeMatch;
@override@JsonKey() final  bool isEnchoUnlimited;
// ★ 修正：デフォルトを「無制限ではない（回数指定）」に変更
@override@JsonKey() final  double enchoTimeMinutes;
// ★ 修正：小数を許容する
@override@JsonKey() final  int enchoCount;
// ★ 追加：延長回数を記憶する引き出し
@override@JsonKey() final  bool hasHantei;
 final  List<String> _leagueOrder;
@override@JsonKey() List<String> get leagueOrder {
  if (_leagueOrder is EqualUnmodifiableListView) return _leagueOrder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_leagueOrder);
}

@override@JsonKey() final  double winPoint;
@override@JsonKey() final  double lossPoint;
@override@JsonKey() final  double drawPoint;

/// Create a copy of MatchRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchRuleCopyWith<_MatchRule> get copyWith => __$MatchRuleCopyWithImpl<_MatchRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchRuleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchRule&&const DeepCollectionEquality().equals(other._positions, _positions)&&(identical(other.matchTimeMinutes, matchTimeMinutes) || other.matchTimeMinutes == matchTimeMinutes)&&(identical(other.isRunningTime, isRunningTime) || other.isRunningTime == isRunningTime)&&(identical(other.isLeague, isLeague) || other.isLeague == isLeague)&&(identical(other.category, category) || other.category == category)&&(identical(other.note, note) || other.note == note)&&(identical(other.isRenseikai, isRenseikai) || other.isRenseikai == isRenseikai)&&const DeepCollectionEquality().equals(other._baseOrder, _baseOrder)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.isKachinuki, isKachinuki) || other.isKachinuki == isKachinuki)&&(identical(other.kachinukiUnlimitedType, kachinukiUnlimitedType) || other.kachinukiUnlimitedType == kachinukiUnlimitedType)&&(identical(other.hasLeagueDaihyo, hasLeagueDaihyo) || other.hasLeagueDaihyo == hasLeagueDaihyo)&&(identical(other.renseikaiType, renseikaiType) || other.renseikaiType == renseikaiType)&&(identical(other.overallTimeMinutes, overallTimeMinutes) || other.overallTimeMinutes == overallTimeMinutes)&&(identical(other.isDaihyoIpponShobu, isDaihyoIpponShobu) || other.isDaihyoIpponShobu == isDaihyoIpponShobu)&&(identical(other.hasRepresentativeMatch, hasRepresentativeMatch) || other.hasRepresentativeMatch == hasRepresentativeMatch)&&(identical(other.isEnchoUnlimited, isEnchoUnlimited) || other.isEnchoUnlimited == isEnchoUnlimited)&&(identical(other.enchoTimeMinutes, enchoTimeMinutes) || other.enchoTimeMinutes == enchoTimeMinutes)&&(identical(other.enchoCount, enchoCount) || other.enchoCount == enchoCount)&&(identical(other.hasHantei, hasHantei) || other.hasHantei == hasHantei)&&const DeepCollectionEquality().equals(other._leagueOrder, _leagueOrder)&&(identical(other.winPoint, winPoint) || other.winPoint == winPoint)&&(identical(other.lossPoint, lossPoint) || other.lossPoint == lossPoint)&&(identical(other.drawPoint, drawPoint) || other.drawPoint == drawPoint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,const DeepCollectionEquality().hash(_positions),matchTimeMinutes,isRunningTime,isLeague,category,note,isRenseikai,const DeepCollectionEquality().hash(_baseOrder),teamName,isKachinuki,kachinukiUnlimitedType,hasLeagueDaihyo,renseikaiType,overallTimeMinutes,isDaihyoIpponShobu,hasRepresentativeMatch,isEnchoUnlimited,enchoTimeMinutes,enchoCount,hasHantei,const DeepCollectionEquality().hash(_leagueOrder),winPoint,lossPoint,drawPoint]);

@override
String toString() {
  return 'MatchRule(positions: $positions, matchTimeMinutes: $matchTimeMinutes, isRunningTime: $isRunningTime, isLeague: $isLeague, category: $category, note: $note, isRenseikai: $isRenseikai, baseOrder: $baseOrder, teamName: $teamName, isKachinuki: $isKachinuki, kachinukiUnlimitedType: $kachinukiUnlimitedType, hasLeagueDaihyo: $hasLeagueDaihyo, renseikaiType: $renseikaiType, overallTimeMinutes: $overallTimeMinutes, isDaihyoIpponShobu: $isDaihyoIpponShobu, hasRepresentativeMatch: $hasRepresentativeMatch, isEnchoUnlimited: $isEnchoUnlimited, enchoTimeMinutes: $enchoTimeMinutes, enchoCount: $enchoCount, hasHantei: $hasHantei, leagueOrder: $leagueOrder, winPoint: $winPoint, lossPoint: $lossPoint, drawPoint: $drawPoint)';
}


}

/// @nodoc
abstract mixin class _$MatchRuleCopyWith<$Res> implements $MatchRuleCopyWith<$Res> {
  factory _$MatchRuleCopyWith(_MatchRule value, $Res Function(_MatchRule) _then) = __$MatchRuleCopyWithImpl;
@override @useResult
$Res call({
 List<String> positions, double matchTimeMinutes, bool isRunningTime, bool isLeague, String category, String note, bool isRenseikai, List<String> baseOrder, String teamName, bool isKachinuki, String kachinukiUnlimitedType, bool hasLeagueDaihyo, String renseikaiType, int overallTimeMinutes, bool isDaihyoIpponShobu, bool hasRepresentativeMatch, bool isEnchoUnlimited, double enchoTimeMinutes, int enchoCount, bool hasHantei, List<String> leagueOrder, double winPoint, double lossPoint, double drawPoint
});




}
/// @nodoc
class __$MatchRuleCopyWithImpl<$Res>
    implements _$MatchRuleCopyWith<$Res> {
  __$MatchRuleCopyWithImpl(this._self, this._then);

  final _MatchRule _self;
  final $Res Function(_MatchRule) _then;

/// Create a copy of MatchRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? positions = null,Object? matchTimeMinutes = null,Object? isRunningTime = null,Object? isLeague = null,Object? category = null,Object? note = null,Object? isRenseikai = null,Object? baseOrder = null,Object? teamName = null,Object? isKachinuki = null,Object? kachinukiUnlimitedType = null,Object? hasLeagueDaihyo = null,Object? renseikaiType = null,Object? overallTimeMinutes = null,Object? isDaihyoIpponShobu = null,Object? hasRepresentativeMatch = null,Object? isEnchoUnlimited = null,Object? enchoTimeMinutes = null,Object? enchoCount = null,Object? hasHantei = null,Object? leagueOrder = null,Object? winPoint = null,Object? lossPoint = null,Object? drawPoint = null,}) {
  return _then(_MatchRule(
positions: null == positions ? _self._positions : positions // ignore: cast_nullable_to_non_nullable
as List<String>,matchTimeMinutes: null == matchTimeMinutes ? _self.matchTimeMinutes : matchTimeMinutes // ignore: cast_nullable_to_non_nullable
as double,isRunningTime: null == isRunningTime ? _self.isRunningTime : isRunningTime // ignore: cast_nullable_to_non_nullable
as bool,isLeague: null == isLeague ? _self.isLeague : isLeague // ignore: cast_nullable_to_non_nullable
as bool,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,isRenseikai: null == isRenseikai ? _self.isRenseikai : isRenseikai // ignore: cast_nullable_to_non_nullable
as bool,baseOrder: null == baseOrder ? _self._baseOrder : baseOrder // ignore: cast_nullable_to_non_nullable
as List<String>,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,isKachinuki: null == isKachinuki ? _self.isKachinuki : isKachinuki // ignore: cast_nullable_to_non_nullable
as bool,kachinukiUnlimitedType: null == kachinukiUnlimitedType ? _self.kachinukiUnlimitedType : kachinukiUnlimitedType // ignore: cast_nullable_to_non_nullable
as String,hasLeagueDaihyo: null == hasLeagueDaihyo ? _self.hasLeagueDaihyo : hasLeagueDaihyo // ignore: cast_nullable_to_non_nullable
as bool,renseikaiType: null == renseikaiType ? _self.renseikaiType : renseikaiType // ignore: cast_nullable_to_non_nullable
as String,overallTimeMinutes: null == overallTimeMinutes ? _self.overallTimeMinutes : overallTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isDaihyoIpponShobu: null == isDaihyoIpponShobu ? _self.isDaihyoIpponShobu : isDaihyoIpponShobu // ignore: cast_nullable_to_non_nullable
as bool,hasRepresentativeMatch: null == hasRepresentativeMatch ? _self.hasRepresentativeMatch : hasRepresentativeMatch // ignore: cast_nullable_to_non_nullable
as bool,isEnchoUnlimited: null == isEnchoUnlimited ? _self.isEnchoUnlimited : isEnchoUnlimited // ignore: cast_nullable_to_non_nullable
as bool,enchoTimeMinutes: null == enchoTimeMinutes ? _self.enchoTimeMinutes : enchoTimeMinutes // ignore: cast_nullable_to_non_nullable
as double,enchoCount: null == enchoCount ? _self.enchoCount : enchoCount // ignore: cast_nullable_to_non_nullable
as int,hasHantei: null == hasHantei ? _self.hasHantei : hasHantei // ignore: cast_nullable_to_non_nullable
as bool,leagueOrder: null == leagueOrder ? _self._leagueOrder : leagueOrder // ignore: cast_nullable_to_non_nullable
as List<String>,winPoint: null == winPoint ? _self.winPoint : winPoint // ignore: cast_nullable_to_non_nullable
as double,lossPoint: null == lossPoint ? _self.lossPoint : lossPoint // ignore: cast_nullable_to_non_nullable
as double,drawPoint: null == drawPoint ? _self.drawPoint : drawPoint // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
