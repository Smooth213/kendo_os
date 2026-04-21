// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SettingsModel {

// 【操作・安全設定】
// ★ アプリの初期状態を「大会・錬成会」プリセットに完全統一
 String get confirmBehavior; bool get isLocked; bool get showConfirmDialog;// ★ 変更：初期値をOFF（ダイアログなし）に統一
// 【フィードバック】
 bool get haptic; bool get strikeVib; bool get sound;// ★ 錬成会モードに合わせて初期値はオフ
// 【システム・表示】
 bool get sleepPrevent;// スリープ(画面消灯)防止
 bool get leftHanded;// 左利きモード（赤白反転）
 String get themeMode;// ★ ダークモード対応 ('system', 'light', 'dark')
// 【セキュリティ・権限】 (Phase 8)
 int get securityLevel;// ★ Phase 8: 1(自由), 2(標準), 3(厳格)
 String? get adminPasscode;
/// Create a copy of SettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsModelCopyWith<SettingsModel> get copyWith => _$SettingsModelCopyWithImpl<SettingsModel>(this as SettingsModel, _$identity);

  /// Serializes this SettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsModel&&(identical(other.confirmBehavior, confirmBehavior) || other.confirmBehavior == confirmBehavior)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.showConfirmDialog, showConfirmDialog) || other.showConfirmDialog == showConfirmDialog)&&(identical(other.haptic, haptic) || other.haptic == haptic)&&(identical(other.strikeVib, strikeVib) || other.strikeVib == strikeVib)&&(identical(other.sound, sound) || other.sound == sound)&&(identical(other.sleepPrevent, sleepPrevent) || other.sleepPrevent == sleepPrevent)&&(identical(other.leftHanded, leftHanded) || other.leftHanded == leftHanded)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.securityLevel, securityLevel) || other.securityLevel == securityLevel)&&(identical(other.adminPasscode, adminPasscode) || other.adminPasscode == adminPasscode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,confirmBehavior,isLocked,showConfirmDialog,haptic,strikeVib,sound,sleepPrevent,leftHanded,themeMode,securityLevel,adminPasscode);

@override
String toString() {
  return 'SettingsModel(confirmBehavior: $confirmBehavior, isLocked: $isLocked, showConfirmDialog: $showConfirmDialog, haptic: $haptic, strikeVib: $strikeVib, sound: $sound, sleepPrevent: $sleepPrevent, leftHanded: $leftHanded, themeMode: $themeMode, securityLevel: $securityLevel, adminPasscode: $adminPasscode)';
}


}

/// @nodoc
abstract mixin class $SettingsModelCopyWith<$Res>  {
  factory $SettingsModelCopyWith(SettingsModel value, $Res Function(SettingsModel) _then) = _$SettingsModelCopyWithImpl;
@useResult
$Res call({
 String confirmBehavior, bool isLocked, bool showConfirmDialog, bool haptic, bool strikeVib, bool sound, bool sleepPrevent, bool leftHanded, String themeMode, int securityLevel, String? adminPasscode
});




}
/// @nodoc
class _$SettingsModelCopyWithImpl<$Res>
    implements $SettingsModelCopyWith<$Res> {
  _$SettingsModelCopyWithImpl(this._self, this._then);

  final SettingsModel _self;
  final $Res Function(SettingsModel) _then;

/// Create a copy of SettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? confirmBehavior = null,Object? isLocked = null,Object? showConfirmDialog = null,Object? haptic = null,Object? strikeVib = null,Object? sound = null,Object? sleepPrevent = null,Object? leftHanded = null,Object? themeMode = null,Object? securityLevel = null,Object? adminPasscode = freezed,}) {
  return _then(_self.copyWith(
confirmBehavior: null == confirmBehavior ? _self.confirmBehavior : confirmBehavior // ignore: cast_nullable_to_non_nullable
as String,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,showConfirmDialog: null == showConfirmDialog ? _self.showConfirmDialog : showConfirmDialog // ignore: cast_nullable_to_non_nullable
as bool,haptic: null == haptic ? _self.haptic : haptic // ignore: cast_nullable_to_non_nullable
as bool,strikeVib: null == strikeVib ? _self.strikeVib : strikeVib // ignore: cast_nullable_to_non_nullable
as bool,sound: null == sound ? _self.sound : sound // ignore: cast_nullable_to_non_nullable
as bool,sleepPrevent: null == sleepPrevent ? _self.sleepPrevent : sleepPrevent // ignore: cast_nullable_to_non_nullable
as bool,leftHanded: null == leftHanded ? _self.leftHanded : leftHanded // ignore: cast_nullable_to_non_nullable
as bool,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,securityLevel: null == securityLevel ? _self.securityLevel : securityLevel // ignore: cast_nullable_to_non_nullable
as int,adminPasscode: freezed == adminPasscode ? _self.adminPasscode : adminPasscode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsModel].
extension SettingsModelPatterns on SettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _SettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String confirmBehavior,  bool isLocked,  bool showConfirmDialog,  bool haptic,  bool strikeVib,  bool sound,  bool sleepPrevent,  bool leftHanded,  String themeMode,  int securityLevel,  String? adminPasscode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsModel() when $default != null:
return $default(_that.confirmBehavior,_that.isLocked,_that.showConfirmDialog,_that.haptic,_that.strikeVib,_that.sound,_that.sleepPrevent,_that.leftHanded,_that.themeMode,_that.securityLevel,_that.adminPasscode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String confirmBehavior,  bool isLocked,  bool showConfirmDialog,  bool haptic,  bool strikeVib,  bool sound,  bool sleepPrevent,  bool leftHanded,  String themeMode,  int securityLevel,  String? adminPasscode)  $default,) {final _that = this;
switch (_that) {
case _SettingsModel():
return $default(_that.confirmBehavior,_that.isLocked,_that.showConfirmDialog,_that.haptic,_that.strikeVib,_that.sound,_that.sleepPrevent,_that.leftHanded,_that.themeMode,_that.securityLevel,_that.adminPasscode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String confirmBehavior,  bool isLocked,  bool showConfirmDialog,  bool haptic,  bool strikeVib,  bool sound,  bool sleepPrevent,  bool leftHanded,  String themeMode,  int securityLevel,  String? adminPasscode)?  $default,) {final _that = this;
switch (_that) {
case _SettingsModel() when $default != null:
return $default(_that.confirmBehavior,_that.isLocked,_that.showConfirmDialog,_that.haptic,_that.strikeVib,_that.sound,_that.sleepPrevent,_that.leftHanded,_that.themeMode,_that.securityLevel,_that.adminPasscode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SettingsModel implements SettingsModel {
  const _SettingsModel({this.confirmBehavior = 'double', this.isLocked = false, this.showConfirmDialog = false, this.haptic = true, this.strikeVib = true, this.sound = false, this.sleepPrevent = true, this.leftHanded = false, this.themeMode = 'system', this.securityLevel = 1, this.adminPasscode});
  factory _SettingsModel.fromJson(Map<String, dynamic> json) => _$SettingsModelFromJson(json);

// 【操作・安全設定】
// ★ アプリの初期状態を「大会・錬成会」プリセットに完全統一
@override@JsonKey() final  String confirmBehavior;
@override@JsonKey() final  bool isLocked;
@override@JsonKey() final  bool showConfirmDialog;
// ★ 変更：初期値をOFF（ダイアログなし）に統一
// 【フィードバック】
@override@JsonKey() final  bool haptic;
@override@JsonKey() final  bool strikeVib;
@override@JsonKey() final  bool sound;
// ★ 錬成会モードに合わせて初期値はオフ
// 【システム・表示】
@override@JsonKey() final  bool sleepPrevent;
// スリープ(画面消灯)防止
@override@JsonKey() final  bool leftHanded;
// 左利きモード（赤白反転）
@override@JsonKey() final  String themeMode;
// ★ ダークモード対応 ('system', 'light', 'dark')
// 【セキュリティ・権限】 (Phase 8)
@override@JsonKey() final  int securityLevel;
// ★ Phase 8: 1(自由), 2(標準), 3(厳格)
@override final  String? adminPasscode;

/// Create a copy of SettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsModelCopyWith<_SettingsModel> get copyWith => __$SettingsModelCopyWithImpl<_SettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsModel&&(identical(other.confirmBehavior, confirmBehavior) || other.confirmBehavior == confirmBehavior)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.showConfirmDialog, showConfirmDialog) || other.showConfirmDialog == showConfirmDialog)&&(identical(other.haptic, haptic) || other.haptic == haptic)&&(identical(other.strikeVib, strikeVib) || other.strikeVib == strikeVib)&&(identical(other.sound, sound) || other.sound == sound)&&(identical(other.sleepPrevent, sleepPrevent) || other.sleepPrevent == sleepPrevent)&&(identical(other.leftHanded, leftHanded) || other.leftHanded == leftHanded)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.securityLevel, securityLevel) || other.securityLevel == securityLevel)&&(identical(other.adminPasscode, adminPasscode) || other.adminPasscode == adminPasscode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,confirmBehavior,isLocked,showConfirmDialog,haptic,strikeVib,sound,sleepPrevent,leftHanded,themeMode,securityLevel,adminPasscode);

@override
String toString() {
  return 'SettingsModel(confirmBehavior: $confirmBehavior, isLocked: $isLocked, showConfirmDialog: $showConfirmDialog, haptic: $haptic, strikeVib: $strikeVib, sound: $sound, sleepPrevent: $sleepPrevent, leftHanded: $leftHanded, themeMode: $themeMode, securityLevel: $securityLevel, adminPasscode: $adminPasscode)';
}


}

/// @nodoc
abstract mixin class _$SettingsModelCopyWith<$Res> implements $SettingsModelCopyWith<$Res> {
  factory _$SettingsModelCopyWith(_SettingsModel value, $Res Function(_SettingsModel) _then) = __$SettingsModelCopyWithImpl;
@override @useResult
$Res call({
 String confirmBehavior, bool isLocked, bool showConfirmDialog, bool haptic, bool strikeVib, bool sound, bool sleepPrevent, bool leftHanded, String themeMode, int securityLevel, String? adminPasscode
});




}
/// @nodoc
class __$SettingsModelCopyWithImpl<$Res>
    implements _$SettingsModelCopyWith<$Res> {
  __$SettingsModelCopyWithImpl(this._self, this._then);

  final _SettingsModel _self;
  final $Res Function(_SettingsModel) _then;

/// Create a copy of SettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? confirmBehavior = null,Object? isLocked = null,Object? showConfirmDialog = null,Object? haptic = null,Object? strikeVib = null,Object? sound = null,Object? sleepPrevent = null,Object? leftHanded = null,Object? themeMode = null,Object? securityLevel = null,Object? adminPasscode = freezed,}) {
  return _then(_SettingsModel(
confirmBehavior: null == confirmBehavior ? _self.confirmBehavior : confirmBehavior // ignore: cast_nullable_to_non_nullable
as String,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,showConfirmDialog: null == showConfirmDialog ? _self.showConfirmDialog : showConfirmDialog // ignore: cast_nullable_to_non_nullable
as bool,haptic: null == haptic ? _self.haptic : haptic // ignore: cast_nullable_to_non_nullable
as bool,strikeVib: null == strikeVib ? _self.strikeVib : strikeVib // ignore: cast_nullable_to_non_nullable
as bool,sound: null == sound ? _self.sound : sound // ignore: cast_nullable_to_non_nullable
as bool,sleepPrevent: null == sleepPrevent ? _self.sleepPrevent : sleepPrevent // ignore: cast_nullable_to_non_nullable
as bool,leftHanded: null == leftHanded ? _self.leftHanded : leftHanded // ignore: cast_nullable_to_non_nullable
as bool,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,securityLevel: null == securityLevel ? _self.securityLevel : securityLevel // ignore: cast_nullable_to_non_nullable
as int,adminPasscode: freezed == adminPasscode ? _self.adminPasscode : adminPasscode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
