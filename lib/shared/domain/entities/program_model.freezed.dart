// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'program_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProgramModel {

 String get id; String get tournamentId; String get title;// 例: 「1日目 進行表」
 String get fileUrl;// Firebase Storage のダウンロードURL
 String get fileType;// 'pdf' または 'image'
 int get pageCount;// PDFの総ページ数（画像の場合は1）
 bool? get isOcrProcessed;// ★ 追加：OCR解析が完了したかどうか
 List<dynamic>? get ocrWords;// ★ 追加：OCRで検出された文字と座標のデータ
@TimestampConverter() DateTime get createdAt;
/// Create a copy of ProgramModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgramModelCopyWith<ProgramModel> get copyWith => _$ProgramModelCopyWithImpl<ProgramModel>(this as ProgramModel, _$identity);

  /// Serializes this ProgramModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgramModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.title, title) || other.title == title)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.fileType, fileType) || other.fileType == fileType)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.isOcrProcessed, isOcrProcessed) || other.isOcrProcessed == isOcrProcessed)&&const DeepCollectionEquality().equals(other.ocrWords, ocrWords)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tournamentId,title,fileUrl,fileType,pageCount,isOcrProcessed,const DeepCollectionEquality().hash(ocrWords),createdAt);

@override
String toString() {
  return 'ProgramModel(id: $id, tournamentId: $tournamentId, title: $title, fileUrl: $fileUrl, fileType: $fileType, pageCount: $pageCount, isOcrProcessed: $isOcrProcessed, ocrWords: $ocrWords, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ProgramModelCopyWith<$Res>  {
  factory $ProgramModelCopyWith(ProgramModel value, $Res Function(ProgramModel) _then) = _$ProgramModelCopyWithImpl;
@useResult
$Res call({
 String id, String tournamentId, String title, String fileUrl, String fileType, int pageCount, bool? isOcrProcessed, List<dynamic>? ocrWords,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$ProgramModelCopyWithImpl<$Res>
    implements $ProgramModelCopyWith<$Res> {
  _$ProgramModelCopyWithImpl(this._self, this._then);

  final ProgramModel _self;
  final $Res Function(ProgramModel) _then;

/// Create a copy of ProgramModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tournamentId = null,Object? title = null,Object? fileUrl = null,Object? fileType = null,Object? pageCount = null,Object? isOcrProcessed = freezed,Object? ocrWords = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tournamentId: null == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,fileUrl: null == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String,fileType: null == fileType ? _self.fileType : fileType // ignore: cast_nullable_to_non_nullable
as String,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,isOcrProcessed: freezed == isOcrProcessed ? _self.isOcrProcessed : isOcrProcessed // ignore: cast_nullable_to_non_nullable
as bool?,ocrWords: freezed == ocrWords ? _self.ocrWords : ocrWords // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgramModel].
extension ProgramModelPatterns on ProgramModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgramModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgramModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgramModel value)  $default,){
final _that = this;
switch (_that) {
case _ProgramModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgramModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProgramModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tournamentId,  String title,  String fileUrl,  String fileType,  int pageCount,  bool? isOcrProcessed,  List<dynamic>? ocrWords, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgramModel() when $default != null:
return $default(_that.id,_that.tournamentId,_that.title,_that.fileUrl,_that.fileType,_that.pageCount,_that.isOcrProcessed,_that.ocrWords,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tournamentId,  String title,  String fileUrl,  String fileType,  int pageCount,  bool? isOcrProcessed,  List<dynamic>? ocrWords, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ProgramModel():
return $default(_that.id,_that.tournamentId,_that.title,_that.fileUrl,_that.fileType,_that.pageCount,_that.isOcrProcessed,_that.ocrWords,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tournamentId,  String title,  String fileUrl,  String fileType,  int pageCount,  bool? isOcrProcessed,  List<dynamic>? ocrWords, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ProgramModel() when $default != null:
return $default(_that.id,_that.tournamentId,_that.title,_that.fileUrl,_that.fileType,_that.pageCount,_that.isOcrProcessed,_that.ocrWords,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgramModel implements ProgramModel {
  const _ProgramModel({required this.id, required this.tournamentId, required this.title, required this.fileUrl, required this.fileType, this.pageCount = 1, this.isOcrProcessed, final  List<dynamic>? ocrWords, @TimestampConverter() required this.createdAt}): _ocrWords = ocrWords;
  factory _ProgramModel.fromJson(Map<String, dynamic> json) => _$ProgramModelFromJson(json);

@override final  String id;
@override final  String tournamentId;
@override final  String title;
// 例: 「1日目 進行表」
@override final  String fileUrl;
// Firebase Storage のダウンロードURL
@override final  String fileType;
// 'pdf' または 'image'
@override@JsonKey() final  int pageCount;
// PDFの総ページ数（画像の場合は1）
@override final  bool? isOcrProcessed;
// ★ 追加：OCR解析が完了したかどうか
 final  List<dynamic>? _ocrWords;
// ★ 追加：OCR解析が完了したかどうか
@override List<dynamic>? get ocrWords {
  final value = _ocrWords;
  if (value == null) return null;
  if (_ocrWords is EqualUnmodifiableListView) return _ocrWords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

// ★ 追加：OCRで検出された文字と座標のデータ
@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of ProgramModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgramModelCopyWith<_ProgramModel> get copyWith => __$ProgramModelCopyWithImpl<_ProgramModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgramModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgramModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tournamentId, tournamentId) || other.tournamentId == tournamentId)&&(identical(other.title, title) || other.title == title)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.fileType, fileType) || other.fileType == fileType)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.isOcrProcessed, isOcrProcessed) || other.isOcrProcessed == isOcrProcessed)&&const DeepCollectionEquality().equals(other._ocrWords, _ocrWords)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tournamentId,title,fileUrl,fileType,pageCount,isOcrProcessed,const DeepCollectionEquality().hash(_ocrWords),createdAt);

@override
String toString() {
  return 'ProgramModel(id: $id, tournamentId: $tournamentId, title: $title, fileUrl: $fileUrl, fileType: $fileType, pageCount: $pageCount, isOcrProcessed: $isOcrProcessed, ocrWords: $ocrWords, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ProgramModelCopyWith<$Res> implements $ProgramModelCopyWith<$Res> {
  factory _$ProgramModelCopyWith(_ProgramModel value, $Res Function(_ProgramModel) _then) = __$ProgramModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String tournamentId, String title, String fileUrl, String fileType, int pageCount, bool? isOcrProcessed, List<dynamic>? ocrWords,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$ProgramModelCopyWithImpl<$Res>
    implements _$ProgramModelCopyWith<$Res> {
  __$ProgramModelCopyWithImpl(this._self, this._then);

  final _ProgramModel _self;
  final $Res Function(_ProgramModel) _then;

/// Create a copy of ProgramModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tournamentId = null,Object? title = null,Object? fileUrl = null,Object? fileType = null,Object? pageCount = null,Object? isOcrProcessed = freezed,Object? ocrWords = freezed,Object? createdAt = null,}) {
  return _then(_ProgramModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tournamentId: null == tournamentId ? _self.tournamentId : tournamentId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,fileUrl: null == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String,fileType: null == fileType ? _self.fileType : fileType // ignore: cast_nullable_to_non_nullable
as String,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,isOcrProcessed: freezed == isOcrProcessed ? _self.isOcrProcessed : isOcrProcessed // ignore: cast_nullable_to_non_nullable
as bool?,ocrWords: freezed == ocrWords ? _self._ocrWords : ocrWords // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$StrokeModel {

 String get id; String get programId; int get pageIndex;// 何ページ目に描かれた線か
 String get authorId;// 誰が描いたか
 int get colorValue;// ARGBのint値 (例: Colors.red.value)
 double get strokeWidth;// 線の太さ
 List<double> get points;// [x1, y1, x2, y2, ...] のフラットリスト（軽量化・高速化のため）
 bool get isShared;// true: 共有ハイライト(全員), false: 個人メモ(自分のみ)
@TimestampConverter() DateTime get createdAt;
/// Create a copy of StrokeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StrokeModelCopyWith<StrokeModel> get copyWith => _$StrokeModelCopyWithImpl<StrokeModel>(this as StrokeModel, _$identity);

  /// Serializes this StrokeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StrokeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&const DeepCollectionEquality().equals(other.points, points)&&(identical(other.isShared, isShared) || other.isShared == isShared)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,programId,pageIndex,authorId,colorValue,strokeWidth,const DeepCollectionEquality().hash(points),isShared,createdAt);

@override
String toString() {
  return 'StrokeModel(id: $id, programId: $programId, pageIndex: $pageIndex, authorId: $authorId, colorValue: $colorValue, strokeWidth: $strokeWidth, points: $points, isShared: $isShared, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $StrokeModelCopyWith<$Res>  {
  factory $StrokeModelCopyWith(StrokeModel value, $Res Function(StrokeModel) _then) = _$StrokeModelCopyWithImpl;
@useResult
$Res call({
 String id, String programId, int pageIndex, String authorId, int colorValue, double strokeWidth, List<double> points, bool isShared,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class _$StrokeModelCopyWithImpl<$Res>
    implements $StrokeModelCopyWith<$Res> {
  _$StrokeModelCopyWithImpl(this._self, this._then);

  final StrokeModel _self;
  final $Res Function(StrokeModel) _then;

/// Create a copy of StrokeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? programId = null,Object? pageIndex = null,Object? authorId = null,Object? colorValue = null,Object? strokeWidth = null,Object? points = null,Object? isShared = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as double,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<double>,isShared: null == isShared ? _self.isShared : isShared // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [StrokeModel].
extension StrokeModelPatterns on StrokeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StrokeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StrokeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StrokeModel value)  $default,){
final _that = this;
switch (_that) {
case _StrokeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StrokeModel value)?  $default,){
final _that = this;
switch (_that) {
case _StrokeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String programId,  int pageIndex,  String authorId,  int colorValue,  double strokeWidth,  List<double> points,  bool isShared, @TimestampConverter()  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StrokeModel() when $default != null:
return $default(_that.id,_that.programId,_that.pageIndex,_that.authorId,_that.colorValue,_that.strokeWidth,_that.points,_that.isShared,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String programId,  int pageIndex,  String authorId,  int colorValue,  double strokeWidth,  List<double> points,  bool isShared, @TimestampConverter()  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _StrokeModel():
return $default(_that.id,_that.programId,_that.pageIndex,_that.authorId,_that.colorValue,_that.strokeWidth,_that.points,_that.isShared,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String programId,  int pageIndex,  String authorId,  int colorValue,  double strokeWidth,  List<double> points,  bool isShared, @TimestampConverter()  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _StrokeModel() when $default != null:
return $default(_that.id,_that.programId,_that.pageIndex,_that.authorId,_that.colorValue,_that.strokeWidth,_that.points,_that.isShared,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StrokeModel implements StrokeModel {
  const _StrokeModel({required this.id, required this.programId, required this.pageIndex, required this.authorId, required this.colorValue, required this.strokeWidth, required final  List<double> points, required this.isShared, @TimestampConverter() required this.createdAt}): _points = points;
  factory _StrokeModel.fromJson(Map<String, dynamic> json) => _$StrokeModelFromJson(json);

@override final  String id;
@override final  String programId;
@override final  int pageIndex;
// 何ページ目に描かれた線か
@override final  String authorId;
// 誰が描いたか
@override final  int colorValue;
// ARGBのint値 (例: Colors.red.value)
@override final  double strokeWidth;
// 線の太さ
 final  List<double> _points;
// 線の太さ
@override List<double> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

// [x1, y1, x2, y2, ...] のフラットリスト（軽量化・高速化のため）
@override final  bool isShared;
// true: 共有ハイライト(全員), false: 個人メモ(自分のみ)
@override@TimestampConverter() final  DateTime createdAt;

/// Create a copy of StrokeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StrokeModelCopyWith<_StrokeModel> get copyWith => __$StrokeModelCopyWithImpl<_StrokeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StrokeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StrokeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&(identical(other.strokeWidth, strokeWidth) || other.strokeWidth == strokeWidth)&&const DeepCollectionEquality().equals(other._points, _points)&&(identical(other.isShared, isShared) || other.isShared == isShared)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,programId,pageIndex,authorId,colorValue,strokeWidth,const DeepCollectionEquality().hash(_points),isShared,createdAt);

@override
String toString() {
  return 'StrokeModel(id: $id, programId: $programId, pageIndex: $pageIndex, authorId: $authorId, colorValue: $colorValue, strokeWidth: $strokeWidth, points: $points, isShared: $isShared, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$StrokeModelCopyWith<$Res> implements $StrokeModelCopyWith<$Res> {
  factory _$StrokeModelCopyWith(_StrokeModel value, $Res Function(_StrokeModel) _then) = __$StrokeModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String programId, int pageIndex, String authorId, int colorValue, double strokeWidth, List<double> points, bool isShared,@TimestampConverter() DateTime createdAt
});




}
/// @nodoc
class __$StrokeModelCopyWithImpl<$Res>
    implements _$StrokeModelCopyWith<$Res> {
  __$StrokeModelCopyWithImpl(this._self, this._then);

  final _StrokeModel _self;
  final $Res Function(_StrokeModel) _then;

/// Create a copy of StrokeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? programId = null,Object? pageIndex = null,Object? authorId = null,Object? colorValue = null,Object? strokeWidth = null,Object? points = null,Object? isShared = null,Object? createdAt = null,}) {
  return _then(_StrokeModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,strokeWidth: null == strokeWidth ? _self.strokeWidth : strokeWidth // ignore: cast_nullable_to_non_nullable
as double,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<double>,isShared: null == isShared ? _self.isShared : isShared // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
