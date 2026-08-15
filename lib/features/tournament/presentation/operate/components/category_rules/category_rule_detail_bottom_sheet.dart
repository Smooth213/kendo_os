import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';

/// 部門別詳細ルール確認ボトムシート（純粋UIコンポーネント）
class CategoryRuleDetailBottomSheet extends StatelessWidget {
  final String categoryName;
  final CategoryRuleSet ruleSet;
  final bool isDark;

  const CategoryRuleDetailBottomSheet({
    super.key,
    required this.categoryName,
    required this.ruleSet,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required String categoryName,
    required CategoryRuleSet ruleSet,
    required bool isDark,
  }) {
    return showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => CategoryRuleDetailBottomSheet(
        categoryName: categoryName,
        ruleSet: ruleSet,
        isDark: isDark,
      ),
    );
  }

  static String _fmtMins(double mins) {
    if (mins <= 0) return '時間制限なし';
    if (mins == mins.toInt()) return '${mins.toInt()}分';
    return '${mins.toInt()}分${((mins % 1) * 60).toInt()}秒';
  }

  Widget _buildDetailRow(
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

  Widget _buildSectionLabel(String label, Color color) {
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

  Widget _buildRuleSection(
    BuildContext context,
    String title,
    MatchRule rule,
    Color accentColor,
    String matchType,
  ) {
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

    String timeDesc =
        '${_fmtMins(rule.matchTimeMinutes)} (${rule.isRunningTime ? "通し/空回し" : "都度ストップ"})';
    String ipponDesc = rule.isIpponShobu ? '１本勝負' : '３本勝負 (２本先取)';

    String enchoDesc;
    if (rule.isEnchoUnlimited) {
      enchoDesc = 'あり (無制限)';
    } else if (rule.enchoCount > 0 || rule.enchoTimeMinutes > 0) {
      enchoDesc =
          'あり (${_fmtMins(rule.enchoTimeMinutes)}・${rule.enchoCount > 0 ? rule.enchoCount : 1}回)';
    } else {
      enchoDesc = 'なし';
    }

    String hanteiDesc = rule.hasHantei ? 'あり' : 'なし';

    String daihyoEnchoDesc;
    if (!rule.daihyoHasExtension) {
      daihyoEnchoDesc = 'なし';
    } else if (rule.daihyoEnchoCount == -2 || rule.daihyoEnchoCount == 0) {
      daihyoEnchoDesc = 'あり (無制限)';
    } else {
      daihyoEnchoDesc =
          'あり (${_fmtMins(rule.daihyoEnchoTimeMinutes)}・${rule.daihyoEnchoCount}回)';
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
        _buildDetailRow(context, '試合形式', formatText, isDark),
        _buildDetailRow(
          context,
          isRenseikai ? '1対戦の時間' : '試合時間',
          timeDesc,
          isDark,
        ),

        // 錬成会設定
        if (isRenseikai) ...[
          _buildSectionLabel('錬成会設定', accentColor),
          _buildDetailRow(context, '進行方式', rule.renseikaiType, isDark),
          if (rule.renseikaiType == '時間制')
            _buildDetailRow(
              context,
              '制限時間',
              '${rule.overallTimeMinutes}分',
              isDark,
            ),
        ],

        // 試合ルール（個人戦のみ延長・判定を表示）
        if (!isRenseikai) ...[
          _buildSectionLabel('試合ルール', accentColor),
          _buildDetailRow(context, '勝負方式', ipponDesc, isDark),
          if (!isTeam) ...[
            _buildDetailRow(context, '延長戦', enchoDesc, isDark),
            _buildDetailRow(context, '判定', hanteiDesc, isDark),
          ],
        ],

        // 勝ち抜き戦設定
        if (isKachinuki) ...[
          _buildSectionLabel('勝ち抜き戦設定', accentColor),
          _buildDetailRow(
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
          _buildSectionLabel('団体戦・チーム設定', accentColor),
          _buildDetailRow(
            context,
            '代表戦',
            rule.hasRepresentativeMatch ? 'あり' : 'なし',
            isDark,
          ),
          if (rule.hasRepresentativeMatch) ...[
            _buildDetailRow(
              context,
              '代表戦勝負形式',
              rule.isDaihyoIpponShobu ? '１本勝負' : '３本勝負',
              isDark,
            ),
            _buildDetailRow(
              context,
              '代表戦時間',
              rule.daihyoMatchTimeMinutes <= 0
                  ? '時間制限なし'
                  : _fmtMins(rule.daihyoMatchTimeMinutes),
              isDark,
            ),
            _buildDetailRow(context, '代表戦延長', daihyoEnchoDesc, isDark),
            if (rule.daihyoHasHantei)
              _buildDetailRow(context, '代表戦判定', 'あり', isDark),
          ],
        ],

        // リーグ戦設定
        if (isLeague) ...[
          _buildSectionLabel('リーグ戦設定', AppKendoColors.orange),
          _buildDetailRow(
            context,
            '勝点配分',
            '勝: ${rule.winPoint}点 / 分: ${rule.drawPoint}点 / 負: ${rule.lossPoint}点',
            isDark,
          ),
          if (matchType == 'リーグ団体戦') ...[
            _buildDetailRow(
              context,
              '同点時代表戦',
              rule.hasLeagueDaihyo ? 'あり' : 'なし',
              isDark,
            ),
            if (rule.hasLeagueDaihyo) ...[
              _buildDetailRow(
                context,
                '代表戦時間',
                rule.daihyoMatchTimeMinutes <= 0
                    ? '時間制限なし'
                    : _fmtMins(rule.daihyoMatchTimeMinutes),
                isDark,
              ),
              _buildDetailRow(context, '代表戦延長', daihyoEnchoDesc, isDark),
              if (rule.daihyoHasHantei)
                _buildDetailRow(context, '代表戦判定', 'あり', isDark),
            ],
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        final List<Widget> sections = [];

        if (ruleSet.isMultiScene) {
          if (ruleSet.useRenseikaiRule) {
            sections.add(
              _buildRuleSection(
                context,
                '⚔️ 錬成会ルール',
                ruleSet.renseikaiRule,
                AppKendoColors.ipponGold,
                '錬成会',
              ),
            );
          }
          if (ruleSet.useHonsenRule) {
            if (sections.isNotEmpty) {
              sections.add(const Divider(height: 32));
            }
            sections.add(
              _buildRuleSection(
                context,
                '🏆 本戦ルール',
                ruleSet.normalRule,
                const Color(0xFF3F51B5),
                ruleSet.matchType,
              ),
            );
          }
          if (ruleSet.useMoushiawaseRule) {
            if (sections.isNotEmpty) {
              sections.add(const Divider(height: 32));
            }
            sections.add(
              _buildRuleSection(
                context,
                '🤝 申し合わせルール',
                ruleSet.moushiawaseRule,
                const Color(0xFF009688),
                '錬成会',
              ),
            );
          }
        } else {
          sections.add(
            _buildRuleSection(
              context,
              '通常戦ルール',
              ruleSet.normalRule,
              themeColors.primaryAccent,
              ruleSet.matchType,
            ),
          );

          if (ruleSet.useAdvancedRule) {
            sections.add(const SizedBox(height: AppSpacing.sm));
            sections.add(const Divider());
            sections.add(
              _buildRuleSection(
                context,
                '上位戦（準決勝・決勝等）ルール',
                ruleSet.advancedRule,
                AppKendoColors.teal,
                ruleSet.matchType,
              ),
            );
            sections.add(const SizedBox(height: AppSpacing.sm));
            sections.add(
              _buildDetailRow(
                context,
                '上位戦 適用ワード',
                ruleSet.advancedKeywords.join('、'),
                isDark,
              ),
            );
          }
        }

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: AppSpacing.roundValue),
                  decoration: BoxDecoration(
                    color: const Color(0x8A000000),
                    borderRadius: AppRadius.medium,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.gavel_rounded,
                    color: themeColors.primaryAccent,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '$categoryName のルール設定',
                      style: TextStyle(
                        fontSize: AppFontSize.headline,
                        fontWeight: AppFontWeight.bold,
                        color: context.appColors.textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              ...sections,

              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.separatorColor,
                    foregroundColor: context.appColors.textColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                  child: const Text(
                    '閉じる',
                    style: TextStyle(fontWeight: AppFontWeight.semiBold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
