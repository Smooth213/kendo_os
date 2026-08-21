import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_option_card.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 現在適用中のルール詳細プレビューカード
class MatchFormatRuleSummaryCard extends StatelessWidget {
  final String displayRuleName;
  final bool isAdvanced;
  final AppThemeColors themeColors;
  final bool isRenseikai;
  final String renseikaiType;
  final double matchTime;
  final String overallTimeMinutes;
  final String matchType;
  final bool isRunningTime;
  final bool isIpponShobu;
  final int ipponLimit;
  final int hansokuLimit;
  final String extensionText;
  final bool hasHantei;
  final String kachinukiUnlimitedType;
  final bool hasLeagueDaihyo;
  final bool isDaihyoIpponShobu;
  final double daihyoMatchTime;
  final bool daihyoHasExtension;
  final double daihyoEnchoTime;
  final int daihyoEnchoCount;
  final bool daihyoHasHantei;
  final double winPoint;
  final double lossPoint;
  final double drawPoint;
  final String Function(double) formatMinutesText;
  final Widget Function(String, Color) buildSectionHeader;

  const MatchFormatRuleSummaryCard({
    super.key,
    required this.displayRuleName,
    required this.isAdvanced,
    required this.themeColors,
    required this.isRenseikai,
    required this.renseikaiType,
    required this.matchTime,
    required this.overallTimeMinutes,
    required this.matchType,
    required this.isRunningTime,
    required this.isIpponShobu,
    required this.ipponLimit,
    required this.hansokuLimit,
    required this.extensionText,
    required this.hasHantei,
    required this.kachinukiUnlimitedType,
    required this.hasLeagueDaihyo,
    required this.isDaihyoIpponShobu,
    required this.daihyoMatchTime,
    required this.daihyoHasExtension,
    required this.daihyoEnchoTime,
    required this.daihyoEnchoCount,
    required this.daihyoHasHantei,
    required this.winPoint,
    required this.lossPoint,
    required this.drawPoint,
    required this.formatMinutesText,
    required this.buildSectionHeader,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor = isAdvanced
        ? AppKendoColors.teal
        : themeColors.primaryAccent;

    return MatchFormatOptionCard(
      title: '現在適用中のルール: $displayRuleName',
      icon: isAdvanced ? Icons.stars : Icons.gavel,
      color: isAdvanced ? AppKendoColors.teal : themeColors.primaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 錬成会設定 ───
          if (isRenseikai) ...[
            buildSectionHeader('錬成会設定', headerColor),
            SetupReadOnlyRuleRow(
              label: '進行方式',
              value: renseikaiType,
              accentColor: headerColor,
            ),
            SetupReadOnlyRuleRow(
              label: '1対戦の時間',
              value: formatMinutesText(matchTime),
              accentColor: headerColor,
            ),
            if (renseikaiType == '時間制')
              SetupReadOnlyRuleRow(
                label: '全体の制限時間',
                value: '$overallTimeMinutes分',
                accentColor: headerColor,
              ),
          ],

          // ─── 試合ルール（錬成会以外） ───
          if (!isRenseikai) ...[
            buildSectionHeader('試合ルール', headerColor),
            SetupReadOnlyRuleRow(
              label: '試合方式',
              value: matchType,
              accentColor: headerColor,
            ),
            SetupReadOnlyRuleRow(
              label: '試合時間',
              value:
                  '${formatMinutesText(matchTime)} (${isRunningTime ? "ランニング計測" : "通常計測"})',
              accentColor: headerColor,
            ),
            SetupReadOnlyRuleRow(
              label: '勝負方式',
              value: isIpponShobu ? '一本勝負' : '三本勝負 ($ipponLimit本先取)',
              accentColor: headerColor,
            ),
            SetupReadOnlyRuleRow(
              label: '反則',
              value: '$hansokuLimit反則で負け',
              accentColor: headerColor,
            ),
            SetupReadOnlyRuleRow(
              label: '延長戦',
              value: extensionText,
              accentColor: headerColor,
            ),
            SetupReadOnlyRuleRow(
              label: '判定',
              value: hasHantei ? '引き分け時に判定あり' : 'なし',
              accentColor: headerColor,
            ),
          ],

          // ─── 勝ち抜き戦設定 ───
          if (matchType == '勝ち抜き戦') ...[
            buildSectionHeader('勝ち抜き戦設定', headerColor),
            SetupReadOnlyRuleRow(
              label: '大将VS大将',
              value:
                  (kachinukiUnlimitedType == 'なし' ||
                      kachinukiUnlimitedType.isEmpty)
                  ? '引き分け'
                  : '延長戦を行う',
              accentColor: headerColor,
            ),
            SetupReadOnlyRuleRow(
              label: '大将VS他ポジション',
              value: kachinukiUnlimitedType == '無制限' ? '延長戦を行う' : '引き分け',
              accentColor: headerColor,
            ),
          ],

          // ─── 団体戦・チーム設定（通常団体戦のみ） ───
          if (matchType == '団体戦') ...[
            buildSectionHeader('団体戦・チーム設定', headerColor),
            SetupReadOnlyRuleRow(
              label: '代表戦',
              value: hasLeagueDaihyo
                  ? 'あり (${isDaihyoIpponShobu ? "一本勝負" : "三本勝負"})'
                  : 'なし',
              accentColor: headerColor,
            ),
          ],

          // ─── 代表戦設定（通常団体戦の代表戦ありのみ） ───
          if (matchType == '団体戦' && hasLeagueDaihyo) ...[
            buildSectionHeader('代表戦設定', headerColor),
            SetupReadOnlyRuleRow(
              label: '代表戦 時間',
              value: daihyoMatchTime <= 0
                  ? '無制限'
                  : formatMinutesText(daihyoMatchTime),
              accentColor: headerColor,
            ),
            SetupReadOnlyRuleRow(
              label: '代表戦 延長戦',
              value: !daihyoHasExtension
                  ? 'なし'
                  : (daihyoEnchoCount == -2
                        ? 'あり (無制限)'
                        : 'あり (${formatMinutesText(daihyoEnchoTime)}・$daihyoEnchoCount回)'),
              accentColor: headerColor,
            ),
            SetupReadOnlyRuleRow(
              label: '代表戦 判定',
              value: daihyoHasHantei ? 'あり' : 'なし',
              accentColor: headerColor,
            ),
          ],

          // ─── リーグ戦設定 ───
          if (matchType.contains('リーグ')) ...[
            buildSectionHeader('リーグ戦設定', AppKendoColors.orange),
            SetupReadOnlyRuleRow(
              label: '勝ち点',
              value: '勝: $winPoint点 / 負: $lossPoint点 / 分: $drawPoint点',
              accentColor: AppKendoColors.orange,
            ),
            if (matchType == 'リーグ団体戦') ...[
              SetupReadOnlyRuleRow(
                label: '同点代表戦',
                value: hasLeagueDaihyo ? 'あり' : 'なし',
                accentColor: AppKendoColors.orange,
              ),
              if (hasLeagueDaihyo) ...[
                SetupReadOnlyRuleRow(
                  label: '代表戦 時間',
                  value: daihyoMatchTime <= 0
                      ? '無制限'
                      : formatMinutesText(daihyoMatchTime),
                  accentColor: AppKendoColors.orange,
                ),
                SetupReadOnlyRuleRow(
                  label: '代表戦 延長戦',
                  value: !daihyoHasExtension
                      ? 'なし'
                      : (daihyoEnchoCount == -2
                            ? 'あり (無制限)'
                            : 'あり (${formatMinutesText(daihyoEnchoTime)}・$daihyoEnchoCount回)'),
                  accentColor: AppKendoColors.orange,
                ),
                SetupReadOnlyRuleRow(
                  label: '代表戦 判定',
                  value: daihyoHasHantei ? 'あり' : 'なし',
                  accentColor: AppKendoColors.orange,
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
