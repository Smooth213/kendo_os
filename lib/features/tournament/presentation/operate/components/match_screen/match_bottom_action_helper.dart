import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

/// 試合画面の最下部アクション（確定・終了・延長等）に関する計算・ヘルパークラス
class MatchBottomActionHelper {
  const MatchBottomActionHelper._();

  /// 確定ボタンのラベル文字列を決定する
  static String getConfirmButtonLabel({
    required bool isTie,
    required bool isTrulyTeamMatch,
    required bool isAllDone,
    required String? tournamentId,
  }) {
    if (isTie && isTrulyTeamMatch) {
      return '記録確定・星取表へ';
    }
    if (isAllDone) {
      if (tournamentId != null && tournamentId.startsWith('bunaiksen_')) {
        return '確定・部内戦ホームへ';
      }
      return '確定・大会ホームへ';
    }
    return '確定・次へ';
  }

  /// 確定ボタンの背景色を決定する
  static Color getConfirmButtonColor({
    required bool isTie,
    required bool isAllDone,
  }) {
    if (isTie) return AppKendoColors.hansokuRed;
    if (isAllDone) return const Color(0xFF303F9F);
    return const Color(0xFF00897B);
  }

  /// 確定ボタンのアイコンを決定する
  static IconData getConfirmButtonIcon({
    required bool isTie,
    required bool isTrulyTeamMatch,
    required bool isAllDone,
  }) {
    if (isTie && isTrulyTeamMatch) {
      return Icons.balance;
    }
    if (isAllDone) {
      return Icons.emoji_events;
    }
    return Icons.verified;
  }

  /// 延長戦の時間（分）を安全に計算する
  static double calculateExtensionMinutes({
    required MatchModel match,
    required Map<String, dynamic> lastSettings,
  }) {
    if (match.extensionTimeMinutes != null && match.extensionTimeMinutes! > 0) {
      return match.extensionTimeMinutes!;
    }

    final rule = match.rule;
    if (match.matchType == '代表戦') {
      return rule?.daihyoEnchoTimeMinutes ??
          ((lastSettings['daihyoEnchoTimeMinutes'] ??
                      lastSettings['extensionTimeMinutes'] ??
                      3.0)
                  as num)
              .toDouble();
    }

    return rule?.enchoTimeMinutes ??
        ((lastSettings['extensionTimeMinutes'] ?? 3.0) as num).toDouble();
  }

  /// 延長回数の表示文字列（例: '延長1回目'）を生成する
  static String formatExtensionCountString(String note) {
    final int currentExtCount = '延長'.allMatches(note).length;
    return '延長${currentExtCount + 1}回目';
  }

  /// 試合の得点から勝者カラー（'red' | 'white' | 'draw'）を判定する
  static String determineWinnerColor(MatchModel match) {
    final red = (match.redScore as num).toInt();
    final white = (match.whiteScore as num).toInt();
    if (red > white) return 'red';
    if (white > red) return 'white';
    return 'draw';
  }
}
