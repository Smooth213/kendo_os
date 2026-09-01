import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_scene_badge.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

void showRuleInfoBottomSheet(BuildContext context, MatchModel match) {
  HapticFeedback.mediumImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bool isBunaiksen =
      match.tournamentId?.startsWith('bunaiksen_') ?? false;
  final themeColors = AppThemeColors.ofMode(
    isDark: isDark,
    mode: isBunaiksen ? 'bunaiksen' : 'normal',
  );
  final rule = match.rule;

  final bool isLegacyLeague = match.note.contains('[リーグ戦]');
  final bool isLeague = (rule?.isLeague ?? false) || isLegacyLeague;
  final bool isIndividual =
      !match.isKachinuki &&
      (match.matchType == 'individual' ||
          match.matchType == '選手' ||
          match.matchType.contains('個人戦') ||
          (rule != null &&
              rule.positions.length == 1 &&
              (rule.positions.first == '選手' || rule.positions.first == '個人戦')));

  // --- 1. 試合シーン ＆ 形式 ---
  final scene = KendoSceneHelper.detectScene(match);
  final String sceneTitle = KendoSceneHelper.getIconLabel(scene);
  final Color sceneColor = KendoSceneHelper.getColor(scene, isDark: isDark);

  String formatText = isIndividual ? '個人戦' : '団体戦';
  if (match.isKachinuki || (rule?.isKachinuki ?? false)) {
    formatText = '勝ち抜き戦';
  } else if (isLeague) {
    formatText = isIndividual ? 'リーグ個人戦' : 'リーグ団体戦';
  }

  // --- 2. 試合時間 ＆ 計測方式 ---
  final double matchTime =
      rule?.matchTimeMinutes ?? match.matchTimeMinutes.toDouble();
  final isRunningTime = rule?.isRunningTime ?? match.isRunningTime;
  String timeStr = matchTime == matchTime.toInt()
      ? '${matchTime.toInt()}分'
      : '${matchTime.toInt()}分${((matchTime % 1) * 60).round()}秒';
  final String timeDesc = '$timeStr (${isRunningTime ? "通し/空回し" : "都度ストップ"})';

  // --- 3. 勝負形式（本数） ---
  final bool isIpponShobu = rule?.isIpponShobu ?? false;
  final String shobuDesc = isIpponShobu ? '１本勝負' : '３本勝負 (２本先取)';

  // --- 4. 延長戦 ---
  final bool isEnchoUnlimited = rule?.isEnchoUnlimited ?? false;
  final double enchoMins =
      rule?.enchoTimeMinutes ?? match.extensionTimeMinutes?.toDouble() ?? 0.0;
  final int enchoCount = rule?.enchoCount ?? match.extensionCount ?? 0;
  final bool hasExtension = rule != null
      ? (isEnchoUnlimited || enchoCount > 0 || enchoMins > 0)
      : match.hasExtension;

  String enchoDesc = 'なし';
  if (hasExtension) {
    if (isEnchoUnlimited || enchoCount == -2) {
      enchoDesc = 'あり (時間無制限・決着まで)';
    } else {
      String extTimeStr = enchoMins == enchoMins.toInt()
          ? '${enchoMins.toInt()}分'
          : '${enchoMins.toInt()}分${((enchoMins % 1) * 60).round()}秒';
      final countStr = enchoCount > 0 ? '$enchoCount回' : '1回';
      enchoDesc = 'あり ($extTimeStr・$countStr)';
    }
  }

  // --- 5. 判定 ---
  final bool hanteiEnabled = rule?.hasHantei ?? match.hasHantei;
  final String hanteiDesc = hanteiEnabled ? 'あり (時間・延長終了時)' : 'なし';

  // --- 6. 団体戦・代表戦 ---
  final bool hasDaihyo = rule?.hasRepresentativeMatch ?? true;
  String daihyoDesc = 'なし';
  if (!isIndividual && hasDaihyo) {
    final daihyoTime = (rule?.daihyoMatchTimeMinutes ?? 0.0) == 0.0
        ? '時間制限なし'
        : '${rule!.daihyoMatchTimeMinutes.toInt()}分';
    final daihyoShobu = (rule?.isDaihyoIpponShobu ?? true) ? '一本勝負' : '三本勝負';

    String daihyoEncho = '延長なし';
    if (rule?.daihyoHasExtension ?? true) {
      if ((rule?.daihyoEnchoCount ?? -2) == -2) {
        daihyoEncho = '延長無制限';
      } else {
        final dEnchoTime = rule?.daihyoEnchoTimeMinutes ?? 3.0;
        final dCount = rule?.daihyoEnchoCount ?? 1;
        daihyoEncho = '延長${dEnchoTime.toInt()}分・$dCount回';
      }
    }
    final daihyoHantei = (rule?.daihyoHasHantei ?? false) ? '判定あり' : '';
    final parts = [
      daihyoTime,
      daihyoShobu,
      daihyoEncho,
      if (daihyoHantei.isNotEmpty) daihyoHantei,
    ];
    daihyoDesc = 'あり (${parts.join("・")})';
  }

  // --- 備考・メモ ---
  String cleanNote = match.note;
  if (cleanNote.contains('[SUMMARY]')) {
    cleanNote = cleanNote.replaceAll('[SUMMARY]', '').trim();
  }

  showAppBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xlargeValue),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: context.appColors.separatorColor,
                  borderRadius: AppRadius.medium,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(
                  Icons.gavel_rounded,
                  color: themeColors.primaryAccent,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '試合レギュレーション確認',
                  style: TextStyle(
                    fontSize: AppFontSize.headline,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.textColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: sceneColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.sub,
                    border: Border.all(
                      color: sceneColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    sceneTitle,
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: sceneColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            // 1. 試合形式
            _buildRuleRow('🎯 試合形式', formatText, context),

            // 2. 試合時間 ＆ 計測方式
            _buildRuleRow('⏱️ 試合時間', timeDesc, context),

            // 3. 勝負形式
            _buildRuleRow('⚔️ 勝負形式', shobuDesc, context),

            // 4. 延長戦
            _buildRuleRow('🔄 延長戦', enchoDesc, context),

            // 5. 判定
            _buildRuleRow('⚖️ 判定', hanteiDesc, context),

            // 6. 代表戦（団体戦時のみ、勝ち抜き戦・錬成会除く）
            if (!isIndividual)
              ...() {
                final bool isSpecialFormat =
                    match.isKachinuki ||
                    (rule?.isKachinuki ?? false) ||
                    (rule?.isRenseikai ?? false);
                if (!isSpecialFormat) {
                  return [_buildRuleRow('🥋 代表戦', daihyoDesc, context)];
                }
                return <Widget>[];
              }(),

            // 錬成会・勝ち抜き戦等の特殊ルール
            if (rule?.isRenseikai ?? false) ...[
              const Divider(height: 20),
              _buildRuleRow('進行方式', rule!.renseikaiType, context),
              if (rule.renseikaiType == '時間制')
                _buildRuleRow('総試合時間', '${rule.overallTimeMinutes}分', context),
            ],
            if (match.isKachinuki || (rule?.isKachinuki ?? false)) ...[
              const Divider(height: 20),
              _buildRuleRow(
                '勝ち抜き条件',
                rule?.kachinukiUnlimitedType ?? '大将対大将',
                context,
              ),
            ],

            // 備考・進行メモ
            if (cleanNote.isNotEmpty) ...[
              const Divider(height: 20),
              _buildRuleRow('📝 備考・メモ', cleanNote, context),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    ),
  );
}

Widget _buildRuleRow(String label, String value, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodySmall,
              color: context.appColors.subTextColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppFontSize.body,
              color: context.appColors.textColor,
              fontWeight: AppFontWeight.semiBold,
            ),
          ),
        ),
      ],
    ),
  );
}
