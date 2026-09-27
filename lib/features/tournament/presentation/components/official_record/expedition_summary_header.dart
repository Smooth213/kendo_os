import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/application/services/line_summary_formatter.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 遠征サマリーカードのタイトル・LINE共有・開閉トグルを含むヘッダー行
class ExpeditionSummaryHeader extends StatelessWidget {
  final bool isCardExpanded;
  final bool isDark;
  final AppThemeColors themeColors;
  final String selectedSummaryTeam;
  final List<MatchModel> matches;
  final VoidCallback onToggleExpand;
  final Future<void> Function(String text, String subject, Rect? origin)?
  onShare;

  const ExpeditionSummaryHeader({
    super.key,
    required this.isCardExpanded,
    required this.isDark,
    required this.themeColors,
    required this.selectedSummaryTeam,
    required this.matches,
    required this.onToggleExpand,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggleExpand,
      borderRadius: AppRadius.medium,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.analytics_outlined,
                    color: AppKendoColors.indigo,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    '成績サマリー',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            Builder(
              builder: (buttonContext) {
                return InkWell(
                  onTap: () async {
                    final title = selectedSummaryTeam == '全体'
                        ? '遠征・試合'
                        : selectedSummaryTeam;
                    final text = LineSummaryFormatter.formatExpeditionSummary(
                      title: title,
                      matches: matches,
                    );

                    final box = buttonContext.findRenderObject() as RenderBox?;
                    final origin = box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null;

                    await Clipboard.setData(ClipboardData(text: text));

                    if (onShare != null) {
                      await onShare!(text, '【$title 結果速報】', origin);
                    } else {
                      await SharePlus.instance.share(
                        ShareParams(
                          text: text,
                          subject: '【$title 結果速報】',
                          sharePositionOrigin: origin,
                        ),
                      );
                    }
                  },
                  borderRadius: AppRadius.round,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06C755).withValues(alpha: 0.15),
                      borderRadius: AppRadius.round,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.share_rounded,
                          size: 13,
                          color: Color(0xFF06C755),
                        ),
                        SizedBox(width: AppSpacing.xxs),
                        Text(
                          'LINE・共有',
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.bold,
                            color: Color(0xFF06C755),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              key: const Key('btn_toggle_expedition_summary'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF38383A)
                    : themeColors.softAccent,
                borderRadius: AppRadius.round,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCardExpanded ? '閉じる' : '開く',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.bold,
                      color: isDark
                          ? const Color(0xFFFFFFFF)
                          : context.appColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    isCardExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : context.appColors.primaryAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
