import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 試合操作画面用 直近操作ミニログ ＆ Undoボタン（純粋UIコンポーネント）
class MatchMiniLogUndoSection extends StatelessWidget {
  final List<ScoreEvent> validEvents;
  final bool canUndo;
  final bool isDark;
  final VoidCallback onUndo;

  const MatchMiniLogUndoSection({
    super.key,
    required this.validEvents,
    required this.canUndo,
    required this.isDark,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. 直近3件のミニログ表示エリア
        Container(
          height: 62,
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(
            vertical: 2,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                : const Color(0xFFF2F2F7),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.smallValue),
            ),
          ),
          alignment: Alignment.bottomCenter,
          child: validEvents.isNotEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: validEvents.reversed
                      .take(3)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                        final e = entry.value;
                        final isLast = entry.key == 0;
                        final sideColor = e.side == Side.red
                            ? AppKendoColors.hansokuRed
                            : (e.side == Side.white
                                  ? (isDark
                                        ? AppKendoColors.pureWhite
                                        : const Color(0xDE000000))
                                  : AppKendoColors.grey);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            children: [
                              Text(
                                '${validEvents.indexOf(e) + 1}.',
                                style: const TextStyle(
                                  fontSize: AppFontSize.badge,
                                  color: AppKendoColors.grey,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(Icons.circle, size: 8, color: sideColor),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                _formatPointType(e.type),
                                style: TextStyle(
                                  fontSize: AppFontSize.small,
                                  fontWeight: isLast
                                      ? AppFontWeight.black
                                      : AppFontWeight.regular,
                                  color: isLast
                                      ? sideColor
                                      : sideColor.withValues(alpha: 0.7),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('HH:mm:ss').format(e.timestamp),
                                style: const TextStyle(
                                  fontSize: AppFontSize.badge,
                                  color: AppKendoColors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(),
                )
              : const Center(
                  child: Text(
                    '操作履歴',
                    style: TextStyle(
                      color: AppKendoColors.grey,
                      fontSize: AppFontSize.badge,
                      fontWeight: AppFontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
        ),
        // 2. Undoボタン
        InkWell(
          onTap: canUndo
              ? () {
                  HapticFeedback.mediumImpact();
                  onUndo();
                }
              : null,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppRadius.smallValue),
          ),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFFFFFFF).withValues(alpha: 0.15)
                  : context.appColors.cardBackground,
              borderRadius: validEvents.isNotEmpty
                  ? const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.smallValue),
                    )
                  : AppRadius.small,
              border: Border.all(
                color: isDark
                    ? const Color(0xFFFFFFFF).withValues(alpha: 0.24)
                    : context.appColors.separatorColor,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.undo,
                  color: canUndo
                      ? (isDark
                            ? context.appColors.primaryAccent
                            : context.appColors.primaryAccent)
                      : AppKendoColors.grey,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  canUndo ? '１つ前の操作を取り消す' : '操作履歴なし',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: AppFontWeight.black,
                    color: canUndo
                        ? context.appColors.textColor
                        : AppKendoColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatPointType(PointType type) {
    switch (type) {
      case PointType.men:
        return 'メン';
      case PointType.kote:
        return 'コテ';
      case PointType.doIdo:
        return 'ドウ';
      case PointType.tsuki:
        return 'ツキ';
      case PointType.hansoku:
        return '反則';
      case PointType.hantei:
        return '判定';
      default:
        return '判定';
    }
  }
}
