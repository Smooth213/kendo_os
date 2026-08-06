import 'package:flutter/material.dart';

/// kendo OS デザインシステムにおける統一型半径 (BorderRadius) トークン
class AppRadius {
  AppRadius._();

  static const double smallValue = 8.0;
  static const double mediumValue = 12.0;
  static const double largeValue = 16.0;
  static const double xlargeValue = 24.0;
  static const double fullValue = 999.0;

  static const BorderRadius small = BorderRadius.all(
    Radius.circular(smallValue),
  );
  static const BorderRadius medium = BorderRadius.all(
    Radius.circular(mediumValue),
  );
  static const BorderRadius large = BorderRadius.all(
    Radius.circular(largeValue),
  );
  static const BorderRadius xlarge = BorderRadius.all(
    Radius.circular(xlargeValue),
  );
  static const BorderRadius full = BorderRadius.all(Radius.circular(fullValue));
}

/// kendo OS デザインシステムにおける統一余白 (Spacing) トークン
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

/// kendo OS デザインシステムにおける統一フォントウェイト (FontWeight) トークン
///
/// 階層を3段階に整理し、UI全体での太さの散らばりを防ぎます:
///   - regular (w400): 通常の本文、サブテキスト、未選択状態のラベル
///   - semiBold (w600): カードの見出し、強調テキスト、選択されたチップ・タブ
///   - bold (w700): 画面タイトル、重要モーダル見出し、スコア数字
class AppFontWeight {
  AppFontWeight._();

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}
