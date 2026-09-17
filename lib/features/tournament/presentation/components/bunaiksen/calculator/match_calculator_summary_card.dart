import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 試合数・終了予定時刻・所要時間のハイライトサマリーカード
class MatchCalculatorSummaryCard extends StatelessWidget {
  final AllocationResult result;
  final CalculatorSettings settings;

  const MatchCalculatorSummaryCard({
    super.key,
    required this.result,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');
    final timeFmt = DateFormat('HH:mm');

    final hours = result.totalEstimatedMinutes ~/ 60;
    final minutes = result.totalEstimatedMinutes % 60;
    final durationText = hours > 0 ? '$hours時間$minutes分' : '$minutes分';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: themeColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: themeColors.primaryAccent.withValues(
            alpha: isDark ? 0.35 : 0.25,
          ),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColors.cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.subValue),
                    decoration: BoxDecoration(
                      color: themeColors.primaryAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      size: 20,
                      color: themeColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '進行シミュレーション概要',
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: AppFontWeight.bold,
                      color: themeColors.textColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: themeColors.subTextColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.full,
                  border: Border.all(
                    color: themeColors.subTextColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  settings.pattern.shortTitle,
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.semiBold,
                    color: themeColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 主要指標3カラム (総試合数 / 所要時間 / 終了見込み)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: '総試合数',
                  value: '${result.totalMatches}',
                  unit: '試合',
                  themeColors: themeColors,
                  textColor: themeColors.infoColor,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: themeColors.separatorColor.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildMetricTile(
                  label: '想定所要時間',
                  value: durationText,
                  unit: '',
                  themeColors: themeColors,
                  textColor: themeColors.successColor,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: themeColors.separatorColor.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildMetricTile(
                  label: '終了予定時刻',
                  value: timeFmt.format(result.estimatedEndTime),
                  unit: '頃',
                  themeColors: themeColors,
                  textColor: themeColors.warningColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // コート別試合数＆終了時刻チップ一覧
          Text(
            '各コートの負荷状況',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.semiBold,
              color: themeColors.subTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (int c = 1; c <= settings.courtCount; c++)
                _buildCourtBadge(
                  courtNumber: c,
                  matchCount: result.getCourtMatchCount(c),
                  endTime: result.getCourtEndTime(c),
                  timeFmt: timeFmt,
                  themeColors: themeColors,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String unit,
    required AppThemeColors themeColors,
    required Color textColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.badge,
            color: themeColors.subTextColor,
            fontWeight: AppFontWeight.medium,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: AppFontSize.headline,
                    fontWeight: AppFontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.xxs),
              Text(
                unit,
                style: TextStyle(
                  fontSize: AppFontSize.badge,
                  color: themeColors.subTextColor,
                  fontWeight: AppFontWeight.semiBold,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCourtBadge({
    required int courtNumber,
    required int matchCount,
    required DateTime? endTime,
    required DateFormat timeFmt,
    required AppThemeColors themeColors,
  }) {
    final endStr = endTime != null ? timeFmt.format(endTime) : '--:--';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: themeColors.subTextColor.withValues(alpha: 0.06),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: themeColors.subTextColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '第$courtNumberコート: ',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: themeColors.textColor,
            ),
          ),
          Text(
            '$matchCount試合 ',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.semiBold,
              color: themeColors.infoColor,
            ),
          ),
          Text(
            '($endStr)',
            style: TextStyle(
              fontSize: AppFontSize.badge,
              color: themeColors.subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
