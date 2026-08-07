import 'package:flutter/material.dart';

/// 剣道競技ルールおよび物理オブジェクトに固有の固定カラー定数。
///
/// テーマ（ダークモード・ライトモード）に関わらず、
/// 赤旗・白旗・一本表示・反則カード等の競技標準色として一貫して使用します。
class AppKendoColors {
  AppKendoColors._();

  /// 赤選手・赤旗標準カラー
  static const Color aka = Colors.red;

  /// 赤選手・赤旗の深みのある強調カラー (ボルドー/深紅)
  static const Color akaDark = Color(0xFF8B0000);

  /// 白選手・白旗標準カラー
  static const Color shiro = Colors.white;

  /// 一本獲得時のゴールドアクセント
  static const Color ipponGold = Color(0xFFFFD700);

  /// 反則・警告の赤
  static const Color hansokuRed = Color(0xFFD32F2F);
}
