import 'package:flutter/material.dart';

/// 1本の手書き線（ストローク）を表現するデータモデル
class StrokeModel {
  final String id;
  final String programId; // どのプログラム（画像/PDF）に引かれた線か
  final List<Offset> points; // 線の軌跡（X, Y座標のリスト）
  final Color color; // 線の色
  final double strokeWidth; // 線の太さ

  StrokeModel({
    required this.id,
    required this.programId,
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  // Firestoreへ保存するためのMap変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'programId': programId,
      // Offset(x,y) はFirestoreに保存できないため、数値のリストに変換する
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.toARGB32(), // 色を数値(int)として保存
      'strokeWidth': strokeWidth,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // Firestoreのデータからモデルを復元
  factory StrokeModel.fromMap(Map<String, dynamic> map) {
    return StrokeModel(
      id: map['id'] ?? '',
      programId: map['programId'] ?? '',
      points: (map['points'] as List<dynamic>).map((p) {
        return Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble());
      }).toList(),
      color: Color(map['color'] as int? ?? 0xFFFF0000), // デフォルトは赤
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 3.0,
    );
  }
}