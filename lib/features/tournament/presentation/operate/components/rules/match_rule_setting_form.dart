import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_daihyo_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_encho_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_hantei_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_special_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/rules/sections/match_rule_time_section.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🥋 試合ルール設定・一括変更・個別スワイプ編集共通の統一ルール設定フォーム
class MatchRuleSettingForm extends StatelessWidget {
  final bool isDantai;
  final String selectedSceneKey; // 'honsen', 'renseikai', 'moushiawase'

  // 1. 時間 ＆ 勝負・得点・反則ルール
  final double matchTime;
  final bool isRunningTime;
  final bool isIpponShobu;
  final int ipponLimit;
  final int hansokuLimit;

  // 2. 延長戦ルール
  final bool hasExtension;
  final double enchoTime;
  final int enchoCount;
  final bool isEnchoUnlimited;

  // 3. 判定ルール
  final bool hasHantei;

  // 4. 団体戦・代表戦設定
  final bool hasRepresentativeMatch;
  final bool isDaihyoIpponShobu;
  final double daihyoMatchTime;
  final bool daihyoHasExtension;
  final double daihyoEnchoTime;
  final int daihyoEnchoCount;
  final bool isDaihyoEnchoUnlimited;
  final bool daihyoHasHantei;

  // 5. 進行形式（一試合制 / 時間制）
  final String renseikaiType;
  final TextEditingController? overallTimeController;

  // 6. 特殊形式（勝ち抜き戦・リーグ勝ち点）
  final bool isKachinuki;
  final String kachinukiUnlimitedType;
  final bool isLeague;
  final double winPoint;
  final double lossPoint;
  final double drawPoint;

  final Color primaryAccent;
  final bool isDark;

  // コールバック: 時間・勝負
  final ValueChanged<double> onMatchTimeChanged;
  final ValueChanged<bool> onRunningTimeChanged;
  final ValueChanged<bool> onIpponShobuChanged;
  final ValueChanged<int>? onIpponLimitChanged;
  final ValueChanged<int>? onHansokuLimitChanged;

  // コールバック: 延長
  final ValueChanged<bool> onExtensionChanged;
  final ValueChanged<double> onEnchoTimeChanged;
  final ValueChanged<int> onEnchoCountChanged;
  final ValueChanged<bool> onEnchoUnlimitedChanged;

  // コールバック: 判定
  final ValueChanged<bool> onHanteiChanged;

  // コールバック: 代表戦
  final ValueChanged<bool> onRepresentativeMatchChanged;
  final ValueChanged<bool> onDaihyoIpponShobuChanged;
  final ValueChanged<double> onDaihyoMatchTimeChanged;
  final ValueChanged<bool> onDaihyoExtensionChanged;
  final ValueChanged<double> onDaihyoEnchoTimeChanged;
  final ValueChanged<int> onDaihyoEnchoCountChanged;
  final ValueChanged<bool> onDaihyoEnchoUnlimitedChanged;
  final ValueChanged<bool> onDaihyoHanteiChanged;

  // コールバック: 進行形式
  final ValueChanged<String>? onRenseikaiTypeChanged;
  final ValueChanged<int>? onOverallTimeChanged;

  // コールバック: 特殊形式
  final ValueChanged<bool>? onKachinukiChanged;
  final ValueChanged<String>? onKachinukiUnlimitedTypeChanged;
  final ValueChanged<bool>? onLeagueChanged;
  final ValueChanged<double>? onWinPointChanged;
  final ValueChanged<double>? onLossPointChanged;
  final ValueChanged<double>? onDrawPointChanged;

  const MatchRuleSettingForm({
    super.key,
    this.isDantai = false,
    required this.selectedSceneKey,
    required this.matchTime,
    required this.isRunningTime,
    required this.isIpponShobu,
    this.ipponLimit = 2,
    this.hansokuLimit = 2,
    required this.hasExtension,
    required this.enchoTime,
    required this.enchoCount,
    required this.isEnchoUnlimited,
    required this.hasHantei,
    required this.hasRepresentativeMatch,
    required this.isDaihyoIpponShobu,
    this.daihyoMatchTime = 0.0,
    this.daihyoHasExtension = true,
    this.daihyoEnchoTime = 3.0,
    this.daihyoEnchoCount = -2,
    this.isDaihyoEnchoUnlimited = true,
    this.daihyoHasHantei = false,
    this.renseikaiType = '一試合制',
    this.overallTimeController,
    this.isKachinuki = false,
    this.kachinukiUnlimitedType = '大将対大将',
    this.isLeague = false,
    this.winPoint = 3.0,
    this.lossPoint = 0.0,
    this.drawPoint = 1.0,
    required this.primaryAccent,
    required this.isDark,
    required this.onMatchTimeChanged,
    required this.onRunningTimeChanged,
    required this.onIpponShobuChanged,
    this.onIpponLimitChanged,
    this.onHansokuLimitChanged,
    required this.onExtensionChanged,
    required this.onEnchoTimeChanged,
    required this.onEnchoCountChanged,
    required this.onEnchoUnlimitedChanged,
    required this.onHanteiChanged,
    required this.onRepresentativeMatchChanged,
    required this.onDaihyoIpponShobuChanged,
    required this.onDaihyoMatchTimeChanged,
    required this.onDaihyoExtensionChanged,
    required this.onDaihyoEnchoTimeChanged,
    required this.onDaihyoEnchoCountChanged,
    required this.onDaihyoEnchoUnlimitedChanged,
    required this.onDaihyoHanteiChanged,
    this.onRenseikaiTypeChanged,
    this.onOverallTimeChanged,
    this.onKachinukiChanged,
    this.onKachinukiUnlimitedTypeChanged,
    this.onLeagueChanged,
    this.onWinPointChanged,
    this.onLossPointChanged,
    this.onDrawPointChanged,
  });

  static String formatMinutes(double minutes) {
    if (minutes == 0.0) return '時間制限なし';
    final int m = minutes.toInt();
    final int s = ((minutes % 1) * 60).round();
    if (s == 0) return '$m分';
    if (m == 0) return '$s秒';
    return '$m分$s秒';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⏱️ 1. 基本ルール（試合時間・進行形式・計測方式・勝負形式・得点上限・反則）
        MatchRuleTimeSection(
          matchTime: matchTime,
          isRunningTime: isRunningTime,
          isIpponShobu: isIpponShobu,
          ipponLimit: ipponLimit,
          hansokuLimit: hansokuLimit,
          renseikaiType: renseikaiType,
          overallTimeController: overallTimeController,
          primaryAccent: primaryAccent,
          isDark: isDark,
          formatMinutes: formatMinutes,
          onMatchTimeChanged: onMatchTimeChanged,
          onRunningTimeChanged: onRunningTimeChanged,
          onIpponShobuChanged: onIpponShobuChanged,
          onIpponLimitChanged: onIpponLimitChanged,
          onHansokuLimitChanged: onHansokuLimitChanged,
          onRenseikaiTypeChanged: onRenseikaiTypeChanged,
          onOverallTimeChanged: onOverallTimeChanged,
        ),
        const SizedBox(height: AppSpacing.lg),

        // 🔄 2. 延長ルール
        MatchRuleEnchoSection(
          hasExtension: hasExtension,
          enchoTime: enchoTime,
          enchoCount: enchoCount,
          isEnchoUnlimited: isEnchoUnlimited,
          primaryAccent: primaryAccent,
          isDark: isDark,
          formatMinutes: formatMinutes,
          onExtensionChanged: onExtensionChanged,
          onEnchoTimeChanged: onEnchoTimeChanged,
          onEnchoCountChanged: onEnchoCountChanged,
          onEnchoUnlimitedChanged: onEnchoUnlimitedChanged,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ⚖️ 3. 判定ルール
        MatchRuleHanteiSection(
          hasHantei: hasHantei,
          primaryAccent: primaryAccent,
          isDark: isDark,
          onHanteiChanged: onHanteiChanged,
        ),
        const SizedBox(height: AppSpacing.lg),

        // 🥋 4. 団体戦・代表戦ルール（団体戦時のみ表示）
        if (isDantai) ...[
          MatchRuleDaihyoSection(
            isDantai: isDantai,
            hasRepresentativeMatch: hasRepresentativeMatch,
            isDaihyoIpponShobu: isDaihyoIpponShobu,
            daihyoMatchTime: daihyoMatchTime,
            daihyoHasExtension: daihyoHasExtension,
            daihyoEnchoTime: daihyoEnchoTime,
            daihyoEnchoCount: daihyoEnchoCount,
            isDaihyoEnchoUnlimited: isDaihyoEnchoUnlimited,
            daihyoHasHantei: daihyoHasHantei,
            primaryAccent: primaryAccent,
            isDark: isDark,
            formatMinutes: formatMinutes,
            onRepresentativeMatchChanged: onRepresentativeMatchChanged,
            onDaihyoIpponShobuChanged: onDaihyoIpponShobuChanged,
            onDaihyoMatchTimeChanged: onDaihyoMatchTimeChanged,
            onDaihyoExtensionChanged: onDaihyoExtensionChanged,
            onDaihyoEnchoTimeChanged: onDaihyoEnchoTimeChanged,
            onDaihyoEnchoCountChanged: onDaihyoEnchoCountChanged,
            onDaihyoEnchoUnlimitedChanged: onDaihyoEnchoUnlimitedChanged,
            onDaihyoHanteiChanged: onDaihyoHanteiChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ⚔️ 5. 特殊試合形式（勝ち抜き戦・リーグ勝ち点）
        MatchRuleSpecialSection(
          isKachinuki: isKachinuki,
          kachinukiUnlimitedType: kachinukiUnlimitedType,
          isLeague: isLeague,
          winPoint: winPoint,
          lossPoint: lossPoint,
          drawPoint: drawPoint,
          primaryAccent: primaryAccent,
          isDark: isDark,
          onKachinukiChanged: onKachinukiChanged,
          onKachinukiUnlimitedTypeChanged: onKachinukiUnlimitedTypeChanged,
          onLeagueChanged: onLeagueChanged,
          onWinPointChanged: onWinPointChanged,
          onLossPointChanged: onLossPointChanged,
          onDrawPointChanged: onDrawPointChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
