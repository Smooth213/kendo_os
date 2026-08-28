import 'package:intl/intl.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

/// 【Phase 4: 保護者連絡】遠征・試合結果をLINE送信用に美しく整形するフォーマッター
class LineSummaryFormatter {
  static String formatExpeditionSummary({
    required String title,
    required List<MatchModel> matches,
    DateTime? date,
  }) {
    final targetDate = date ?? DateTime.now();
    final dateStr = DateFormat('yyyy/MM/dd (E)', 'ja').format(targetDate);

    final buffer = StringBuffer();
    buffer.writeln('【$title 結果速報】');
    buffer.writeln('📅 $dateStr');
    buffer.writeln('━━━━━━━━━━━━━━');

    // 団体戦と個人戦のグループ分け
    final Map<String, List<MatchModel>> teamGroupMap = {};
    final List<MatchModel> individualMatches = [];

    for (final m in matches) {
      final bool isTeam =
          (m.groupName != null && m.groupName!.isNotEmpty) ||
          m.isKachinuki ||
          m.matchType.contains('団体') ||
          m.matchType == '先鋒' ||
          m.matchType == '次鋒' ||
          m.matchType == '中堅' ||
          m.matchType == '副将' ||
          m.matchType == '大将' ||
          m.matchType == '代表戦';

      if (isTeam) {
        final key = (m.groupName != null && m.groupName!.isNotEmpty)
            ? m.groupName!
            : m.id;
        teamGroupMap.putIfAbsent(key, () => []).add(m);
      } else {
        individualMatches.add(m);
      }
    }

    int matchIndex = 1;
    int totalWins = 0;
    int totalLosses = 0;
    int totalDraws = 0;

    // 🥋 団体戦セクション
    if (teamGroupMap.isNotEmpty) {
      buffer.writeln('【団体戦】');

      for (final entry in teamGroupMap.entries) {
        final groupMatches = entry.value
          ..sort((a, b) => a.order.compareTo(b.order));
        final firstMatch = groupMatches.first;

        final redTeam = firstMatch.redName.contains(':')
            ? firstMatch.redName.split(':').first.trim()
            : firstMatch.redName;
        final whiteTeam = firstMatch.whiteName.contains(':')
            ? firstMatch.whiteName.split(':').first.trim()
            : firstMatch.whiteName;

        int redWins = 0;
        int whiteWins = 0;
        int redPoints = 0;
        int whitePoints = 0;

        for (final m in groupMatches) {
          redPoints += m.redScore;
          whitePoints += m.whiteScore;

          if (m.redScore > m.whiteScore) {
            redWins++;
          } else if (m.whiteScore > m.redScore) {
            whiteWins++;
          }
        }

        String mark = '△';
        if (redWins > whiteWins) {
          mark = '○';
        } else if (whiteWins > redWins) {
          mark = '●';
        } else {
          if (redPoints > whitePoints) {
            mark = '○';
          } else if (whitePoints > redPoints) {
            mark = '●';
          } else {
            mark = '△';
          }
        }

        if (mark == '○') {
          totalWins++;
        } else if (mark == '●') {
          totalLosses++;
        } else {
          totalDraws++;
        }

        if (groupMatches.length > 1) {
          buffer.writeln(
            '第$matchIndex試合: $mark $redTeam $redWins($redPoints) - $whiteWins($whitePoints) $whiteTeam',
          );
        } else {
          buffer.writeln(
            '第$matchIndex試合: $mark ${firstMatch.redName} ${firstMatch.redScore} - ${firstMatch.whiteScore} ${firstMatch.whiteName}',
          );
        }
        matchIndex++;
      }
    }

    // ⚔️ 個人戦セクション
    if (individualMatches.isNotEmpty) {
      buffer.writeln('【個人戦】');
      int indIndex = 1;
      for (final m in individualMatches) {
        String mark = '△';
        if (m.redScore > m.whiteScore) {
          mark = '○';
          totalWins++;
        } else if (m.whiteScore > m.redScore) {
          mark = '●';
          totalLosses++;
        } else {
          totalDraws++;
        }

        buffer.writeln(
          '第$indIndex試合: $mark ${m.redName} ${m.redScore} - ${m.whiteScore} ${m.whiteName}',
        );
        indIndex++;
      }
    }

    // 選手別取得本数の集計
    final Map<String, int> playerPointsMap = {};
    for (final m in matches) {
      for (final e in m.events) {
        if (e.isCanceled || !e.isIppon || e.isUndo) continue;
        String playerName = '';
        if (e.side == Side.red) {
          playerName = m.redName.contains(':')
              ? m.redName.split(':').last.trim()
              : m.redName;
        } else if (e.side == Side.white) {
          playerName = m.whiteName.contains(':')
              ? m.whiteName.split(':').last.trim()
              : m.whiteName;
        }
        if (playerName.isNotEmpty && !playerName.contains('代表')) {
          playerPointsMap[playerName] = (playerPointsMap[playerName] ?? 0) + 1;
        }
      }
    }

    final totalMatchesCount = totalWins + totalLosses + totalDraws;
    if (totalMatchesCount > 0) {
      final double winRate = totalMatchesCount > 0
          ? (totalWins / totalMatchesCount) * 100.0
          : 0.0;
      buffer.writeln('━━━━━━━━━━━━━━');
      buffer.writeln(
        '🏆 通算成績: $totalWins勝$totalLosses敗$totalDraws分 (勝率: ${winRate.toStringAsFixed(1)}%)',
      );

      if (playerPointsMap.isNotEmpty) {
        final sortedPlayers = playerPointsMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        if (sortedPlayers.first.value > 0) {
          final top = sortedPlayers.first;
          buffer.writeln('🔥 本日の最多取得本数: ${top.key} (${top.value}本)');
        }
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━');
    buffer.write('Kendo_Sync より配信');

    return buffer.toString();
  }
}
