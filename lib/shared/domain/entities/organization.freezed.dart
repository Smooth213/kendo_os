// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Organization {

 String get id; String get name; List<String> get memberNames;
/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationCopyWith<Organization> get copyWith => _$OrganizationCopyWithImpl<Organization>(this as Organization, _$identity);

  /// Serializes this Organization to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Organization&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.memberNames, memberNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(memberNames));

@override
String toString() {
  return 'Organization(id: $id, name: $name, memberNames: $memberNames)';
}


}

/// @nodoc
abstract mixin class $OrganizationCopyWith<$Res>  {
  factory $OrganizationCopyWith(Organization value, $Res Function(Organization) _then) = _$OrganizationCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<String> memberNames
});




}
/// @nodoc
class _$OrganizationCopyWithImpl<$Res>
    implements $OrganizationCopyWith<$Res> {
  _$OrganizationCopyWithImpl(this._self, this._then);

  final Organization _self;
  final $Res Function(Organization) _then;

/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? memberNames = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberNames: null == memberNames ? _self.memberNames : memberNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Organization].
extension OrganizationPatterns on Organization {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Organization value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Organization() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Organization value)  $default,){
final _that = this;
switch (_that) {
case _Organization():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Organization value)?  $default,){
final _that = this;
switch (_that) {
case _Organization() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<String> memberNames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Organization() when $default != null:
return $default(_that.id,_that.name,_that.memberNames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<String> memberNames)  $default,) {final _that = this;
switch (_that) {
case _Organization():
return $default(_that.id,_that.name,_that.memberNames);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<String> memberNames)?  $default,) {final _that = this;
switch (_that) {
case _Organization() when $default != null:
return $default(_that.id,_that.name,_that.memberNames);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Organization implements Organization {
  const _Organization({required this.id, required this.name, final  List<String> memberNames = const []}): _memberNames = memberNames;
  factory _Organization.fromJson(Map<String, dynamic> json) => _$OrganizationFromJson(json);

@override final  String id;
@override final  String name;
 final  List<String> _memberNames;
@override@JsonKey() List<String> get memberNames {
  if (_memberNames is EqualUnmodifiableListView) return _memberNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberNames);
}


/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationCopyWith<_Organization> get copyWith => __$OrganizationCopyWithImpl<_Organization>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrganizationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Organization&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._memberNames, _memberNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_memberNames));

@override
String toString() {
  return 'Organization(id: $id, name: $name, memberNames: $memberNames)';
}


}

/// @nodoc
abstract mixin class _$OrganizationCopyWith<$Res> implements $OrganizationCopyWith<$Res> {
  factory _$OrganizationCopyWith(_Organization value, $Res Function(_Organization) _then) = __$OrganizationCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<String> memberNames
});




}
/// @nodoc
class __$OrganizationCopyWithImpl<$Res>
    implements _$OrganizationCopyWith<$Res> {
  __$OrganizationCopyWithImpl(this._self, this._then);

  final _Organization _self;
  final $Res Function(_Organization) _then;

/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? memberNames = null,}) {
  return _then(_Organization(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberNames: null == memberNames ? _self._memberNames : memberNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$TeamTemplate {

 String get id; String get name;// 例：「Aチーム」「中学男子部」
 List<String> get orderedMemberNames;
/// Create a copy of TeamTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamTemplateCopyWith<TeamTemplate> get copyWith => _$TeamTemplateCopyWithImpl<TeamTemplate>(this as TeamTemplate, _$identity);

  /// Serializes this TeamTemplate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.orderedMemberNames, orderedMemberNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(orderedMemberNames));

@override
String toString() {
  return 'TeamTemplate(id: $id, name: $name, orderedMemberNames: $orderedMemberNames)';
}


}

/// @nodoc
abstract mixin class $TeamTemplateCopyWith<$Res>  {
  factory $TeamTemplateCopyWith(TeamTemplate value, $Res Function(TeamTemplate) _then) = _$TeamTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<String> orderedMemberNames
});




}
/// @nodoc
class _$TeamTemplateCopyWithImpl<$Res>
    implements $TeamTemplateCopyWith<$Res> {
  _$TeamTemplateCopyWithImpl(this._self, this._then);

  final TeamTemplate _self;
  final $Res Function(TeamTemplate) _then;

/// Create a copy of TeamTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? orderedMemberNames = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,orderedMemberNames: null == orderedMemberNames ? _self.orderedMemberNames : orderedMemberNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamTemplate].
extension TeamTemplatePatterns on TeamTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamTemplate value)  $default,){
final _that = this;
switch (_that) {
case _TeamTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _TeamTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<String> orderedMemberNames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamTemplate() when $default != null:
return $default(_that.id,_that.name,_that.orderedMemberNames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<String> orderedMemberNames)  $default,) {final _that = this;
switch (_that) {
case _TeamTemplate():
return $default(_that.id,_that.name,_that.orderedMemberNames);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<String> orderedMemberNames)?  $default,) {final _that = this;
switch (_that) {
case _TeamTemplate() when $default != null:
return $default(_that.id,_that.name,_that.orderedMemberNames);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeamTemplate implements TeamTemplate {
  const _TeamTemplate({required this.id, required this.name, final  List<String> orderedMemberNames = const []}): _orderedMemberNames = orderedMemberNames;
  factory _TeamTemplate.fromJson(Map<String, dynamic> json) => _$TeamTemplateFromJson(json);

@override final  String id;
@override final  String name;
// 例：「Aチーム」「中学男子部」
 final  List<String> _orderedMemberNames;
// 例：「Aチーム」「中学男子部」
@override@JsonKey() List<String> get orderedMemberNames {
  if (_orderedMemberNames is EqualUnmodifiableListView) return _orderedMemberNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orderedMemberNames);
}


/// Create a copy of TeamTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamTemplateCopyWith<_TeamTemplate> get copyWith => __$TeamTemplateCopyWithImpl<_TeamTemplate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamTemplateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._orderedMemberNames, _orderedMemberNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_orderedMemberNames));

@override
String toString() {
  return 'TeamTemplate(id: $id, name: $name, orderedMemberNames: $orderedMemberNames)';
}


}

/// @nodoc
abstract mixin class _$TeamTemplateCopyWith<$Res> implements $TeamTemplateCopyWith<$Res> {
  factory _$TeamTemplateCopyWith(_TeamTemplate value, $Res Function(_TeamTemplate) _then) = __$TeamTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<String> orderedMemberNames
});




}
/// @nodoc
class __$TeamTemplateCopyWithImpl<$Res>
    implements _$TeamTemplateCopyWith<$Res> {
  __$TeamTemplateCopyWithImpl(this._self, this._then);

  final _TeamTemplate _self;
  final $Res Function(_TeamTemplate) _then;

/// Create a copy of TeamTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? orderedMemberNames = null,}) {
  return _then(_TeamTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,orderedMemberNames: null == orderedMemberNames ? _self._orderedMemberNames : orderedMemberNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
