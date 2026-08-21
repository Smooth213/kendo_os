import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_score_marks.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 部内戦画面の個別試合カード（スワイプ編集・削除対応）
class BunaiksenMatchCard extends StatelessWidget {
  final MatchModel match;
  final int index;
  final String dateId;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEditNote;
  final VoidCallback onDelete;

  const BunaiksenMatchCard({
    super.key,
    required this.match,
    required this.index,
    required this.dateId,
    required this.isDark,
    required this.onTap,
    required this.onEditNote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasScore =
        match.redScore > 0 || match.whiteScore > 0 || match.events.isNotEmpty;
    final isPlaying = match.status == 'in_progress';
    final isFinished =
        (match.status == 'finished' ||
            match.status == 'approved' ||
            hasScore) &&
        !isPlaying;

    final Color bg = isFinished
        ? (isDark ? const Color(0xFF161618) : const Color(0xFFF2F2F7))
        : (isDark ? const Color(0xFF1C1C1E) : context.appColors.textColor);
    final Color textC = isFinished
        ? (isDark
              ? context.appColors.subTextColor
              : context.appColors.subTextColor)
        : (context.appColors.textColor);
    final Color noteC = isFinished
        ? (isDark ? const Color(0xFFFFFFFF) : context.appColors.subTextColor)
        : AppKendoColors.grey;

    final Color badgeBg = isPlaying
        ? const Color(0xFF2196F3)
        : (isFinished
              ? (isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0))
              : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEEEE)));

    final Color badgeText = isPlaying
        ? AppKendoColors.pureWhite
        : (isFinished
              ? (isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575))
              : (isDark ? const Color(0xFFBDBDBD) : const Color(0xFF616161)));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Slidable(
        key: ValueKey(match.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onEditNote(),
              backgroundColor: AppKendoColors.blueAccent,
              foregroundColor: AppKendoColors.pureWhite,
              icon: Icons.edit,
              label: '編集',
            ),
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppKendoColors.redAccent,
              foregroundColor: AppKendoColors.pureWhite,
              icon: Icons.delete,
              label: '削除',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(AppRadius.largeValue),
              ),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.large,
            side: BorderSide(
              color: isDark
                  ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                  : const Color(0xFF000000).withValues(alpha: 0.05),
            ),
          ),
          child: InkWell(
            borderRadius: AppRadius.large,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          match.note.isNotEmpty ? match.note : '部内稽古',
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: noteC,
                            fontWeight: AppFontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.subValue,
                          vertical: AppSpacing.xxs,
                        ),
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: AppRadius.tiny,
                        ),
                        child: Text(
                          isPlaying ? '進行中' : (isFinished ? '終了' : '待機中'),
                          style: TextStyle(
                            fontSize: AppFontSize.badge,
                            fontWeight: AppFontWeight.bold,
                            color: badgeText,
                          ),
                        ),
                      ),
                      Text(
                        '第${index + 1}試合',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: noteC,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.redName,
                          style: TextStyle(
                            fontSize: AppFontSize.subhead,
                            fontWeight: AppFontWeight.bold,
                            color: textC,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: isFinished
                            ? BunaiksenScoreMarks(
                                match: match,
                                isDark: isDark,
                                isFinished: isFinished,
                              )
                            : Text(
                                'VS',
                                style: TextStyle(
                                  fontSize: AppFontSize.subhead,
                                  fontWeight: AppFontWeight.bold,
                                  color: textC,
                                ),
                              ),
                      ),
                      Expanded(
                        child: Text(
                          match.whiteName,
                          style: TextStyle(
                            fontSize: AppFontSize.subhead,
                            fontWeight: AppFontWeight.bold,
                            color: textC,
                          ),
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
