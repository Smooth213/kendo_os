import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 対戦フォーマット設定画面の純粋ロジック・ヘルパー
class MatchFormatSetupHelper {
  static const List<String> majorCategories = [
    '初心者',
    '幼年',
    '小学生',
    '中学生',
    '高校生',
    '大学・一般',
  ];

  static List<String> getMinorCategories(String major) {
    if (major == '初心者' || major == '幼年') {
      return ['全体', '男子', '女子'];
    }
    if (major == '小学生') {
      return [
        '全体',
        '低学年',
        '高学年',
        '1年',
        '2年',
        '3年',
        '4年',
        '5年',
        '6年',
        '男子',
        '女子',
      ];
    }
    if (major == '中学生' || major == '高校生') {
      return ['全体', '1年', '2年', '3年', '男子', '女子'];
    }
    if (major == '大学・一般') {
      return ['全体', '大学生', '一般', 'シニア', '男子', '女子'];
    }
    return ['全体'];
  }

  /// カテゴリ文字列から (major, minor) を復元
  static (String, String) parseCategoryToState(String categoryName) {
    if (categoryName == '初心者の部') {
      return ('初心者', '全体');
    }
    if (categoryName == '幼年の部') {
      return ('幼年', '全体');
    }
    final cleanCat = categoryName.replaceAll('の部', '');
    if (['大学生', '一般', 'シニア'].contains(cleanCat)) {
      return ('大学・一般', cleanCat);
    }
    for (var major in ['小学生', '中学生', '高校生']) {
      if (cleanCat.startsWith(major)) {
        final minor = cleanCat.substring(major.length);
        return (major, minor.isEmpty ? '全体' : minor);
      }
    }
    return ('小学生', '低学年');
  }

  /// チームサイズに応じたポジション名の生成
  static List<String> generatePositions(int size) {
    if (size <= 0) return [];
    if (size == 1) return ['選手'];
    if (size == 3) return ['先鋒', '中堅', '大将'];
    if (size == 5) return ['先鋒', '次鋒', '中堅', '副将', '大将'];

    List<String> positions = [];
    positions.add('先鋒');
    if (size >= 2) positions.add('次鋒');

    for (int i = 3; i <= size - 2; i++) {
      if (size % 2 != 0 && i == (size + 1) ~/ 2) {
        positions.add('中堅');
      } else {
        int k = size - i + 1;
        positions.add('$k将');
      }
    }

    if (size >= 4) positions.add('副将');
    if (size >= 3) positions.add('大将');

    return positions;
  }

  /// チームサイズ（人数）の算出
  static int calculateTeamSize({
    required String matchType,
    required String? selectedTeamId,
    required List<TeamModel> registeredTeams,
  }) {
    if (matchType == '個人戦' ||
        matchType == 'リーグ個人戦' ||
        matchType.contains('1人制')) {
      return 1;
    }
    if (matchType.contains('3人制')) {
      return 3;
    }
    if (matchType.contains('7人制')) {
      return 7;
    }

    if (selectedTeamId != null) {
      TeamModel? selectedTeam;
      for (var t in registeredTeams) {
        if (t.id == selectedTeamId) {
          selectedTeam = t;
          break;
        }
      }
      if (selectedTeam != null && selectedTeam.matchType.isNotEmpty) {
        if (selectedTeam.matchType.contains('3人制')) {
          return 3;
        }
        if (selectedTeam.matchType.contains('7人制')) {
          return 7;
        }
        if (selectedTeam.matchType.contains('1人制') ||
            selectedTeam.matchType.contains('個人戦')) {
          return 1;
        }
      }
    }
    return 5;
  }

  /// 共通 InputDecoration ビルダー
  static InputDecoration buildTextFieldDecoration({
    required AppThemeColors themeColors,
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: themeColors.subTextColor,
        fontSize: AppFontSize.bodySmall,
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: themeColors.hintColor,
        fontSize: AppFontSize.bodyMedium,
      ),
      suffixText: suffixText,
      suffixStyle: TextStyle(color: themeColors.subTextColor),
      prefixIcon: prefixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      filled: true,
      fillColor: themeColors.inputBackground,
      border: OutlineInputBorder(borderRadius: AppRadius.medium),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: themeColors.separatorColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: themeColors.primaryAccent, width: 2),
      ),
    );
  }

  /// MatchRule インスタンスの組み立て
  static MatchRule createMatchRule({
    required List<String> positions,
    required double matchTime,
    required bool isRunningTime,
    required bool isLeague,
    required String category,
    required String noteCombined,
    required bool isRenseikai,
    required List<String> baseOrder,
    required String teamName,
    required bool isKachinuki,
    required String kachinukiUnlimitedType,
    required bool hasLeagueDaihyo,
    required String renseikaiType,
    required int overallTimeMinutes,
    required bool isDaihyoIpponShobu,
    required bool hasExtension,
    required double extTime,
    required int extCount,
    required bool hasHantei,
    required double winPoint,
    required double lossPoint,
    required double drawPoint,
    required String selectedRuleScene,
  }) {
    return MatchRule(
      positions: positions,
      matchTimeMinutes: matchTime,
      isRunningTime: isRunningTime,
      isLeague: isLeague,
      category: category,
      note: noteCombined,
      isRenseikai: isRenseikai,
      baseOrder: baseOrder,
      teamName: teamName,
      isKachinuki: isKachinuki,
      kachinukiUnlimitedType: kachinukiUnlimitedType,
      hasLeagueDaihyo: hasLeagueDaihyo,
      renseikaiType: renseikaiType,
      overallTimeMinutes: overallTimeMinutes,
      isDaihyoIpponShobu: isDaihyoIpponShobu,
      isEnchoUnlimited: hasExtension && (extTime == -2.0 || extCount == -2),
      enchoTimeMinutes: hasExtension ? (extTime == -2.0 ? 0.0 : extTime) : 0.0,
      enchoCount: hasExtension ? (extCount == -2 ? 99 : extCount) : 0,
      hasHantei: hasHantei,
      winPoint: winPoint,
      lossPoint: lossPoint,
      drawPoint: drawPoint,
      matchScene: selectedRuleScene,
    );
  }
}
