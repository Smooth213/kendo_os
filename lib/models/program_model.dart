import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'program_model.freezed.dart';
part 'program_model.g.dart';

// FirestoreのTimestampとDateTimeを相互変換するコンバーター
class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();
  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();
  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}

/// プログラム（PDFや画像）本体の情報を管理するモデル
@freezed
abstract class ProgramModel with _$ProgramModel {
  const factory ProgramModel({
    required String id,
    required String tournamentId,
    required String title,          // 例: 「1日目 進行表」
    required String fileUrl,        // Firebase Storage のダウンロードURL
    required String fileType,       // 'pdf' または 'image'
    @Default(1) int pageCount,      // PDFの総ページ数（画像の場合は1）
    bool? isOcrProcessed,           // ★ 追加：OCR解析が完了したかどうか
    List<dynamic>? ocrWords,        // ★ 追加：OCRで検出された文字と座標のデータ
    @TimestampConverter() required DateTime createdAt,
  }) = _ProgramModel;

  factory ProgramModel.fromJson(Map<String, dynamic> json) => _$ProgramModelFromJson(json);
}

/// 手書きハイライトやメモの「1本の一筆書き（Stroke）」を管理するモデル
@freezed
abstract class StrokeModel with _$StrokeModel {
  const factory StrokeModel({
    required String id,
    required String programId,
    required int pageIndex,         // 何ページ目に描かれた線か
    required String authorId,       // 誰が描いたか
    required int colorValue,        // ARGBのint値 (例: Colors.red.value)
    required double strokeWidth,    // 線の太さ
    required List<double> points,   // [x1, y1, x2, y2, ...] のフラットリスト（軽量化・高速化のため）
    required bool isShared,         // true: 共有ハイライト(全員), false: 個人メモ(自分のみ)
    @TimestampConverter() required DateTime createdAt,
  }) = _StrokeModel;

  factory StrokeModel.fromJson(Map<String, dynamic> json) => _$StrokeModelFromJson(json);
}