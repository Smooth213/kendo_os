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
    'その他',
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
    if (major == 'その他') {
      return ['混成', '混合', '自由', '全体', '直接入力'];
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
    if (cleanCat == 'その他' ||
        cleanCat == '混成' ||
        cleanCat == '混合' ||
        cleanCat == '自由') {
      return ('その他', cleanCat == 'その他' ? '全体' : cleanCat);
    }
    for (var major in ['小学生', '中学生', '高校生']) {
      if (cleanCat.startsWith(major)) {
        final minor = cleanCat.substring(major.length);
        return (major, minor.isEmpty ? '全体' : minor);
      }
    }
    if (cleanCat.startsWith('その他')) {
      final minor = cleanCat.substring(3);
      return ('その他', minor.isEmpty ? '全体' : minor);
    }
    return ('その他', '直接入力');
  }

  /// 数値を漢数字（1〜99）に変換するユーティリティ
  static String toKanjiNumber(int n) {
    if (n <= 0) return '$n';
    const kanjiDigits = ['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
    if (n < 10) {
      return kanjiDigits[n];
    }
    if (n == 10) {
      return '十';
    }
    if (n < 20) {
      return '十${kanjiDigits[n % 10]}';
    }
    final tens = n ~/ 10;
    final ones = n % 10;
    if (ones == 0) {
      return '${kanjiDigits[tens]}十';
    }
    return '${kanjiDigits[tens]}十${kanjiDigits[ones]}';
  }

  /// チームサイズに応じたポジション名の生成
  static List<String> generatePositions(int size) {
    if (size <= 0) return [];
    if (size == 1) return ['選手'];
    if (size == 2) return ['先鋒', '大将'];
    if (size == 3) return ['先鋒', '中堅', '大将'];
    if (size == 4) return ['先鋒', '次鋒', '副将', '大将'];
    if (size == 5) return ['先鋒', '次鋒', '中堅', '副将', '大将'];

    final positions = <String>['先鋒', '次鋒'];
    final isOdd = size % 2 != 0;
    final mid = (size + 1) ~/ 2;

    for (int i = 3; i <= size - 2; i++) {
      if (isOdd && i == mid) {
        positions.add('中堅');
      } else {
        final int k = size - i + 1;
        positions.add('${toKanjiNumber(k)}将');
      }
    }

    positions.add('副将');
    positions.add('大将');

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
      if (selectedTeam != null) {
        if (selectedTeam.matchType.contains('それ以上') ||
            matchType.contains('それ以上')) {
          if (selectedTeam.playerNames.isNotEmpty) {
            return selectedTeam.playerNames.length;
          }
        }
        if (selectedTeam.matchType.isNotEmpty) {
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
        if (selectedTeam.playerNames.length > 5) {
          return selectedTeam.playerNames.length;
        }
      }
    }

    if (matchType.contains('それ以上')) {
      int maxCount = 8;
      for (var t in registeredTeams) {
        if (t.matchType.contains('それ以上') && t.playerNames.length > maxCount) {
          maxCount = t.playerNames.length;
        }
      }
      return maxCount;
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
    bool isIpponShobu = false,
    int ipponLimit = 2,
    int hansokuLimit = 2,
    double daihyoMatchTime = 0.0,
    bool daihyoHasExtension = true,
    double daihyoEnchoTime = 3.0,
    int daihyoEnchoCount = -2,
    bool daihyoHasHantei = false,
    required bool hasExtension,
    required double extTime,
    required int extCount,
    required bool hasHantei,
    required double winPoint,
    required double lossPoint,
    required double drawPoint,
    required String selectedRuleScene,
    bool skipEmptyRoster = false,
  }) {
    final effectiveIsIpponShobu = isIpponShobu || ipponLimit == 1;
    return MatchRule(
      positions: positions,
      matchTimeMinutes: matchTime,
      isRunningTime: isRunningTime,
      isIpponShobu: effectiveIsIpponShobu,
      ipponLimit: effectiveIsIpponShobu ? 1 : ipponLimit,
      hansokuLimit: hansokuLimit,
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
      skipEmptyRoster: skipEmptyRoster,
      isDaihyoIpponShobu: isDaihyoIpponShobu,
      daihyoMatchTimeMinutes: daihyoMatchTime,
      daihyoHasExtension: daihyoHasExtension,
      daihyoEnchoTimeMinutes: daihyoEnchoTime,
      daihyoEnchoCount: daihyoEnchoCount,
      daihyoHasHantei: daihyoHasHantei,
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
