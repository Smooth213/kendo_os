// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timeline_projection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TimelineProjection {

 String get tournamentId; List<TimelineItem> get items; DateTime get lastUpdatedAt;
/// Create a copy of TimelineProjection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimelineProjectionCopyWith<TimelineProjection> get copyWith => _$TimelineProjectionCopyWithImpl<TimelineProjection>(this as TimelineProjection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimelineProjection&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,tournamentId,const DeepCollectionEquality().hash(items),lastUpdatedAt);

@override
String toString() {
  return 'TimelineProjection(tournamentId: $tournamentId, items: $items, lastUpdatedAt: $lastUpdatedAt)';
}


}

/// @nodoc
abstract mixin class $TimelineProjectionCopyWith<$Res>  {
  factory $TimelineProjectionCopyWith(TimelineProjection value, $Res Function(TimelineProjection) _then) = _$TimelineProjectionCopyWithImpl;
@useResult
$Res call({
 String tournamentId, List<TimelineItem> items, DateTime lastUpdatedAt
});




}
/// @nodoc
class _$TimelineProjectionCopyWithImpl<$Res>
    implements $TimelineProjectionCopyWith<$Res> {
  _$TimelineProjectionCopyWithImpl(this._self, this._then);

  final TimelineProjection _self;
  final $Res Function(TimelineProjection) _then;

/// Create a copy of TimelineProjection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tournamentId = null,Object? items = null,Object? lastUpdatedAt = null,}) {
  return _then(_self.copyWith(
tournamentId: null == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TimelineItem>,lastUpdatedAt: null == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TimelineProjection].
extension TimelineProjectionPatterns on TimelineProjection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimelineProjection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimelineProjection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimelineProjection value)  $default,){
final _that = this;
switch (_that) {
case _TimelineProjection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimelineProjection value)?  $default,){
final _that = this;
switch (_that) {
case _TimelineProjection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tournamentId,  List<TimelineItem> items,  DateTime lastUpdatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimelineProjection() when $default != null:
return $default(_that.tournamentId,_that.items,_that.lastUpdatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tournamentId,  List<TimelineItem> items,  DateTime lastUpdatedAt)  $default,) {final _that = this;
switch (_that) {
case _TimelineProjection():
return $default(_that.tournamentId,_that.items,_that.lastUpdatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tournamentId,  List<TimelineItem> items,  DateTime lastUpdatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TimelineProjection() when $default != null:
return $default(_that.tournamentId,_that.items,_that.lastUpdatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _TimelineProjection extends TimelineProjection {
  const _TimelineProjection({required this.tournamentId, final  List<TimelineItem> items = const [], required this.lastUpdatedAt}): _items = items,super._();
  

@override final  String tournamentId;
 final  List<TimelineItem> _items;
@override@JsonKey() List<TimelineItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  DateTime lastUpdatedAt;

/// Create a copy of TimelineProjection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimelineProjectionCopyWith<_TimelineProjection> get copyWith => __$TimelineProjectionCopyWithImpl<_TimelineProjection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimelineProjection&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,tournamentId,const DeepCollectionEquality().hash(_items),lastUpdatedAt);

@override
String toString() {
  return 'TimelineProjection(tournamentId: $tournamentId, items: $items, lastUpdatedAt: $lastUpdatedAt)';
}


}

/// @nodoc
abstract mixin class _$TimelineProjectionCopyWith<$Res> implements $TimelineProjectionCopyWith<$Res> {
  factory _$TimelineProjectionCopyWith(_TimelineProjection value, $Res Function(_TimelineProjection) _then) = __$TimelineProjectionCopyWithImpl;
@override @useResult
$Res call({
 String tournamentId, List<TimelineItem> items, DateTime lastUpdatedAt
});




}
/// @nodoc
class __$TimelineProjectionCopyWithImpl<$Res>
    implements _$TimelineProjectionCopyWith<$Res> {
  __$TimelineProjectionCopyWithImpl(this._self, this._then);

  final _TimelineProjection _self;
  final $Res Function(_TimelineProjection) _then;

/// Create a copy of TimelineProjection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tournamentId = null,Object? items = null,Object? lastUpdatedAt = null,}) {
  return _then(_TimelineProjection(
tournamentId: null == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TimelineItem>,lastUpdatedAt: null == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
