// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_aggregate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MatchSnapshot {

 String get id;@TimestampConverter() DateTime get createdAt; String get reason; List<ScoreEvent> get events;
/// Create a copy of MatchSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchSnapshotCopyWith<MatchSnapshot> get copyWith => _$MatchSnapshotCopyWithImpl<MatchSnapshot>(this as MatchSnapshot, _$identity);

  /// Serializes this MatchSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchSnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.events, events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,reason,const DeepCollectionEquality().hash(events));

@override
String toString() {
  return 'MatchSnapshot(id: $id, createdAt: $createdAt, reason: $reason, events: $events)';
}


}

/// @nodoc
abstract mixin class $MatchSnapshotCopyWith<$Res>  {
  factory $MatchSnapshotCopyWith(MatchSnapshot value, $Res Function(MatchSnapshot) _then) = _$MatchSnapshotCopyWithImpl;
@useResult
$Res call({
 String id,@TimestampConverter() DateTime createdAt, String reason, List<ScoreEvent> events
});




}
/// @nodoc
class _$MatchSnapshotCopyWithImpl<$Res>
    implements $MatchSnapshotCopyWith<$Res> {
  _$MatchSnapshotCopyWithImpl(this._self, this._then);

  final MatchSnapshot _self;
  final $Res Function(MatchSnapshot) _then;

/// Create a copy of MatchSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,Object? reason = null,Object? events = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<ScoreEvent>,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchSnapshot].
extension MatchSnapshotPatterns on MatchSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _MatchSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _MatchSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @TimestampConverter()  DateTime createdAt,  String reason,  List<ScoreEvent> events)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchSnapshot() when $default != null:
return $default(_that.id,_that.createdAt,_that.reason,_that.events);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @TimestampConverter()  DateTime createdAt,  String reason,  List<ScoreEvent> events)  $default,) {final _that = this;
switch (_that) {
case _MatchSnapshot():
return $default(_that.id,_that.createdAt,_that.reason,_that.events);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @TimestampConverter()  DateTime createdAt,  String reason,  List<ScoreEvent> events)?  $default,) {final _that = this;
switch (_that) {
case _MatchSnapshot() when $default != null:
return $default(_that.id,_that.createdAt,_that.reason,_that.events);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchSnapshot implements MatchSnapshot {
  const _MatchSnapshot({required this.id, @TimestampConverter() required this.createdAt, required this.reason, final  List<ScoreEvent> events = const []}): _events = events;
  factory _MatchSnapshot.fromJson(Map<String, dynamic> json) => _$MatchSnapshotFromJson(json);

@override final  String id;
@override@TimestampConverter() final  DateTime createdAt;
@override final  String reason;
 final  List<ScoreEvent> _events;
@override@JsonKey() List<ScoreEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}


/// Create a copy of MatchSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchSnapshotCopyWith<_MatchSnapshot> get copyWith => __$MatchSnapshotCopyWithImpl<_MatchSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchSnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other._events, _events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,reason,const DeepCollectionEquality().hash(_events));

@override
String toString() {
  return 'MatchSnapshot(id: $id, createdAt: $createdAt, reason: $reason, events: $events)';
}


}

/// @nodoc
abstract mixin class _$MatchSnapshotCopyWith<$Res> implements $MatchSnapshotCopyWith<$Res> {
  factory _$MatchSnapshotCopyWith(_MatchSnapshot value, $Res Function(_MatchSnapshot) _then) = __$MatchSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String id,@TimestampConverter() DateTime createdAt, String reason, List<ScoreEvent> events
});




}
/// @nodoc
class __$MatchSnapshotCopyWithImpl<$Res>
    implements _$MatchSnapshotCopyWith<$Res> {
  __$MatchSnapshotCopyWithImpl(this._self, this._then);

  final _MatchSnapshot _self;
  final $Res Function(_MatchSnapshot) _then;

/// Create a copy of MatchSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = null,Object? reason = null,Object? events = null,}) {
  return _then(_MatchSnapshot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<ScoreEvent>,
  ));
}


}


/// @nodoc
mixin _$MatchAggregate {

 String get id; MatchRule get rule; List<ScoreEvent> get events; List<MatchSnapshot> get snapshots;// 試合の進行状態（永続化が必要なドメインの状態）
 String get status; int get redScore; int get whiteScore; int get remainingSeconds; bool get timerIsRunning;
/// Create a copy of MatchAggregate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchAggregateCopyWith<MatchAggregate> get copyWith => _$MatchAggregateCopyWithImpl<MatchAggregate>(this as MatchAggregate, _$identity);

  /// Serializes this MatchAggregate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchAggregate&&(identical(other.id, id) || other.id == id)&&(identical(other.rule, rule) || other.rule == rule)&&const DeepCollectionEquality().equals(other.events, events)&&const DeepCollectionEquality().equals(other.snapshots, snapshots)&&(identical(other.status, status) || other.status == status)&&(identical(other.redScore, redScore) || other.redScore == redScore)&&(identical(other.whiteScore, whiteScore) || other.whiteScore == whiteScore)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.timerIsRunning, timerIsRunning) || other.timerIsRunning == timerIsRunning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,rule,const DeepCollectionEquality().hash(events),const DeepCollectionEquality().hash(snapshots),status,redScore,whiteScore,remainingSeconds,timerIsRunning);

@override
String toString() {
  return 'MatchAggregate(id: $id, rule: $rule, events: $events, snapshots: $snapshots, status: $status, redScore: $redScore, whiteScore: $whiteScore, remainingSeconds: $remainingSeconds, timerIsRunning: $timerIsRunning)';
}


}

/// @nodoc
abstract mixin class $MatchAggregateCopyWith<$Res>  {
  factory $MatchAggregateCopyWith(MatchAggregate value, $Res Function(MatchAggregate) _then) = _$MatchAggregateCopyWithImpl;
@useResult
$Res call({
 String id, MatchRule rule, List<ScoreEvent> events, List<MatchSnapshot> snapshots, String status, int redScore, int whiteScore, int remainingSeconds, bool timerIsRunning
});


$MatchRuleCopyWith<$Res> get rule;

}
/// @nodoc
class _$MatchAggregateCopyWithImpl<$Res>
    implements $MatchAggregateCopyWith<$Res> {
  _$MatchAggregateCopyWithImpl(this._self, this._then);

  final MatchAggregate _self;
  final $Res Function(MatchAggregate) _then;

/// Create a copy of MatchAggregate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rule = null,Object? events = null,Object? snapshots = null,Object? status = null,Object? redScore = null,Object? whiteScore = null,Object? remainingSeconds = null,Object? timerIsRunning = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as MatchRule,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<ScoreEvent>,snapshots: null == snapshots ? _self.snapshots : snapshots // ignore: cast_nullable_to_non_nullable
as List<MatchSnapshot>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,redScore: null == redScore ? _self.redScore : redScore // ignore: cast_nullable_to_non_nullable
as int,whiteScore: null == whiteScore ? _self.whiteScore : whiteScore // ignore: cast_nullable_to_non_nullable
as int,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,timerIsRunning: null == timerIsRunning ? _self.timerIsRunning : timerIsRunning // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of MatchAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchRuleCopyWith<$Res> get rule {
  
  return $MatchRuleCopyWith<$Res>(_self.rule, (value) {
    return _then(_self.copyWith(rule: value));
  });
}
}


/// Adds pattern-matching-related methods to [MatchAggregate].
extension MatchAggregatePatterns on MatchAggregate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchAggregate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchAggregate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchAggregate value)  $default,){
final _that = this;
switch (_that) {
case _MatchAggregate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchAggregate value)?  $default,){
final _that = this;
switch (_that) {
case _MatchAggregate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MatchRule rule,  List<ScoreEvent> events,  List<MatchSnapshot> snapshots,  String status,  int redScore,  int whiteScore,  int remainingSeconds,  bool timerIsRunning)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchAggregate() when $default != null:
return $default(_that.id,_that.rule,_that.events,_that.snapshots,_that.status,_that.redScore,_that.whiteScore,_that.remainingSeconds,_that.timerIsRunning);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MatchRule rule,  List<ScoreEvent> events,  List<MatchSnapshot> snapshots,  String status,  int redScore,  int whiteScore,  int remainingSeconds,  bool timerIsRunning)  $default,) {final _that = this;
switch (_that) {
case _MatchAggregate():
return $default(_that.id,_that.rule,_that.events,_that.snapshots,_that.status,_that.redScore,_that.whiteScore,_that.remainingSeconds,_that.timerIsRunning);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MatchRule rule,  List<ScoreEvent> events,  List<MatchSnapshot> snapshots,  String status,  int redScore,  int whiteScore,  int remainingSeconds,  bool timerIsRunning)?  $default,) {final _that = this;
switch (_that) {
case _MatchAggregate() when $default != null:
return $default(_that.id,_that.rule,_that.events,_that.snapshots,_that.status,_that.redScore,_that.whiteScore,_that.remainingSeconds,_that.timerIsRunning);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchAggregate extends MatchAggregate {
  const _MatchAggregate({required this.id, required this.rule, final  List<ScoreEvent> events = const [], final  List<MatchSnapshot> snapshots = const [], this.status = 'waiting', this.redScore = 0, this.whiteScore = 0, this.remainingSeconds = 180, this.timerIsRunning = false}): _events = events,_snapshots = snapshots,super._();
  factory _MatchAggregate.fromJson(Map<String, dynamic> json) => _$MatchAggregateFromJson(json);

@override final  String id;
@override final  MatchRule rule;
 final  List<ScoreEvent> _events;
@override@JsonKey() List<ScoreEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

 final  List<MatchSnapshot> _snapshots;
@override@JsonKey() List<MatchSnapshot> get snapshots {
  if (_snapshots is EqualUnmodifiableListView) return _snapshots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_snapshots);
}

// 試合の進行状態（永続化が必要なドメインの状態）
@override@JsonKey() final  String status;
@override@JsonKey() final  int redScore;
@override@JsonKey() final  int whiteScore;
@override@JsonKey() final  int remainingSeconds;
@override@JsonKey() final  bool timerIsRunning;

/// Create a copy of MatchAggregate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchAggregateCopyWith<_MatchAggregate> get copyWith => __$MatchAggregateCopyWithImpl<_MatchAggregate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchAggregateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchAggregate&&(identical(other.id, id) || other.id == id)&&(identical(other.rule, rule) || other.rule == rule)&&const DeepCollectionEquality().equals(other._events, _events)&&const DeepCollectionEquality().equals(other._snapshots, _snapshots)&&(identical(other.status, status) || other.status == status)&&(identical(other.redScore, redScore) || other.redScore == redScore)&&(identical(other.whiteScore, whiteScore) || other.whiteScore == whiteScore)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.timerIsRunning, timerIsRunning) || other.timerIsRunning == timerIsRunning));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,rule,const DeepCollectionEquality().hash(_events),const DeepCollectionEquality().hash(_snapshots),status,redScore,whiteScore,remainingSeconds,timerIsRunning);

@override
String toString() {
  return 'MatchAggregate(id: $id, rule: $rule, events: $events, snapshots: $snapshots, status: $status, redScore: $redScore, whiteScore: $whiteScore, remainingSeconds: $remainingSeconds, timerIsRunning: $timerIsRunning)';
}


}

/// @nodoc
abstract mixin class _$MatchAggregateCopyWith<$Res> implements $MatchAggregateCopyWith<$Res> {
  factory _$MatchAggregateCopyWith(_MatchAggregate value, $Res Function(_MatchAggregate) _then) = __$MatchAggregateCopyWithImpl;
@override @useResult
$Res call({
 String id, MatchRule rule, List<ScoreEvent> events, List<MatchSnapshot> snapshots, String status, int redScore, int whiteScore, int remainingSeconds, bool timerIsRunning
});


@override $MatchRuleCopyWith<$Res> get rule;

}
/// @nodoc
class __$MatchAggregateCopyWithImpl<$Res>
    implements _$MatchAggregateCopyWith<$Res> {
  __$MatchAggregateCopyWithImpl(this._self, this._then);

  final _MatchAggregate _self;
  final $Res Function(_MatchAggregate) _then;

/// Create a copy of MatchAggregate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rule = null,Object? events = null,Object? snapshots = null,Object? status = null,Object? redScore = null,Object? whiteScore = null,Object? remainingSeconds = null,Object? timerIsRunning = null,}) {
  return _then(_MatchAggregate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as MatchRule,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<ScoreEvent>,snapshots: null == snapshots ? _self._snapshots : snapshots // ignore: cast_nullable_to_non_nullable
as List<MatchSnapshot>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,redScore: null == redScore ? _self.redScore : redScore // ignore: cast_nullable_to_non_nullable
as int,whiteScore: null == whiteScore ? _self.whiteScore : whiteScore // ignore: cast_nullable_to_non_nullable
as int,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,timerIsRunning: null == timerIsRunning ? _self.timerIsRunning : timerIsRunning // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of MatchAggregate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MatchRuleCopyWith<$Res> get rule {
  
  return $MatchRuleCopyWith<$Res>(_self.rule, (value) {
    return _then(_self.copyWith(rule: value));
  });
}
}

// dart format on
