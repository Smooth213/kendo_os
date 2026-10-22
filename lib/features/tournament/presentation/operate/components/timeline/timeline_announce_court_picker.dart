import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_court_slot_picker.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 アナウンス用の試合会場・試合順設定Picker（変更前 ➔ 変更先の段階的展開対応）
class TimelineAnnounceCourtPicker extends StatelessWidget {
  final int? fromCourt;
  final int? fromOrder;
  final int? toCourt;
  final int? toOrder;
  final bool hasDestination;
  final ValueChanged<int?> onFromCourtChanged;
  final ValueChanged<int?> onFromOrderChanged;
  final ValueChanged<int?> onToCourtChanged;
  final ValueChanged<int?> onToOrderChanged;
  final VoidCallback onToggleDestination;
  final VoidCallback onClearAll;
  final bool isDark;

  const TimelineAnnounceCourtPicker({
    super.key,
    required this.fromCourt,
    required this.fromOrder,
    required this.toCourt,
    required this.toOrder,
    required this.hasDestination,
    required this.onFromCourtChanged,
    required this.onFromOrderChanged,
    required this.onToCourtChanged,
    required this.onToOrderChanged,
    required this.onToggleDestination,
    required this.onClearAll,
    required this.isDark,
  });

  /// 選択中の設定からフォーマット文字列を生成
  static String formatHeading({
    required int? fromCourt,
    required int? fromOrder,
    required int? toCourt,
    required int? toOrder,
    required bool hasDestination,
  }) {
    final fromParts = <String>[];
    if (fromCourt != null && fromCourt > 0) fromParts.add('第$fromCourt試合場');
    if (fromOrder != null && fromOrder > 0) fromParts.add('$fromOrder試合目');
    final fromText = fromParts.join(' ');

    if (!hasDestination) return fromText;

    final toParts = <String>[];
    if (toCourt != null && toCourt > 0) toParts.add('第$toCourt試合場');
    if (toOrder != null && toOrder > 0) toParts.add('$toOrder試合目');
    final toText = toParts.join(' ');

    if (fromText.isEmpty && toText.isEmpty) return '';
    if (fromText.isEmpty) return toText;
    if (toText.isEmpty) return fromText;
    return '$fromText ➔ $toText';
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;
    final cardBgColor = isDark
        ? const Color(0xFF242426)
        : themeColors.primaryAccent.withValues(alpha: 0.05);
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : themeColors.primaryAccent.withValues(alpha: 0.2);

    final hasAnyValue =
        fromCourt != null ||
        fromOrder != null ||
        toCourt != null ||
        toOrder != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: AppRadius.large,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ヘッダー行
          Row(
            children: [
              Icon(Icons.stadium, size: 16, color: themeColors.primaryAccent),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  hasDestination ? '試合場・試合順の変更（元 ➔ 先）' : '試合場・試合順の入力補助',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.textColor,
                  ),
                ),
              ),
              if (hasAnyValue)
                InkWell(
                  onTap: onClearAll,
                  borderRadius: AppRadius.small,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.clear,
                          size: 14,
                          color: context.appColors.subTextColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'リセット',
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: context.appColors.subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // 変更元（または基本の試合場・試合順）Picker
          if (hasDestination) ...[
            Text(
              '【変更元】',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
                color: themeColors.primaryAccent,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
          ],
          MatchCourtSlotPicker(
            courtNumber: fromCourt,
            matchOrder: fromOrder,
            onCourtNumberChanged: onFromCourtChanged,
            onMatchOrderChanged: onFromOrderChanged,
            isDark: isDark,
          ),

          // アニメーション展開: 変更先スロット
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: hasDestination
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppKendoColors.amber.withValues(
                          alpha: isDark ? 0.25 : 0.15,
                        ),
                        borderRadius: AppRadius.small,
                        border: Border.all(
                          color: AppKendoColors.amber.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.arrow_downward,
                            size: 14,
                            color: AppKendoColors.amber,
                          ),
                          SizedBox(width: AppSpacing.xxs),
                          Text(
                            '変更先へ移動（➔）',
                            style: TextStyle(
                              fontSize: AppFontSize.micro,
                              fontWeight: AppFontWeight.bold,
                              color: AppKendoColors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '【変更先】',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: AppKendoColors.amber,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                MatchCourtSlotPicker(
                  courtNumber: toCourt,
                  matchOrder: toOrder,
                  onCourtNumberChanged: onToCourtChanged,
                  onMatchOrderChanged: onToOrderChanged,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 変更先トグルボタン行
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                key: const Key('timeline_toggle_destination_button'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onToggleDestination,
                icon: Icon(
                  hasDestination
                      ? Icons.close_rounded
                      : Icons.arrow_forward_rounded,
                  size: 14,
                  color: hasDestination
                      ? context.appColors.errorColor
                      : themeColors.primaryAccent,
                ),
                label: Text(
                  hasDestination ? '変更先を取り消す' : '＋ 変更先（➔）を指定',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: hasDestination
                        ? context.appColors.errorColor
                        : themeColors.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
