import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// ルール概要カード：1ルールセクション（通常戦・上位戦・錬成等）の内容を表示する
/// [CategoryRuleDetailBottomSheet] から分離された UIコンポーネント。
class CategoryRuleSummaryCard extends StatelessWidget {
  final String title;
  final MatchRule rule;
  final Color accentColor;
  final String matchType;
  final bool isDark;

  const CategoryRuleSummaryCard({
    super.key,
    required this.title,
    required this.rule,
    required this.accentColor,
    required this.matchType,
    required this.isDark,
  });

  static String fmtMins(double mins) {
    if (mins <= 0) return '時間制限なし';
    if (mins == mins.toInt()) return '${mins.toInt()}分';
    return '${mins.toInt()}分${((mins % 1) * 60).toInt()}秒';
  }

  static Widget buildDetailRow(
    BuildContext context,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.subValue),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: AppFontWeight.semiBold,
                fontSize: AppFontSize.bodySmall,
                color: AppKendoColors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: context.appColors.subTextColor,
                fontWeight: AppFontWeight.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildSectionLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppFontSize.small,
          fontWeight: AppFontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTeam =
        matchType == '団体戦' ||
        matchType == '勝ち抜き戦' ||
        matchType == 'リーグ団体戦' ||
        matchType == '錬成会';
    final bool isLeague = matchType == 'リーグ団体戦' || matchType == 'リーグ個人戦';
    final bool isKachinuki = matchType == '勝ち抜き戦';
    final bool isRenseikai = matchType == '錬成会' || (rule.isRenseikai);

    String formatText;
    if (isRenseikai) {
      formatText = '錬成会';
    } else if (isKachinuki) {
      formatText = '勝ち抜き戦';
    } else if (matchType == 'リーグ団体戦') {
      formatText = 'リーグ戦（団体）';
    } else if (matchType == 'リーグ個人戦') {
      formatText = 'リーグ戦（個人）';
    } else if (matchType == '団体戦') {
      formatText = '団体戦';
    } else {
      formatText = '個人戦';
    }

    final timeDesc =
        '${fmtMins(rule.matchTimeMinutes)} (${rule.isRunningTime ? "通し/空回し" : "都度ストップ"})';
    final ipponDesc = rule.isIpponShobu ? '１本勝負' : '３本勝負 (２本先取)';

    String enchoDesc;
    if (rule.isEnchoUnlimited) {
      enchoDesc = 'あり (無制限)';
    } else if (rule.enchoCount > 0 || rule.enchoTimeMinutes > 0) {
      enchoDesc =
          'あり (${fmtMins(rule.enchoTimeMinutes)}・${rule.enchoCount > 0 ? rule.enchoCount : 1}回)';
    } else {
      enchoDesc = 'なし';
    }

    final hanteiDesc = rule.hasHantei ? 'あり' : 'なし';

    String daihyoEnchoDesc;
    if (!rule.daihyoHasExtension) {
      daihyoEnchoDesc = 'なし';
    } else if (rule.daihyoEnchoCount == -2 || rule.daihyoEnchoCount == 0) {
      daihyoEnchoDesc = 'あり (無制限)';
    } else {
      daihyoEnchoDesc =
          'あり (${fmtMins(rule.daihyoEnchoTimeMinutes)}・${rule.daihyoEnchoCount}回)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: AppRadius.micro,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppFontSize.bodyMedium,
                  fontWeight: AppFontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),

        // 試合基本情報
        buildDetailRow(context, '試合形式', formatText, isDark),
        buildDetailRow(
          context,
          isRenseikai ? '1対戦の時間' : '試合時間',
          timeDesc,
          isDark,
        ),

        // 錬成会設定
        if (isRenseikai) ...[
          buildSectionLabel('錬成会設定', accentColor),
          buildDetailRow(context, '進行方式', rule.renseikaiType, isDark),
          if (rule.renseikaiType == '時間制')
            buildDetailRow(
              context,
              '制限時間',
              '${rule.overallTimeMinutes}分',
              isDark,
            ),
        ],

        // 試合ルール（個人戦のみ延長・判定を表示）
        if (!isRenseikai) ...[
          buildSectionLabel('試合ルール', accentColor),
          buildDetailRow(context, '勝負方式', ipponDesc, isDark),
          if (!isTeam) ...[
            buildDetailRow(context, '延長戦', enchoDesc, isDark),
            buildDetailRow(context, '判定', hanteiDesc, isDark),
          ],
        ],

        // 勝ち抜き戦設定
        if (isKachinuki) ...[
          buildSectionLabel('勝ち抜き戦設定', accentColor),
          buildDetailRow(
            context,
            '無制限条件',
            rule.kachinukiUnlimitedType.isEmpty
                ? '大将対大将'
                : rule.kachinukiUnlimitedType,
            isDark,
          ),
        ],

        // 団体戦・チーム設定
        if (matchType == '団体戦') ...[
          buildSectionLabel('団体戦・チーム設定', accentColor),
          buildDetailRow(
            context,
            '代表戦',
            rule.hasRepresentativeMatch ? 'あり' : 'なし',
            isDark,
          ),
          if (rule.hasRepresentativeMatch) ...[
            buildDetailRow(
              context,
              '代表戦勝負形式',
              rule.isDaihyoIpponShobu ? '１本勝負' : '３本勝負',
              isDark,
            ),
            buildDetailRow(
              context,
              '代表戦時間',
              rule.daihyoMatchTimeMinutes <= 0
                  ? '時間制限なし'
                  : fmtMins(rule.daihyoMatchTimeMinutes),
              isDark,
            ),
            buildDetailRow(context, '代表戦延長', daihyoEnchoDesc, isDark),
            if (rule.daihyoHasHantei)
              buildDetailRow(context, '代表戦判定', 'あり', isDark),
          ],
        ],

        // リーグ戦設定
        if (isLeague) ...[
          buildSectionLabel('リーグ戦設定', AppKendoColors.orange),
          buildDetailRow(
            context,
            '勝点配分',
            '勝: ${rule.winPoint}点 / 分: ${rule.drawPoint}点 / 負: ${rule.lossPoint}点',
            isDark,
          ),
          if (matchType == 'リーグ団体戦') ...[
            buildDetailRow(
              context,
              '同点時代表戦',
              rule.hasLeagueDaihyo ? 'あり' : 'なし',
              isDark,
            ),
            if (rule.hasLeagueDaihyo) ...[
              buildDetailRow(
                context,
                '代表戦時間',
                rule.daihyoMatchTimeMinutes <= 0
                    ? '時間制限なし'
                    : fmtMins(rule.daihyoMatchTimeMinutes),
                isDark,
              ),
              buildDetailRow(context, '代表戦延長', daihyoEnchoDesc, isDark),
              if (rule.daihyoHasHantei)
                buildDetailRow(context, '代表戦判定', 'あり', isDark),
            ],
          ],
        ],
      ],
    );
  }
}
