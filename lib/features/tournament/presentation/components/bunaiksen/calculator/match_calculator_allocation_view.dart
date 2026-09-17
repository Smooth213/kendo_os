import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 🥋 コート別進行タイムライン表示ビュー
class MatchCalculatorAllocationView extends StatefulWidget {
  final AllocationResult result;
  final int courtCount;

  const MatchCalculatorAllocationView({
    super.key,
    required this.result,
    required this.courtCount,
  });

  @override
  State<MatchCalculatorAllocationView> createState() =>
      _MatchCalculatorAllocationViewState();
}

class _MatchCalculatorAllocationViewState
    extends State<MatchCalculatorAllocationView> {
  int _selectedCourt = 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');
    final timeFmt = DateFormat('HH:mm');

    final matchesInCourt = widget.result.courtMatches[_selectedCourt] ?? [];
    final endTime = widget.result.getCourtEndTime(_selectedCourt);
    final endStr = endTime != null ? timeFmt.format(endTime) : '--:--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.view_agenda_rounded,
                  size: 16,
                  color: themeColors.primaryAccent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'コート別試合タイムライン',
                  style: TextStyle(
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                ),
              ],
            ),
            Text(
              '全${widget.result.totalMatches}試合',
              style: TextStyle(
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.semiBold,
                color: themeColors.subTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // コート切替タブ
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(widget.courtCount, (index) {
              final courtNum = index + 1;
              final isSelected = _selectedCourt == courtNum;
              final count = widget.result.getCourtMatchCount(courtNum);

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: AppChoiceChip(
                  label: Text('第$courtNumコート ($count試合)'),
                  selected: isSelected,
                  customSelectedColor: themeColors.primaryAccent,
                  customTextColor: themeColors.onPrimaryAccent,
                  onSelected: (_) {
                    setState(() {
                      _selectedCourt = courtNum;
                    });
                  },
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // 選択中コートのヘッダー状況バー
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: themeColors.subTextColor.withValues(alpha: 0.05),
            borderRadius: AppRadius.medium,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '第$_selectedCourtコート 進行順 (${matchesInCourt.length}試合)',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  fontWeight: AppFontWeight.bold,
                  color: themeColors.textColor,
                ),
              ),
              Text(
                '終了見込: $endStr頃',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  fontWeight: AppFontWeight.semiBold,
                  color: themeColors.infoColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // 試合一覧リスト
        if (matchesInCourt.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: Text(
                'このコートに割り振られた試合はありません',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  color: themeColors.subTextColor,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matchesInCourt.length,
            itemBuilder: (context, idx) {
              final match = matchesInCourt[idx];
              final startStr = timeFmt.format(match.estimatedStart);
              final endStr = timeFmt.format(match.estimatedEnd);

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.subValue),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: themeColors.surface,
                  borderRadius: AppRadius.small,
                  border: Border.all(
                    color: themeColors.subTextColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    // 試合番号バッジ
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: themeColors.subTextColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${match.matchOrder}',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.bold,
                          color: themeColors.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // 試合タイトル & カテゴリ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.subValue,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: themeColors.primaryAccent.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: AppRadius.micro,
                                ),
                                child: Text(
                                  match.categoryName,
                                  style: TextStyle(
                                    fontSize: AppFontSize.badge,
                                    fontWeight: AppFontWeight.bold,
                                    color: themeColors.primaryAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: themeColors.subTextColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: AppRadius.micro,
                                ),
                                child: Text(
                                  CalculatorSettings.formatMinutes(
                                    match.durationMinutes,
                                  ),
                                  style: TextStyle(
                                    fontSize: AppFontSize.nano,
                                    color: themeColors.subTextColor,
                                    fontWeight: AppFontWeight.medium,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.subValue),
                              Expanded(
                                child: Text(
                                  match.matchTitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppFontSize.small,
                                    fontWeight: AppFontWeight.semiBold,
                                    color: themeColors.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            match.pairDescription,
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              color: themeColors.subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 想定時間帯
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: themeColors.cardBackground,
                        borderRadius: AppRadius.tiny,
                        border: Border.all(
                          color: themeColors.subTextColor.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      child: Text(
                        '$startStr ~ $endStr',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontFamily: 'monospace',
                          fontWeight: AppFontWeight.semiBold,
                          color: themeColors.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
