import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/tournament_own_info_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';
import 'package:kendo_os/shared/widgets/match_tables/individual_list_card.dart';

/// 🏆 公式記録画面: 個人戦専用の縦並びリスト描画コンポーネント
class OfficialRecordIndividualMatchesList extends ConsumerWidget {
  final String groupName;
  final List<MatchModel> matches;
  final Color? cardColor;
  final bool isDark;
  final bool applySort;

  const OfficialRecordIndividualMatchesList({
    super.key,
    required this.groupName,
    required this.matches,
    this.cardColor,
    required this.isDark,
    required this.applySort,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<MatchModel> displayMatches = List.from(matches);
    final tournamentId = matches.isNotEmpty
        ? (matches.first.tournamentId ?? '')
        : '';
    final ownInfo = ref.watch(tournamentOwnInfoProvider(tournamentId));
    final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];

    bool isMatchSideOwn(String teamPart, String namePart, String? ruleTeam) {
      return ownInfo.isOwnSide(
            teamPart: teamPart,
            namePart: namePart,
            ruleTeamName: ruleTeam,
          ) ||
          ownTeams.contains(teamPart) ||
          (ruleTeam != null && ruleTeam.isNotEmpty && teamPart == ruleTeam);
    }

    if (applySort) {
      // 選手ごとの最初の試合順（初戦のorder）を計算し、選手ごとのまとまりを時系列順に並べる
      final playerFirstOrderMap = <String, double>{};
      for (final m in displayMatches) {
        final rTeam = m.redName.contains(':')
            ? m.redName.split(':').first.trim()
            : '';
        final wTeam = m.whiteName.contains(':')
            ? m.whiteName.split(':').first.trim()
            : '';
        final rName = m.redName.contains(':')
            ? m.redName.split(':').last.trim()
            : m.redName.trim();
        final wName = m.whiteName.contains(':')
            ? m.whiteName.split(':').last.trim()
            : m.whiteName.trim();
        final ruleTeamName = m.rule?.teamName;

        final bool rOwn =
            isMatchSideOwn(rTeam, rName, ruleTeamName) ||
            m.redName.contains('自チーム');
        final bool wOwn =
            isMatchSideOwn(wTeam, wName, ruleTeamName) ||
            m.whiteName.contains('自チーム');

        if (rOwn) {
          playerFirstOrderMap[rName] = (playerFirstOrderMap[rName] == null)
              ? m.order
              : (m.order < playerFirstOrderMap[rName]!
                    ? m.order
                    : playerFirstOrderMap[rName]!);
        }
        if (wOwn) {
          playerFirstOrderMap[wName] = (playerFirstOrderMap[wName] == null)
              ? m.order
              : (m.order < playerFirstOrderMap[wName]!
                    ? m.order
                    : playerFirstOrderMap[wName]!);
        }
      }

      int getTeamPriority(MatchModel m) {
        final rTeam = m.redName.contains(':')
            ? m.redName.split(':').first.trim()
            : '';
        final wTeam = m.whiteName.contains(':')
            ? m.whiteName.split(':').first.trim()
            : '';
        final rName = m.redName.contains(':')
            ? m.redName.split(':').last.trim()
            : m.redName.trim();
        final wName = m.whiteName.contains(':')
            ? m.whiteName.split(':').last.trim()
            : m.whiteName.trim();
        final ruleTeamName = m.rule?.teamName;

        final bool rOwn =
            isMatchSideOwn(rTeam, rName, ruleTeamName) ||
            m.redName.contains('自チーム');
        final bool wOwn =
            isMatchSideOwn(wTeam, wName, ruleTeamName) ||
            m.whiteName.contains('自チーム');

        // ★ 自チームの試合（同門含む）を最優先。同門対決が決勝戦なのに1番上に飛び出すのを完全に防止
        if (rOwn || wOwn) return 1; // 自チーム関連試合
        return 2; // 他チーム同士
      }

      String getSortPlayerKey(MatchModel m) {
        final rTeam = m.redName.contains(':')
            ? m.redName.split(':').first.trim()
            : '';
        final wTeam = m.whiteName.contains(':')
            ? m.whiteName.split(':').first.trim()
            : '';
        final rName = m.redName.contains(':')
            ? m.redName.split(':').last.trim()
            : m.redName.trim();
        final wName = m.whiteName.contains(':')
            ? m.whiteName.split(':').last.trim()
            : m.whiteName.trim();
        final ruleTeamName = m.rule?.teamName;

        final bool rOwn =
            isMatchSideOwn(rTeam, rName, ruleTeamName) ||
            m.redName.contains('自チーム');
        final bool wOwn =
            isMatchSideOwn(wTeam, wName, ruleTeamName) ||
            m.whiteName.contains('自チーム');

        if (rOwn && wOwn) {
          // 同門対決の場合、初戦が早かった方の選手のまとまりに帰属させる
          final firstR = playerFirstOrderMap[rName] ?? m.order;
          final firstW = playerFirstOrderMap[wName] ?? m.order;
          return firstR <= firstW ? rName : wName;
        }
        if (rOwn) return rName;
        if (wOwn) return wName;
        return rName;
      }

      displayMatches.sort((a, b) {
        int pA = getTeamPriority(a);
        int pB = getTeamPriority(b);
        if (pA != pB) return pA.compareTo(pB);

        String playerA = getSortPlayerKey(a);
        String playerB = getSortPlayerKey(b);

        // 選手の初戦orderが早い順に選手のまとまりを並べる（あとから追加された選手は下へ）
        final firstOrderA = playerFirstOrderMap[playerA] ?? a.order;
        final firstOrderB = playerFirstOrderMap[playerB] ?? b.order;
        if (firstOrderA != firstOrderB) {
          return firstOrderA.compareTo(firstOrderB);
        }

        if (playerA != playerB) return playerA.compareTo(playerB);

        // 同じ選手の中では試合順（1回戦 -> 2回戦 -> 決勝）
        return a.order.compareTo(b.order);
      });
    }

    // ヘッダー名からシステムID（英数字とハイフンの羅列）や統合用キーを隠す処理
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    String displayGroupName = groupName;
    if (uuidRegex.hasMatch(groupName) ||
        groupName.length > 20 ||
        groupName == '__default__' ||
        groupName == '__merged_individual__' ||
        groupName.contains(' vs ')) {
      displayGroupName = '';
    }

    String headerTitle = '【個人戦】';
    if (displayGroupName.isNotEmpty) {
      headerTitle += ' $displayGroupName';
    }

    final matchItems = displayMatches.map((m) {
      final rTeam = m.redName.contains(':')
          ? m.redName.split(':').first.trim()
          : '';
      final wTeam = m.whiteName.contains(':')
          ? m.whiteName.split(':').first.trim()
          : '';
      final rName = m.redName.contains(':')
          ? m.redName.split(':').last.replaceAll(')', '').trim()
          : m.redName.trim();
      final wName = m.whiteName.contains(':')
          ? m.whiteName.split(':').last.replaceAll(')', '').trim()
          : m.whiteName.trim();

      final rResolvedTeam = rTeam.isNotEmpty
          ? rTeam
          : (ownInfo.resolveTeamForPlayer(rName) ?? '');
      final wResolvedTeam = wTeam.isNotEmpty
          ? wTeam
          : (ownInfo.resolveTeamForPlayer(wName) ?? '');

      final isDone = m.status == 'finished' || m.status == 'approved';
      final rScore = (m.redScore as num).toInt();
      final wScore = (m.whiteScore as num).toInt();
      final isDraw = isDone && rScore == wScore;
      final rWin = isDone && rScore > wScore;
      final wWin = isDone && wScore > rScore;

      final ptsMap = MatchCalculatorHelper.extractPointsFromModel(m);

      final ruleTeamName = m.rule?.teamName;
      final bool rOwn =
          isMatchSideOwn(rTeam, rName, ruleTeamName) ||
          m.redName.contains('自チーム');
      final bool wOwn =
          isMatchSideOwn(wTeam, wName, ruleTeamName) ||
          m.whiteName.contains('自チーム');
      final bool hasOwnTeam = rOwn || wOwn;

      return IndividualMatchItem(
        id: m.id,
        note: m.note,
        redTeam: rResolvedTeam,
        whiteTeam: wResolvedTeam,
        redName: rName,
        whiteName: wName,
        redScore: rScore,
        whiteScore: wScore,
        isFinished: isDone,
        isSummary: m.note.contains('[SUMMARY]'),
        isDraw: isDraw,
        rWin: rWin,
        wWin: wWin,
        hasOwnTeam: hasOwnTeam,
        redPoints: ptsMap['red'] ?? [],
        whitePoints: ptsMap['white'] ?? [],
      );
    }).toList();

    final scenePrefix = matches.isNotEmpty
        ? TeamProgressHelper.getScenePrefix(matches.first)
        : '';

    return IndividualListCard(
      headerTitle: headerTitle,
      scenePrefix: scenePrefix,
      matches: matchItems,
      cardColor: cardColor,
      isDark: isDark,
    );
  }
}
