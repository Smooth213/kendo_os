import 'package:flutter/material.dart';

/// プログラム手書きキャンバスの消しゴム判定ヘルパー
class ProgramViewerStrokeEraser {
  static bool isNearStroke(
    Offset touchPoint,
    List<Offset> strokePoints,
    double threshold,
  ) {
    for (final pt in strokePoints) {
      if ((touchPoint - pt).distance <= threshold) {
        return true;
      }
    }
    return false;
  }

  static bool isNearLocalStroke(
    Offset touchPoint,
    List<double> xs,
    List<double> ys,
    double threshold,
  ) {
    final len = xs.length;
    for (int i = 0; i < len; i++) {
      if ((touchPoint - Offset(xs[i], ys[i])).distance <= threshold) {
        return true;
      }
    }
    return false;
  }
}
