import 'package:isar_community/isar.dart';

// build_runnerで自動生成されるファイルを指定
part 'local_stroke_model.g.dart';

/// 自分だけのメモ（青ペンなど）をローカル保存するためのIsar用モデル
@collection
class LocalStrokeModel {
  Id id = Isar.autoIncrement; // Isarが自動で割り当てる内部ID

  @Index(type: IndexType.hash)
  late String programId; // どのプログラム（画像/PDF）に引かれた線か

  // Isarは「Offset(X, Y)」という複雑な型を直接保存できないため、
  // X座標のリストとY座標のリストに分けて保存するプロのテクニックを使います
  late List<double> pointsX;
  late List<double> pointsY;

  late int colorValue; // 線の色（数値化して保存）
  late double strokeWidth; // 線の太さ
  late DateTime createdAt; // 描画日時
}