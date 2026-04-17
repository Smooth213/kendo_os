// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrganizationModel {

 String get id; String get name; List<String> get memberNames;
/// Create a copy of OrganizationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationModelCopyWith<OrganizationModel> get copyWith => _$OrganizationModelCopyWithImpl<OrganizationModel>(this as OrganizationModel, _$identity);

  /// Serializes this OrganizationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.memberNames, memberNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(memberNames));

@override
String toString() {
  return 'OrganizationModel(id: $id, name: $name, memberNames: $memberNames)';
}


}

/// @nodoc
abstract mixin class $OrganizationModelCopyWith<$Res>  {
  factory $OrganizationModelCopyWith(OrganizationModel value, $Res Function(OrganizationModel) _then) = _$OrganizationModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<String> memberNames
});




}
/// @nodoc
class _$OrganizationModelCopyWithImpl<$Res>
    implements $OrganizationModelCopyWith<$Res> {
  _$OrganizationModelCopyWithImpl(this._self, this._then);

  final OrganizationModel _self;
  final $Res Function(OrganizationModel) _then;

/// Create a copy of OrganizationModel
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


/// Adds pattern-matching-related methods to [OrganizationModel].
extension OrganizationModelPatterns on OrganizationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationModel value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationModel value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationModel() when $default != null:
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
case _OrganizationModel() when $default != null:
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
case _OrganizationModel():
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
case _OrganizationModel() when $default != null:
return $default(_that.id,_that.name,_that.memberNames);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrganizationModel implements OrganizationModel {
  const _OrganizationModel({required this.id, required this.name, final  List<String> memberNames = const []}): _memberNames = memberNames;
  factory _OrganizationModel.fromJson(Map<String, dynamic> json) => _$OrganizationModelFromJson(json);

@override final  String id;
@override final  String name;
 final  List<String> _memberNames;
@override@JsonKey() List<String> get memberNames {
  if (_memberNames is EqualUnmodifiableListView) return _memberNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberNames);
}


/// Create a copy of OrganizationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationModelCopyWith<_OrganizationModel> get copyWith => __$OrganizationModelCopyWithImpl<_OrganizationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrganizationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._memberNames, _memberNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_memberNames));

@override
String toString() {
  return 'OrganizationModel(id: $id, name: $name, memberNames: $memberNames)';
}


}

/// @nodoc
abstract mixin class _$OrganizationModelCopyWith<$Res> implements $OrganizationModelCopyWith<$Res> {
  factory _$OrganizationModelCopyWith(_OrganizationModel value, $Res Function(_OrganizationModel) _then) = __$OrganizationModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<String> memberNames
});




}
/// @nodoc
class __$OrganizationModelCopyWithImpl<$Res>
    implements _$OrganizationModelCopyWith<$Res> {
  __$OrganizationModelCopyWithImpl(this._self, this._then);

  final _OrganizationModel _self;
  final $Res Function(_OrganizationModel) _then;

/// Create a copy of OrganizationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? memberNames = null,}) {
  return _then(_OrganizationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,memberNames: null == memberNames ? _self._memberNames : memberNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
