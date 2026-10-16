import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// タイムライン・リーグ戦親アコーディオン用の4段目進行状況サマリー帯ボックス
class TimelineLeagueStatusSection extends StatelessWidget {
  final List<MatchModel> groupList;
  final bool allFinished;
  final bool hasInProgress;
  final bool isDark;
  final List<String> ownTeams;

  const TimelineLeagueStatusSection({
    super.key,
    required this.groupList,
    required this.allFinished,
    required this.hasInProgress,
    required this.isDark,
    required this.ownTeams,
  });

  @override
  Widget build(BuildContext context) {
    // 各対戦カード（チーム対抗戦）を特定
    final boutsByMatchup = <String, List<MatchModel>>{};
    for (final m in groupList) {
      final t1 = m.redName.split(':').first.trim();
      final t2 = m.whiteName.split(':').first.trim();
      final matchupName = '$t1 vs $t2';
      boutsByMatchup.putIfAbsent(matchupName, () => []).add(m);
    }

    final totalMatchups = boutsByMatchup.length;
    int finishedCount = 0;
    String? liveMatchupName;
    String? nextMatchupName;

    for (final entry in boutsByMatchup.entries) {
      final bouts = entry.value;
      final isFinished = bouts.every(
        (m) => m.status == 'finished' || m.status == 'approved',
      );
      if (isFinished) {
        finishedCount++;
      } else if (bouts.any((m) => m.status == 'in_progress')) {
        liveMatchupName ??= entry.key;
      } else {
        final t1 = entry.key.split(' vs ').first;
        final t2 = entry.key.split(' vs ').length > 1
            ? entry.key.split(' vs ')[1]
            : '';
        final isOwn = ownTeams.contains(t1) || ownTeams.contains(t2);
        if (isOwn &&
            (nextMatchupName == null || !nextMatchupName.contains('自チーム'))) {
          nextMatchupName = entry.key;
        } else {
          nextMatchupName ??= entry.key;
        }
      }
    }

    // 1. 進行中の対戦がある場合
    if (liveMatchupName != null) {
      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppKendoColors.hansokuRed.withValues(alpha: 0.08),
          borderRadius: AppRadius.sub,
          border: Border.all(
            color: AppKendoColors.hansokuRed.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '🔴 試合中: $liveMatchupName',
                  style: const TextStyle(
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: AppFontWeight.bold,
                    color: AppKendoColors.hansokuRed,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '($finishedCount/$totalMatchups 対戦完了)',
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
                color: AppKendoColors.hansokuRed,
              ),
            ),
          ],
        ),
      );
    }

    // 2. 全対戦終了の場合
    if (allFinished || (totalMatchups > 0 && finishedCount == totalMatchups)) {
      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          borderRadius: AppRadius.sub,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '🏁 リーグ全対戦終了 (全$totalMatchups対戦完了)',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  color: isDark
                      ? const Color(0xFF9E9E9E)
                      : context.appColors.subTextColor,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    }

    // 3. 待機中・次の対戦がある場合
    final targetNext = nextMatchupName ?? '全$totalMatchups対戦';
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.appColors.warningColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.sub,
        border: Border.all(
          color: context.appColors.warningColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '⏳ 次の対戦: $targetNext',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.warningColor,
                ),
                maxLines: 1,
              ),
            ),
          ),
          if (totalMatchups > 0) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              '($finishedCount/$totalMatchups 完了)',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.bold,
                color: context.appColors.warningColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
