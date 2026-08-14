import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

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

  // --- 試合形式 ---
  String formatText = isIndividual ? '個人戦' : '団体戦';
  if (rule?.isRenseikai ?? false) {
    formatText = '錬成会';
  } else if (match.isKachinuki || (rule?.isKachinuki ?? false)) {
    formatText = '勝ち抜き戦';
  } else if (isLeague) {
    formatText = isIndividual ? 'リーグ個人戦' : 'リーグ団体戦';
  }

  // --- 試合時間 ---
  final double matchTime =
      rule?.matchTimeMinutes ?? match.matchTimeMinutes.toDouble();
  final isRunningTime = rule?.isRunningTime ?? match.isRunningTime;
  String timeStr = matchTime == matchTime.toInt()
      ? '${matchTime.toInt()}分'
      : '${matchTime.toInt()}分${((matchTime % 1) * 60).toInt()}秒';
  final String timeDesc = '$timeStr (${isRunningTime ? "通し/空回し" : "都度ストップ"})';

  // --- 勝負形式（本数） ---
  final bool isIpponShobu = rule?.isIpponShobu ?? false;
  final String shobuDesc = isIpponShobu ? '１本勝負' : '３本勝負 (２本先取)';

  // --- 延長戦・判定 (個人戦または明示設定用) ---
  final bool isEnchoUnlimited = rule?.isEnchoUnlimited ?? false;
  final double enchoMins =
      rule?.enchoTimeMinutes ?? match.extensionTimeMinutes?.toDouble() ?? 0.0;
  final int enchoCount = rule?.enchoCount ?? match.extensionCount ?? 0;
  final bool hasExtension = rule != null
      ? (isEnchoUnlimited || enchoCount > 0)
      : match.hasExtension;

  String enchoDesc = 'なし';
  if (hasExtension) {
    if (isEnchoUnlimited || enchoCount == -2) {
      enchoDesc = 'あり (無制限)';
    } else {
      String extTimeStr = enchoMins == enchoMins.toInt()
          ? '${enchoMins.toInt()}分'
          : '${enchoMins.toInt()}分${((enchoMins % 1) * 60).toInt()}秒';
      final countStr = enchoCount > 0 ? '$enchoCount回' : '1回';
      enchoDesc = 'あり ($extTimeStr・$countStr)';
    }
  }

  final bool hanteiEnabled = rule?.hasHantei ?? match.hasHantei;

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
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Icon(
                  Icons.gavel_rounded,
                  color: themeColors.primaryAccent,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '試合レギュレーション',
                  style: TextStyle(
                    fontSize: AppFontSize.headline,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.textColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            if (rule == null)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppKendoColors.orange.withValues(alpha: 0.1),
                  borderRadius: AppRadius.small,
                  border: Border.all(color: context.appColors.warningColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: context.appColors.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'この試合はアップデート前に作成されたため、詳細なルールが保存されていません。新しく作成した試合では正しく表示されます。',
                        style: TextStyle(
                          color: context.appColors.warningColor,
                          fontSize: AppFontSize.small,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildRuleRow('試合形式', formatText, context),
            _buildRuleRow('勝負形式', shobuDesc, context),
            _buildRuleRow('試合時間', timeDesc, context),

            // === 錬成会 ===
            if (rule?.isRenseikai ?? false) ...[
              _buildSectionHeader('錬成会設定', themeColors.primaryAccent),
              _buildRuleRow('進行方式', rule!.renseikaiType, context),
              if (rule.renseikaiType == '時間制')
                _buildRuleRow('制限時間', '${rule.overallTimeMinutes}分', context),
              if (!isIndividual && rule.positions.isNotEmpty)
                _buildRuleRow('ポジション', rule.positions.join('、'), context),
            ]
            // === 個人戦（トーナメント個人戦） ===
            else if (isIndividual && !isLeague) ...[
              _buildRuleRow('延長戦', enchoDesc, context),
              _buildRuleRow('判定', hanteiEnabled ? 'あり' : 'なし', context),
            ]
            // === リーグ個人戦 ===
            else if (isIndividual && isLeague) ...[
              if (hasExtension) _buildRuleRow('延長戦', enchoDesc, context),
              if (hanteiEnabled) _buildRuleRow('判定', 'あり', context),
              if (rule != null &&
                  (rule.winPoint > 0 ||
                      rule.drawPoint > 0 ||
                      rule.lossPoint > 0)) ...[
                _buildSectionHeader('リーグ勝点設定', themeColors.primaryAccent),
                _buildRuleRow(
                  '勝点配分',
                  '勝: ${rule.winPoint}点 / 分: ${rule.drawPoint}点 / 負: ${rule.lossPoint}点',
                  context,
                ),
              ],
            ]
            // === 勝ち抜き戦 ===
            else if (match.isKachinuki || (rule?.isKachinuki ?? false)) ...[
              _buildSectionHeader('勝ち抜き戦設定', themeColors.primaryAccent),
              _buildRuleRow(
                '無制限条件',
                rule?.kachinukiUnlimitedType ?? '大将対大将',
                context,
              ),
              if (rule != null && rule.positions.isNotEmpty)
                _buildRuleRow('ポジション', rule.positions.join('、'), context),
            ]
            // === 団体戦（トーナメント団体戦） ===
            else if (!isIndividual && !isLeague) ...[
              if (hasExtension) _buildRuleRow('ポジション延長', enchoDesc, context),
              _buildSectionHeader('団体戦・チーム設定', themeColors.primaryAccent),
              _buildRuleRow(
                '代表戦',
                rule != null
                    ? (rule.hasRepresentativeMatch ? 'あり' : 'なし')
                    : 'あり',
                context,
              ),
              if (rule == null || rule.hasRepresentativeMatch) ...[
                _buildRuleRow(
                  '代表戦勝負形式',
                  (rule?.isDaihyoIpponShobu ?? true) ? '１本勝負' : '３本勝負',
                  context,
                ),
                _buildRuleRow(
                  '代表戦時間',
                  (rule?.daihyoMatchTimeMinutes ?? 0.0) == 0.0
                      ? '時間制限なし'
                      : '${rule!.daihyoMatchTimeMinutes.toInt()}分',
                  context,
                ),
                if (rule?.daihyoHasExtension ?? true)
                  _buildRuleRow(
                    '代表戦延長',
                    ((rule?.daihyoEnchoCount ?? -2) == -2 ||
                            (rule?.daihyoEnchoCount ?? -2) == 0)
                        ? 'あり (無制限)'
                        : 'あり (${rule!.daihyoEnchoTimeMinutes.toInt()}分・${rule.daihyoEnchoCount}回)',
                    context,
                  )
                else
                  _buildRuleRow('代表戦延長', 'なし', context),
                if (rule?.daihyoHasHantei ?? false)
                  _buildRuleRow('代表戦判定', 'あり', context),
              ],
              if (rule != null && rule.positions.isNotEmpty)
                _buildRuleRow('ポジション', rule.positions.join('、'), context),
            ]
            // === リーグ団体戦 ===
            else if (!isIndividual && isLeague) ...[
              _buildSectionHeader('リーグ団体戦設定', themeColors.primaryAccent),
              _buildRuleRow(
                '同点時代表戦',
                (rule?.hasLeagueDaihyo ?? false) ? 'あり' : 'なし',
                context,
              ),
              if (rule != null && rule.hasLeagueDaihyo) ...[
                _buildRuleRow(
                  '代表戦勝負形式',
                  rule.isDaihyoIpponShobu ? '１本勝負' : '３本勝負',
                  context,
                ),
                _buildRuleRow(
                  '代表戦時間',
                  rule.daihyoMatchTimeMinutes == 0.0
                      ? '時間制限なし'
                      : '${rule.daihyoMatchTimeMinutes.toInt()}分',
                  context,
                ),
              ],
              if (rule != null &&
                  (rule.winPoint > 0 ||
                      rule.drawPoint > 0 ||
                      rule.lossPoint > 0))
                _buildRuleRow(
                  '勝点配分',
                  '勝: ${rule.winPoint}点 / 分: ${rule.drawPoint}点 / 負: ${rule.lossPoint}点',
                  context,
                ),
              if (rule != null && rule.positions.isNotEmpty)
                _buildRuleRow('ポジション', rule.positions.join('、'), context),
            ],

            if (cleanNote.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildRuleRow('備考・メモ', cleanNote, context),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.separatorColor,
                  foregroundColor: context.appColors.textColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.modernValue,
                  ),
                ),
                child: const Text(
                  '閉じる',
                  style: TextStyle(fontWeight: AppFontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSectionHeader(String title, Color color) {
  return Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
    child: Text(
      title,
      style: TextStyle(
        fontSize: AppFontSize.small,
        fontWeight: AppFontWeight.bold,
        color: color,
      ),
    ),
  );
}

Widget _buildRuleRow(String label, String value, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.bold,
              color: context.appColors.subTextColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppFontSize.bodySmall,
              fontWeight: AppFontWeight.bold,
              color: context.appColors.textColor,
            ),
          ),
        ),
      ],
    ),
  );
}
