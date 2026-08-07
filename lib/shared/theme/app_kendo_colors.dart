import 'package:flutter/material.dart';

/// 剣道競技ルールおよび物理オブジェクトに固有の固定カラー定数。
///
/// テーマ（ダークモード・ライトモード）に関わらず、
/// 赤旗・白旗・一本表示・反則カード等の競技標準色として一貫して使用します。
class AppKendoColors {
  AppKendoColors._();

  /// 共通マテリアルカラーエイリアス (shadeアクセス互換)
  static const MaterialColor indigo = Colors.indigo;
  static const MaterialColor teal = Colors.teal;
  static const MaterialColor blue = Colors.blue;
  static const MaterialColor orange = Colors.orange;
  static const MaterialColor purple = Colors.purple;
  static const MaterialColor grey = Colors.grey;
  static const MaterialColor red = Colors.red;
  static const MaterialColor amber = Colors.amber;
  static const MaterialColor green = Colors.green;
  static const MaterialColor yellow = Colors.yellow;
  static const MaterialColor pink = Colors.pink;
  static const MaterialColor cyan = Colors.cyan;
  static const MaterialColor brown = Colors.brown;
  static const MaterialColor deepPurple = Colors.deepPurple;
  static const MaterialColor blueGrey = Colors.blueGrey;
  static const MaterialColor deepOrange = Colors.deepOrange;

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

  /// 透明
  static const Color transparent = Colors.transparent;

  /// 純白 (UI固定白)
  static const Color pureWhite = Colors.white;

  /// 純黒 (UI固定黒)
  static const Color pureBlack = Colors.black;

  /// 標準白・黒エイリアス
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  /// アクセントカラーエイリアス
  static const Color orangeAccent = Colors.orangeAccent;
  static const Color tealAccent = Colors.tealAccent;
  static const Color blueAccent = Colors.blueAccent;
  static const Color redAccent = Colors.redAccent;
  static const Color pinkAccent = Colors.pinkAccent;
  static const Color purpleAccent = Colors.purpleAccent;
  static const Color cyanAccent = Colors.cyanAccent;
  static const Color yellowAccent = Colors.yellowAccent;
  static const Color greenAccent = Colors.greenAccent;

  /// アルファ透明度カラー定数
  static const Color white60 = Colors.white60;
  static const Color white38 = Colors.white38;
  static const Color black45 = Colors.black45;
}
