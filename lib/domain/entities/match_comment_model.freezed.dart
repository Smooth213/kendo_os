// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_comment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchCommentModel implements DiagnosticableTreeMixin {

 String get id; String? get tournamentId; String? get category; String? get groupName; String get text;@DoubleConverter() double get order; SyncState get syncState;@SafeTimestampConverter() DateTime? get lastUpdatedAt;
/// Create a copy of MatchCommentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchCommentModelCopyWith<MatchCommentModel> get copyWith => _$MatchCommentModelCopyWithImpl<MatchCommentModel>(this as MatchCommentModel, _$identity);

  /// Serializes this MatchCommentModel to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MatchCommentModel'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('tournamentId', tournamentId))..add(DiagnosticsProperty('category', category))..add(DiagnosticsProperty('groupName', groupName))..add(DiagnosticsProperty('text', text))..add(DiagnosticsProperty('order', order))..add(DiagnosticsProperty('syncState', syncState))..add(DiagnosticsProperty('lastUpdatedAt', lastUpdatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchCommentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.category, category) || other.category == category)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.text, text) || other.text == text)&&(identical(other.order, order) || other.order == order)&&(identical(other.syncState, syncState) || other.syncState == syncState)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tournamentId,category,groupName,text,order,syncState,lastUpdatedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MatchCommentModel(id: $id, tournamentId: $tournamentId, category: $category, groupName: $groupName, text: $text, order: $order, syncState: $syncState, lastUpdatedAt: $lastUpdatedAt)';
}


}

/// @nodoc
abstract mixin class $MatchCommentModelCopyWith<$Res>  {
  factory $MatchCommentModelCopyWith(MatchCommentModel value, $Res Function(MatchCommentModel) _then) = _$MatchCommentModelCopyWithImpl;
@useResult
$Res call({
 String id, String? tournamentId, String? category, String? groupName, String text,@DoubleConverter() double order, SyncState syncState,@SafeTimestampConverter() DateTime? lastUpdatedAt
});




}
/// @nodoc
class _$MatchCommentModelCopyWithImpl<$Res>
    implements $MatchCommentModelCopyWith<$Res> {
  _$MatchCommentModelCopyWithImpl(this._self, this._then);

  final MatchCommentModel _self;
  final $Res Function(MatchCommentModel) _then;

/// Create a copy of MatchCommentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tournamentId = freezed,Object? category = freezed,Object? groupName = freezed,Object? text = null,Object? order = null,Object? syncState = null,Object? lastUpdatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tournamentId: freezed == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as double,syncState: null == syncState ? _self.syncState : syncState // ignore: cast_nullable_to_non_nullable
as SyncState,lastUpdatedAt: freezed == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchCommentModel].
extension MatchCommentModelPatterns on MatchCommentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchCommentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchCommentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchCommentModel value)  $default,){
final _that = this;
switch (_that) {
case _MatchCommentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchCommentModel value)?  $default,){
final _that = this;
switch (_that) {
case _MatchCommentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? tournamentId,  String? category,  String? groupName,  String text, @DoubleConverter()  double order,  SyncState syncState, @SafeTimestampConverter()  DateTime? lastUpdatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchCommentModel() when $default != null:
return $default(_that.id,_that.tournamentId,_that.category,_that.groupName,_that.text,_that.order,_that.syncState,_that.lastUpdatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? tournamentId,  String? category,  String? groupName,  String text, @DoubleConverter()  double order,  SyncState syncState, @SafeTimestampConverter()  DateTime? lastUpdatedAt)  $default,) {final _that = this;
switch (_that) {
case _MatchCommentModel():
return $default(_that.id,_that.tournamentId,_that.category,_that.groupName,_that.text,_that.order,_that.syncState,_that.lastUpdatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? tournamentId,  String? category,  String? groupName,  String text, @DoubleConverter()  double order,  SyncState syncState, @SafeTimestampConverter()  DateTime? lastUpdatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MatchCommentModel() when $default != null:
return $default(_that.id,_that.tournamentId,_that.category,_that.groupName,_that.text,_that.order,_that.syncState,_that.lastUpdatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchCommentModel extends MatchCommentModel with DiagnosticableTreeMixin {
  const _MatchCommentModel({required this.id, this.tournamentId, this.category, this.groupName, required this.text, @DoubleConverter() this.order = 0.0, this.syncState = SyncState.synced, @SafeTimestampConverter() this.lastUpdatedAt}): super._();
  factory _MatchCommentModel.fromJson(Map<String, dynamic> json) => _$MatchCommentModelFromJson(json);

@override final  String id;
@override final  String? tournamentId;
@override final  String? category;
@override final  String? groupName;
@override final  String text;
@override@JsonKey()@DoubleConverter() final  double order;
@override@JsonKey() final  SyncState syncState;
@override@SafeTimestampConverter() final  DateTime? lastUpdatedAt;

/// Create a copy of MatchCommentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchCommentModelCopyWith<_MatchCommentModel> get copyWith => __$MatchCommentModelCopyWithImpl<_MatchCommentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchCommentModelToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MatchCommentModel'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('tournamentId', tournamentId))..add(DiagnosticsProperty('category', category))..add(DiagnosticsProperty('groupName', groupName))..add(DiagnosticsProperty('text', text))..add(DiagnosticsProperty('order', order))..add(DiagnosticsProperty('syncState', syncState))..add(DiagnosticsProperty('lastUpdatedAt', lastUpdatedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchCommentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.category, category) || other.category == category)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.text, text) || other.text == text)&&(identical(other.order, order) || other.order == order)&&(identical(other.syncState, syncState) || other.syncState == syncState)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tournamentId,category,groupName,text,order,syncState,lastUpdatedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MatchCommentModel(id: $id, tournamentId: $tournamentId, category: $category, groupName: $groupName, text: $text, order: $order, syncState: $syncState, lastUpdatedAt: $lastUpdatedAt)';
}


}

/// @nodoc
abstract mixin class _$MatchCommentModelCopyWith<$Res> implements $MatchCommentModelCopyWith<$Res> {
  factory _$MatchCommentModelCopyWith(_MatchCommentModel value, $Res Function(_MatchCommentModel) _then) = __$MatchCommentModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String? tournamentId, String? category, String? groupName, String text,@DoubleConverter() double order, SyncState syncState,@SafeTimestampConverter() DateTime? lastUpdatedAt
});




}
/// @nodoc
class __$MatchCommentModelCopyWithImpl<$Res>
    implements _$MatchCommentModelCopyWith<$Res> {
  __$MatchCommentModelCopyWithImpl(this._self, this._then);

  final _MatchCommentModel _self;
  final $Res Function(_MatchCommentModel) _then;

/// Create a copy of MatchCommentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tournamentId = freezed,Object? category = freezed,Object? groupName = freezed,Object? text = null,Object? order = null,Object? syncState = null,Object? lastUpdatedAt = freezed,}) {
  return _then(_MatchCommentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tournamentId: freezed == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as double,syncState: null == syncState ? _self.syncState : syncState // ignore: cast_nullable_to_non_nullable
as SyncState,lastUpdatedAt: freezed == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
