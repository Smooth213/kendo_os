// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_rule_set.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategoryRuleSet {

 MatchRule get normalRule; MatchRule get advancedRule; bool get useAdvancedRule; List<String> get advancedKeywords; String get matchType; bool get isMultiScene; bool get useHonsenRule; bool get useRenseikaiRule; bool get useMoushiawaseRule; MatchRule get renseikaiRule; MatchRule get moushiawaseRule;
/// Create a copy of CategoryRuleSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryRuleSetCopyWith<CategoryRuleSet> get copyWith => _$CategoryRuleSetCopyWithImpl<CategoryRuleSet>(this as CategoryRuleSet, _$identity);

  /// Serializes this CategoryRuleSet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryRuleSet&&(identical(other.normalRule, normalRule) || other.normalRule == normalRule)&&(identical(other.advancedRule, advancedRule) || other.advancedRule == advancedRule)&&(identical(other.useAdvancedRule, useAdvancedRule) || other.useAdvancedRule == useAdvancedRule)&&const DeepCollectionEquality().equals(other.advancedKeywords, advancedKeywords)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.isMultiScene, isMultiScene) || other.isMultiScene == isMultiScene)&&(identical(other.useHonsenRule, useHonsenRule) || other.useHonsenRule == useHonsenRule)&&(identical(other.useRenseikaiRule, useRenseikaiRule) || other.useRenseikaiRule == useRenseikaiRule)&&(identical(other.useMoushiawaseRule, useMoushiawaseRule) || other.useMoushiawaseRule == useMoushiawaseRule)&&(identical(other.renseikaiRule, renseikaiRule) || other.renseikaiRule == renseikaiRule)&&(identical(other.moushiawaseRule, moushiawaseRule) || other.moushiawaseRule == moushiawaseRule));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,normalRule,advancedRule,useAdvancedRule,const DeepCollectionEquality().hash(advancedKeywords),matchType,isMultiScene,useHonsenRule,useRenseikaiRule,useMoushiawaseRule,renseikaiRule,moushiawaseRule);

@override
String toString() {
  return 'CategoryRuleSet(normalRule: $normalRule, advancedRule: $advancedRule, useAdvancedRule: $useAdvancedRule, advancedKeywords: $advancedKeywords, matchType: $matchType, isMultiScene: $isMultiScene, useHonsenRule: $useHonsenRule, useRenseikaiRule: $useRenseikaiRule, useMoushiawaseRule: $useMoushiawaseRule, renseikaiRule: $renseikaiRule, moushiawaseRule: $moushiawaseRule)';
}


}

/// @nodoc
abstract mixin class $CategoryRuleSetCopyWith<$Res>  {
  factory $CategoryRuleSetCopyWith(CategoryRuleSet value, $Res Function(CategoryRuleSet) _then) = _$CategoryRuleSetCopyWithImpl;
@useResult
$Res call({
 MatchRule normalRule, MatchRule advancedRule, bool useAdvancedRule, List<String> advancedKeywords, String matchType, bool isMultiScene, bool useHonsenRule, bool useRenseikaiRule, bool useMoushiawaseRule, MatchRule renseikaiRule, MatchRule moushiawaseRule
});


$MatchRuleCopyWith<$Res> get normalRule;$MatchRuleCopyWith<$Res> get advancedRule;$MatchRuleCopyWith<$Res> get renseikaiRule;$MatchRuleCopyWith<$Res> get moushiawaseRule;

}
/// @nodoc
class _$CategoryRuleSetCopyWithImpl<$Res>
    implements $CategoryRuleSetCopyWith<$Res> {
  _$CategoryRuleSetCopyWithImpl(this._self, this._then);

  final CategoryRuleSet _self;
  final $Res Function(CategoryRuleSet) _then;

/// Create a copy of CategoryRuleSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? normalRule = null,Object? advancedRule = null,Object? useAdvancedRule = null,Object? advancedKeywords = null,Object? matchType = null,Object? isMultiScene = null,Object? useHonsenRule = null,Object? useRenseikaiRule = null,Object? useMoushiawaseRule = null,Object? renseikaiRule = null,Object? moushiawaseRule = null,}) {
  return _then(_self.copyWith(
normalRule: null == normalRule ? _self.normalRule : normalRule // ignore: cast_nullable_to_non_nullable
as MatchRule,advancedRule: null == advancedRule ? _self.advancedRule : advancedRule // ignore: cast_nullable_to_non_nullable
as MatchRule,useAdvancedRule: null == useAdvancedRule ? _self.useAdvancedRule : useAdvancedRule // ignore: cast_nullable_to_non_nullable
as bool,advancedKeywords: null == advancedKeywords ? _self.advancedKeywords : advancedKeywords // ignore: cast_nullable_to_non_nullable
as List<String>,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,isMultiScene: null == isMultiScene ? _self.isMultiScene : isMultiScene // ignore: cast_nullable_to_non_nullable
as bool,useHonsenRule: null == useHonsenRule ? _self.useHonsenRule : useHonsenRule // ignore: cast_nullable_to_non_nullable
as bool,useRenseikaiRule: null == useRenseikaiRule ? _self.useRenseikaiRule : useRenseikaiRule // ignore: cast_nullable_to_non_nullable
as bool,useMoushiawaseRule: null == useMoushiawaseRule ? _self.useMoushiawaseRule : useMoushiawaseRule // ignore: cast_nullable_to_non_nullable
as bool,renseikaiRule: null == renseikaiRule ? _self.renseikaiRule : renseikaiRule // ignore: cast_nullable_to_non_nullable
as MatchRule,moushiawaseRule: null == moushiawaseRule ? _self.moushiawaseRule : moushiawaseRule // ignore: cast_nullable_to_non_nullable
as MatchRule,
  ));
}
/// Create a copy of CategoryRuleSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchRuleCopyWith<$Res> get normalRule {
  
  return $MatchRuleCopyWith<$Res>(_self.normalRule, (value) {
    return _then(_self.copyWith(normalRule: value));
  });
}/// Create a copy of CategoryRuleSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchRuleCopyWith<$Res> get advancedRule {
  
  return $MatchRuleCopyWith<$Res>(_self.advancedRule, (value) {
    return _then(_self.copyWith(advancedRule: value));
  });
}/// Create a copy of CategoryRuleSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchRuleCopyWith<$Res> get renseikaiRule {
  
  return $MatchRuleCopyWith<$Res>(_self.renseikaiRule, (value) {
    return _then(_self.copyWith(renseikaiRule: value));
  });
}/// Create a copy of CategoryRuleSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchRuleCopyWith<$Res> get moushiawaseRule {
  
  return $MatchRuleCopyWith<$Res>(_self.moushiawaseRule, (value) {
    return _then(_self.copyWith(moushiawaseRule: value));
  });
}
}


/// Adds pattern-matching-related methods to [CategoryRuleSet].
extension CategoryRuleSetPatterns on CategoryRuleSet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryRuleSet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryRuleSet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryRuleSet value)  $default,){
final _that = this;
switch (_that) {
case _CategoryRuleSet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryRuleSet value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryRuleSet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MatchRule normalRule,  MatchRule advancedRule,  bool useAdvancedRule,  List<String> advancedKeywords,  String matchType,  bool isMultiScene,  bool useHonsenRule,  bool useRenseikaiRule,  bool useMoushiawaseRule,  MatchRule renseikaiRule,  MatchRule moushiawaseRule)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryRuleSet() when $default != null:
return $default(_that.normalRule,_that.advancedRule,_that.useAdvancedRule,_that.advancedKeywords,_that.matchType,_that.isMultiScene,_that.useHonsenRule,_that.useRenseikaiRule,_that.useMoushiawaseRule,_that.renseikaiRule,_that.moushiawaseRule);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MatchRule normalRule,  MatchRule advancedRule,  bool useAdvancedRule,  List<String> advancedKeywords,  String matchType,  bool isMultiScene,  bool useHonsenRule,  bool useRenseikaiRule,  bool useMoushiawaseRule,  MatchRule renseikaiRule,  MatchRule moushiawaseRule)  $default,) {final _that = this;
switch (_that) {
case _CategoryRuleSet():
return $default(_that.normalRule,_that.advancedRule,_that.useAdvancedRule,_that.advancedKeywords,_that.matchType,_that.isMultiScene,_that.useHonsenRule,_that.useRenseikaiRule,_that.useMoushiawaseRule,_that.renseikaiRule,_that.moushiawaseRule);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MatchRule normalRule,  MatchRule advancedRule,  bool useAdvancedRule,  List<String> advancedKeywords,  String matchType,  bool isMultiScene,  bool useHonsenRule,  bool useRenseikaiRule,  bool useMoushiawaseRule,  MatchRule renseikaiRule,  MatchRule moushiawaseRule)?  $default,) {final _that = this;
switch (_that) {
case _CategoryRuleSet() when $default != null:
return $default(_that.normalRule,_that.advancedRule,_that.useAdvancedRule,_that.advancedKeywords,_that.matchType,_that.isMultiScene,_that.useHonsenRule,_that.useRenseikaiRule,_that.useMoushiawaseRule,_that.renseikaiRule,_that.moushiawaseRule);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryRuleSet implements CategoryRuleSet {
  const _CategoryRuleSet({this.normalRule = const MatchRule(), this.advancedRule = const MatchRule(), this.useAdvancedRule = false, final  List<String> advancedKeywords = const ['準決勝', '準決', '決勝', 'final', '3位決定', '3決', 'ベスト4'], this.matchType = '個人戦', this.isMultiScene = false, this.useHonsenRule = true, this.useRenseikaiRule = true, this.useMoushiawaseRule = true, this.renseikaiRule = const MatchRule(matchTimeMinutes: 2, isRunningTime: true, hasHantei: true, enchoCount: 0, isEnchoUnlimited: false, isRenseikai: true, matchScene: 'renseikai'), this.moushiawaseRule = const MatchRule(matchTimeMinutes: 2, isRunningTime: true, hasHantei: true, enchoCount: 0, isEnchoUnlimited: false, isRenseikai: true, matchScene: 'moushiawase')}): _advancedKeywords = advancedKeywords;
  factory _CategoryRuleSet.fromJson(Map<String, dynamic> json) => _$CategoryRuleSetFromJson(json);

@override@JsonKey() final  MatchRule normalRule;
@override@JsonKey() final  MatchRule advancedRule;
@override@JsonKey() final  bool useAdvancedRule;
 final  List<String> _advancedKeywords;
@override@JsonKey() List<String> get advancedKeywords {
  if (_advancedKeywords is EqualUnmodifiableListView) return _advancedKeywords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_advancedKeywords);
}

@override@JsonKey() final  String matchType;
@override@JsonKey() final  bool isMultiScene;
@override@JsonKey() final  bool useHonsenRule;
@override@JsonKey() final  bool useRenseikaiRule;
@override@JsonKey() final  bool useMoushiawaseRule;
@override@JsonKey() final  MatchRule renseikaiRule;
@override@JsonKey() final  MatchRule moushiawaseRule;

/// Create a copy of CategoryRuleSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryRuleSetCopyWith<_CategoryRuleSet> get copyWith => __$CategoryRuleSetCopyWithImpl<_CategoryRuleSet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryRuleSetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryRuleSet&&(identical(other.normalRule, normalRule) || other.normalRule == normalRule)&&(identical(other.advancedRule, advancedRule) || other.advancedRule == advancedRule)&&(identical(other.useAdvancedRule, useAdvancedRule) || other.useAdvancedRule == useAdvancedRule)&&const DeepCollectionEquality().equals(other._advancedKeywords, _advancedKeywords)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.isMultiScene, isMultiScene) || other.isMultiScene == isMultiScene)&&(identical(other.useHonsenRule, useHonsenRule) || other.useHonsenRule == useHonsenRule)&&(identical(other.useRenseikaiRule, useRenseikaiRule) || other.useRenseikaiRule == useRenseikaiRule)&&(identical(other.useMoushiawaseRule, useMoushiawaseRule) || other.useMoushiawaseRule == useMoushiawaseRule)&&(identical(other.renseikaiRule, renseikaiRule) || other.renseikaiRule == renseikaiRule)&&(identical(other.moushiawaseRule, moushiawaseRule) || other.moushiawaseRule == moushiawaseRule));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,normalRule,advancedRule,useAdvancedRule,const DeepCollectionEquality().hash(_advancedKeywords),matchType,isMultiScene,useHonsenRule,useRenseikaiRule,useMoushiawaseRule,renseikaiRule,moushiawaseRule);

@override
String toString() {
  return 'CategoryRuleSet(normalRule: $normalRule, advancedRule: $advancedRule, useAdvancedRule: $useAdvancedRule, advancedKeywords: $advancedKeywords, matchType: $matchType, isMultiScene: $isMultiScene, useHonsenRule: $useHonsenRule, useRenseikaiRule: $useRenseikaiRule, useMoushiawaseRule: $useMoushiawaseRule, renseikaiRule: $renseikaiRule, moushiawaseRule: $moushiawaseRule)';
}


}

/// @nodoc
abstract mixin class _$CategoryRuleSetCopyWith<$Res> implements $CategoryRuleSetCopyWith<$Res> {
  factory _$CategoryRuleSetCopyWith(_CategoryRuleSet value, $Res Function(_CategoryRuleSet) _then) = __$CategoryRuleSetCopyWithImpl;
@override @useResult
$Res call({
 MatchRule normalRule, MatchRule advancedRule, bool useAdvancedRule, List<String> advancedKeywords, String matchType, bool isMultiScene, bool useHonsenRule, bool useRenseikaiRule, bool useMoushiawaseRule, MatchRule renseikaiRule, MatchRule moushiawaseRule
});


@override $MatchRuleCopyWith<$Res> get normalRule;@override $MatchRuleCopyWith<$Res> get advancedRule;@override $MatchRuleCopyWith<$Res> get renseikaiRule;@override $MatchRuleCopyWith<$Res> get moushiawaseRule;

}
/// @nodoc
class __$CategoryRuleSetCopyWithImpl<$Res>
    implements _$CategoryRuleSetCopyWith<$Res> {
  __$CategoryRuleSetCopyWithImpl(this._self, this._then);

  final _CategoryRuleSet _self;
  final $Res Function(_CategoryRuleSet) _then;

/// Create a copy of CategoryRuleSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? normalRule = null,Object? advancedRule = null,Object? useAdvancedRule = null,Object? advancedKeywords = null,Object? matchType = null,Object? isMultiScene = null,Object? useHonsenRule = null,Object? useRenseikaiRule = null,Object? useMoushiawaseRule = null,Object? renseikaiRule = null,Object? moushiawaseRule = null,}) {
  return _then(_CategoryRuleSet(
normalRule: null == normalRule ? _self.normalRule : normalRule // ignore: cast_nullable_to_non_nullable
as MatchRule,advancedRule: null == advancedRule ? _self.advancedRule : advancedRule // ignore: cast_nullable_to_non_nullable
as MatchRule,useAdvancedRule: null == useAdvancedRule ? _self.useAdvancedRule : useAdvancedRule // ignore: cast_nullable_to_non_nullable
as bool,advancedKeywords: null == advancedKeywords ? _self._advancedKeywords : advancedKeywords // ignore: cast_nullable_to_non_nullable
as List<String>,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,isMultiScene: null == isMultiScene ? _self.isMultiScene : isMultiScene // ignore: cast_nullable_to_non_nullable
as bool,useHonsenRule: null == useHonsenRule ? _self.useHonsenRule : useHonsenRule // ignore: cast_nullable_to_non_nullable
as bool,useRenseikaiRule: null == useRenseikaiRule ? _self.useRenseikaiRule : useRenseikaiRule // ignore: cast_nullable_to_non_nullable
as bool,useMoushiawaseRule: null == useMoushiawaseRule ? _self.useMoushiawaseRule : useMoushiawaseRule // ignore: cast_nullable_to_non_nullable
as bool,renseikaiRule: null == renseikaiRule ? _self.renseikaiRule : renseikaiRule // ignore: cast_nullable_to_non_nullable
as MatchRule,moushiawaseRule: null == moushiawaseRule ? _self.moushiawaseRule : moushiawaseRule // ignore: cast_nullable_to_non_nullable
as MatchRule,
  ));
}

/// Create a copy of CategoryRuleSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchRuleCopyWith<$Res> get normalRule {
  
  return $MatchRuleCopyWith<$Res>(_self.normalRule, (value) {
    return _then(_self.copyWith(normalRule: value));
  });
}/// Create a copy of CategoryRuleSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchRuleCopyWith<$Res> get advancedRule {
  
  return $MatchRuleCopyWith<$Res>(_self.advancedRule, (value) {
    return _then(_self.copyWith(advancedRule: value));
  });
}/// Create a copy of CategoryRuleSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchRuleCopyWith<$Res> get renseikaiRule {
  
  return $MatchRuleCopyWith<$Res>(_self.renseikaiRule, (value) {
    return _then(_self.copyWith(renseikaiRule: value));
  });
}/// Create a copy of CategoryRuleSet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchRuleCopyWith<$Res> get moushiawaseRule {
  
  return $MatchRuleCopyWith<$Res>(_self.moushiawaseRule, (value) {
    return _then(_self.copyWith(moushiawaseRule: value));
  });
}
}

// dart format on
