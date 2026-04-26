// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_meta.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchMeta {

 String get matchType; String get redName; String get whiteName; String get note; String? get tournamentId; String? get category; String? get groupName; int? get matchOrder; List<String> get refereeNames; bool get countForStandings; bool get isAutoAssigned;
/// Create a copy of MatchMeta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchMetaCopyWith<MatchMeta> get copyWith => _$MatchMetaCopyWithImpl<MatchMeta>(this as MatchMeta, _$identity);

  /// Serializes this MatchMeta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchMeta&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.redName, redName) || other.redName == redName)&&(identical(other.whiteName, whiteName) || other.whiteName == whiteName)&&(identical(other.note, note) || other.note == note)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.category, category) || other.category == category)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.matchOrder, matchOrder) || other.matchOrder == matchOrder)&&const DeepCollectionEquality().equals(other.refereeNames, refereeNames)&&(identical(other.countForStandings, countForStandings) || other.countForStandings == countForStandings)&&(identical(other.isAutoAssigned, isAutoAssigned) || other.isAutoAssigned == isAutoAssigned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matchType,redName,whiteName,note,tournamentId,category,groupName,matchOrder,const DeepCollectionEquality().hash(refereeNames),countForStandings,isAutoAssigned);

@override
String toString() {
  return 'MatchMeta(matchType: $matchType, redName: $redName, whiteName: $whiteName, note: $note, tournamentId: $tournamentId, category: $category, groupName: $groupName, matchOrder: $matchOrder, refereeNames: $refereeNames, countForStandings: $countForStandings, isAutoAssigned: $isAutoAssigned)';
}


}

/// @nodoc
abstract mixin class $MatchMetaCopyWith<$Res>  {
  factory $MatchMetaCopyWith(MatchMeta value, $Res Function(MatchMeta) _then) = _$MatchMetaCopyWithImpl;
@useResult
$Res call({
 String matchType, String redName, String whiteName, String note, String? tournamentId, String? category, String? groupName, int? matchOrder, List<String> refereeNames, bool countForStandings, bool isAutoAssigned
});




}
/// @nodoc
class _$MatchMetaCopyWithImpl<$Res>
    implements $MatchMetaCopyWith<$Res> {
  _$MatchMetaCopyWithImpl(this._self, this._then);

  final MatchMeta _self;
  final $Res Function(MatchMeta) _then;

/// Create a copy of MatchMeta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? matchType = null,Object? redName = null,Object? whiteName = null,Object? note = null,Object? tournamentId = freezed,Object? category = freezed,Object? groupName = freezed,Object? matchOrder = freezed,Object? refereeNames = null,Object? countForStandings = null,Object? isAutoAssigned = null,}) {
  return _then(_self.copyWith(
matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,redName: null == redName ? _self.redName : redName // ignore: cast_nullable_to_non_nullable
as String,whiteName: null == whiteName ? _self.whiteName : whiteName // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,tournamentId: freezed == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,matchOrder: freezed == matchOrder ? _self.matchOrder : matchOrder // ignore: cast_nullable_to_non_nullable
as int?,refereeNames: null == refereeNames ? _self.refereeNames : refereeNames // ignore: cast_nullable_to_non_nullable
as List<String>,countForStandings: null == countForStandings ? _self.countForStandings : countForStandings // ignore: cast_nullable_to_non_nullable
as bool,isAutoAssigned: null == isAutoAssigned ? _self.isAutoAssigned : isAutoAssigned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchMeta].
extension MatchMetaPatterns on MatchMeta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchMeta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchMeta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchMeta value)  $default,){
final _that = this;
switch (_that) {
case _MatchMeta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchMeta value)?  $default,){
final _that = this;
switch (_that) {
case _MatchMeta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String matchType,  String redName,  String whiteName,  String note,  String? tournamentId,  String? category,  String? groupName,  int? matchOrder,  List<String> refereeNames,  bool countForStandings,  bool isAutoAssigned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchMeta() when $default != null:
return $default(_that.matchType,_that.redName,_that.whiteName,_that.note,_that.tournamentId,_that.category,_that.groupName,_that.matchOrder,_that.refereeNames,_that.countForStandings,_that.isAutoAssigned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String matchType,  String redName,  String whiteName,  String note,  String? tournamentId,  String? category,  String? groupName,  int? matchOrder,  List<String> refereeNames,  bool countForStandings,  bool isAutoAssigned)  $default,) {final _that = this;
switch (_that) {
case _MatchMeta():
return $default(_that.matchType,_that.redName,_that.whiteName,_that.note,_that.tournamentId,_that.category,_that.groupName,_that.matchOrder,_that.refereeNames,_that.countForStandings,_that.isAutoAssigned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String matchType,  String redName,  String whiteName,  String note,  String? tournamentId,  String? category,  String? groupName,  int? matchOrder,  List<String> refereeNames,  bool countForStandings,  bool isAutoAssigned)?  $default,) {final _that = this;
switch (_that) {
case _MatchMeta() when $default != null:
return $default(_that.matchType,_that.redName,_that.whiteName,_that.note,_that.tournamentId,_that.category,_that.groupName,_that.matchOrder,_that.refereeNames,_that.countForStandings,_that.isAutoAssigned);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchMeta extends MatchMeta {
  const _MatchMeta({required this.matchType, required this.redName, required this.whiteName, this.note = '', this.tournamentId, this.category, this.groupName, this.matchOrder, final  List<String> refereeNames = const [], this.countForStandings = false, this.isAutoAssigned = false}): _refereeNames = refereeNames,super._();
  factory _MatchMeta.fromJson(Map<String, dynamic> json) => _$MatchMetaFromJson(json);

@override final  String matchType;
@override final  String redName;
@override final  String whiteName;
@override@JsonKey() final  String note;
@override final  String? tournamentId;
@override final  String? category;
@override final  String? groupName;
@override final  int? matchOrder;
 final  List<String> _refereeNames;
@override@JsonKey() List<String> get refereeNames {
  if (_refereeNames is EqualUnmodifiableListView) return _refereeNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_refereeNames);
}

@override@JsonKey() final  bool countForStandings;
@override@JsonKey() final  bool isAutoAssigned;

/// Create a copy of MatchMeta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchMetaCopyWith<_MatchMeta> get copyWith => __$MatchMetaCopyWithImpl<_MatchMeta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchMetaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchMeta&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.redName, redName) || other.redName == redName)&&(identical(other.whiteName, whiteName) || other.whiteName == whiteName)&&(identical(other.note, note) || other.note == note)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.category, category) || other.category == category)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.matchOrder, matchOrder) || other.matchOrder == matchOrder)&&const DeepCollectionEquality().equals(other._refereeNames, _refereeNames)&&(identical(other.countForStandings, countForStandings) || other.countForStandings == countForStandings)&&(identical(other.isAutoAssigned, isAutoAssigned) || other.isAutoAssigned == isAutoAssigned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matchType,redName,whiteName,note,tournamentId,category,groupName,matchOrder,const DeepCollectionEquality().hash(_refereeNames),countForStandings,isAutoAssigned);

@override
String toString() {
  return 'MatchMeta(matchType: $matchType, redName: $redName, whiteName: $whiteName, note: $note, tournamentId: $tournamentId, category: $category, groupName: $groupName, matchOrder: $matchOrder, refereeNames: $refereeNames, countForStandings: $countForStandings, isAutoAssigned: $isAutoAssigned)';
}


}

/// @nodoc
abstract mixin class _$MatchMetaCopyWith<$Res> implements $MatchMetaCopyWith<$Res> {
  factory _$MatchMetaCopyWith(_MatchMeta value, $Res Function(_MatchMeta) _then) = __$MatchMetaCopyWithImpl;
@override @useResult
$Res call({
 String matchType, String redName, String whiteName, String note, String? tournamentId, String? category, String? groupName, int? matchOrder, List<String> refereeNames, bool countForStandings, bool isAutoAssigned
});




}
/// @nodoc
class __$MatchMetaCopyWithImpl<$Res>
    implements _$MatchMetaCopyWith<$Res> {
  __$MatchMetaCopyWithImpl(this._self, this._then);

  final _MatchMeta _self;
  final $Res Function(_MatchMeta) _then;

/// Create a copy of MatchMeta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? matchType = null,Object? redName = null,Object? whiteName = null,Object? note = null,Object? tournamentId = freezed,Object? category = freezed,Object? groupName = freezed,Object? matchOrder = freezed,Object? refereeNames = null,Object? countForStandings = null,Object? isAutoAssigned = null,}) {
  return _then(_MatchMeta(
matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,redName: null == redName ? _self.redName : redName // ignore: cast_nullable_to_non_nullable
as String,whiteName: null == whiteName ? _self.whiteName : whiteName // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,tournamentId: freezed == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,matchOrder: freezed == matchOrder ? _self.matchOrder : matchOrder // ignore: cast_nullable_to_non_nullable
as int?,refereeNames: null == refereeNames ? _self._refereeNames : refereeNames // ignore: cast_nullable_to_non_nullable
as List<String>,countForStandings: null == countForStandings ? _self.countForStandings : countForStandings // ignore: cast_nullable_to_non_nullable
as bool,isAutoAssigned: null == isAutoAssigned ? _self.isAutoAssigned : isAutoAssigned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
