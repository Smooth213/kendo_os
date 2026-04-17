// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tournament_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TournamentModel {

 String get id; String get name;@TimestampConverter() DateTime get date;// ★ これで日付エラーが永遠に起きなくなる！
 String get venue; List<String> get categories; String get status;// ★ エラーログにあったstatusを維持
 String get notes;
/// Create a copy of TournamentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TournamentModelCopyWith<TournamentModel> get copyWith => _$TournamentModelCopyWithImpl<TournamentModel>(this as TournamentModel, _$identity);

  /// Serializes this TournamentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TournamentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.date, date) || other.date == date)&&(identical(other.venue, venue) || other.venue == venue)&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,date,venue,const DeepCollectionEquality().hash(categories),status,notes);

@override
String toString() {
  return 'TournamentModel(id: $id, name: $name, date: $date, venue: $venue, categories: $categories, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $TournamentModelCopyWith<$Res>  {
  factory $TournamentModelCopyWith(TournamentModel value, $Res Function(TournamentModel) _then) = _$TournamentModelCopyWithImpl;
@useResult
$Res call({
 String id, String name,@TimestampConverter() DateTime date, String venue, List<String> categories, String status, String notes
});




}
/// @nodoc
class _$TournamentModelCopyWithImpl<$Res>
    implements $TournamentModelCopyWith<$Res> {
  _$TournamentModelCopyWithImpl(this._self, this._then);

  final TournamentModel _self;
  final $Res Function(TournamentModel) _then;

/// Create a copy of TournamentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? date = null,Object? venue = null,Object? categories = null,Object? status = null,Object? notes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,venue: null == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TournamentModel].
extension TournamentModelPatterns on TournamentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TournamentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TournamentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TournamentModel value)  $default,){
final _that = this;
switch (_that) {
case _TournamentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TournamentModel value)?  $default,){
final _that = this;
switch (_that) {
case _TournamentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @TimestampConverter()  DateTime date,  String venue,  List<String> categories,  String status,  String notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TournamentModel() when $default != null:
return $default(_that.id,_that.name,_that.date,_that.venue,_that.categories,_that.status,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @TimestampConverter()  DateTime date,  String venue,  List<String> categories,  String status,  String notes)  $default,) {final _that = this;
switch (_that) {
case _TournamentModel():
return $default(_that.id,_that.name,_that.date,_that.venue,_that.categories,_that.status,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @TimestampConverter()  DateTime date,  String venue,  List<String> categories,  String status,  String notes)?  $default,) {final _that = this;
switch (_that) {
case _TournamentModel() when $default != null:
return $default(_that.id,_that.name,_that.date,_that.venue,_that.categories,_that.status,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TournamentModel implements TournamentModel {
  const _TournamentModel({required this.id, required this.name, @TimestampConverter() required this.date, required this.venue, final  List<String> categories = const [], this.status = 'active', this.notes = ''}): _categories = categories;
  factory _TournamentModel.fromJson(Map<String, dynamic> json) => _$TournamentModelFromJson(json);

@override final  String id;
@override final  String name;
@override@TimestampConverter() final  DateTime date;
// ★ これで日付エラーが永遠に起きなくなる！
@override final  String venue;
 final  List<String> _categories;
@override@JsonKey() List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

@override@JsonKey() final  String status;
// ★ エラーログにあったstatusを維持
@override@JsonKey() final  String notes;

/// Create a copy of TournamentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TournamentModelCopyWith<_TournamentModel> get copyWith => __$TournamentModelCopyWithImpl<_TournamentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TournamentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TournamentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.date, date) || other.date == date)&&(identical(other.venue, venue) || other.venue == venue)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,date,venue,const DeepCollectionEquality().hash(_categories),status,notes);

@override
String toString() {
  return 'TournamentModel(id: $id, name: $name, date: $date, venue: $venue, categories: $categories, status: $status, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$TournamentModelCopyWith<$Res> implements $TournamentModelCopyWith<$Res> {
  factory _$TournamentModelCopyWith(_TournamentModel value, $Res Function(_TournamentModel) _then) = __$TournamentModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@TimestampConverter() DateTime date, String venue, List<String> categories, String status, String notes
});




}
/// @nodoc
class __$TournamentModelCopyWithImpl<$Res>
    implements _$TournamentModelCopyWith<$Res> {
  __$TournamentModelCopyWithImpl(this._self, this._then);

  final _TournamentModel _self;
  final $Res Function(_TournamentModel) _then;

/// Create a copy of TournamentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? date = null,Object? venue = null,Object? categories = null,Object? status = null,Object? notes = null,}) {
  return _then(_TournamentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,venue: null == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
