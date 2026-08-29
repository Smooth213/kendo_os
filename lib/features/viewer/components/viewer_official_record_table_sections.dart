import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';
import 'package:kendo_os/shared/widgets/match_tables/individual_list_card.dart';
import 'package:kendo_os/shared/widgets/match_tables/score_table_card.dart';

/// 🥋 観客用公式記録表: 団体戦・勝ち抜き戦スコアテーブル表示
class ViewerOfficialScoreTableCard extends StatelessWidget {
  final String groupName;
  final List<MatchListProjection> matches;
  final TeamMatchResult? result;
  final Color? cardColor;
  final bool isDark;

  const ViewerOfficialScoreTableCard({
    super.key,
    required this.groupName,
    required this.matches,
    this.result,
    this.cardColor,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    final note = matches.first.note;
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();

    final redTeam = matches.first.redName.contains(':')
        ? matches.first.redName.split(':').first.trim()
        : matches.first.redName;
    final whiteTeam = matches.first.whiteName.contains(':')
        ? matches.first.whiteName.split(':').first.trim()
        : matches.first.whiteName;

    // 試合形式に合わせてヘッダーテキストを生成
    String matchTypeStr = '団体戦';
    if (matches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    )) {
      matchTypeStr = '個人戦';
    } else if (matches.first.isKachinuki) {
      matchTypeStr = '勝ち抜き戦';
    } else if (matches.any((m) => m.note.contains('リーグ戦'))) {
      matchTypeStr = 'リーグ戦';
    }

    String headerTitle = '【$matchTypeStr】 $redTeam vs $whiteTeam';
    if (cleanNote.isNotEmpty && !cleanNote.contains(matchTypeStr)) {
      headerTitle += ' ($cleanNote)';
    }

    String teamWinner = 'draw';
    int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
    bool allFinished = false;

    if (result != null) {
      teamWinner = result!.teamWinner;
      rWins = result!.redWins;
      wWins = result!.whiteWins;
      rPts = result!.redPoints;
      wPts = result!.whitePoints;
      allFinished = result!.allFinished;
    } else {
      allFinished = matches.every(
        (m) => m.status == 'approved' || m.status == 'finished',
      );
      MatchListProjection? daihyoMatch;
      for (var m in matches) {
        if (m.status == 'approved' || m.status == 'finished') {
          final rs = m.redScore;
          final ws = m.whiteScore;
          rPts += rs;
          wPts += ws;
          if (rs > ws) {
            rWins++;
          } else if (ws > rs) {
            wWins++;
          }
        }
        if (m.matchType == '代表戦') daihyoMatch = m;
      }
      if (allFinished) {
        if (rWins > wWins) {
          teamWinner = 'red';
        } else if (wWins > rWins) {
          teamWinner = 'white';
        } else if (rPts > wPts) {
          teamWinner = 'red';
        } else if (wPts > rPts) {
          teamWinner = 'white';
        } else if (daihyoMatch != null) {
          final rs = daihyoMatch.redScore;
          final ws = daihyoMatch.whiteScore;
          if (rs > ws) {
            teamWinner = 'red';
          } else if (ws > rs) {
            teamWinner = 'white';
          }
        }
      }
    }

    final bool isSummary = matches.any((m) => m.note.contains('[SUMMARY]'));
    final scenePrefix = matches.isNotEmpty
        ? TeamProgressHelper.getScenePrefixFromDynamic(matches.first)
        : '';

    final info = ScoreTableGroupInfo(
      groupName: groupName,
      headerTitle: headerTitle,
      scenePrefix: scenePrefix,
      sideLabelRed: redTeam,
      sideLabelWhite: whiteTeam,
      isSummary: isSummary,
      teamWinner: teamWinner,
      redWins: rWins,
      whiteWins: wWins,
      redTotalPoints: rPts,
      whiteTotalPoints: wPts,
      allFinished: allFinished,
    );

    final matchItems = matches.map((m) {
      final isFinished = m.status == 'approved' || m.status == 'finished';
      final ptsMap = MatchCalculatorHelper.extractPointsFromProjection(m);
      return ScoreTableMatchItem(
        id: m.id,
        matchType: m.matchType,
        redName: m.redName,
        whiteName: m.whiteName,
        redScore: m.redScore,
        whiteScore: m.whiteScore,
        isFinished: isFinished,
        isSummary: m.note.contains('[SUMMARY]'),
        isEncho: MatchCalculatorHelper.isEnchoFromProjection(m),
        redPoints: ptsMap['red'] ?? [],
        whitePoints: ptsMap['white'] ?? [],
        onTap: () {},
      );
    }).toList();

    return InkWell(
      key: Key('viewer_match_card_$groupName'),
      onTap: () {},
      child: ScoreTableCard(
        info: info,
        matches: matchItems,
        cardColor: cardColor,
        isDark: isDark,
      ),
    );
  }
}

/// 🥋 観客用公式記録表: 個人戦リスト表示
class ViewerOfficialIndividualListCard extends StatelessWidget {
  final String groupName;
  final List<MatchListProjection> matches;
  final Color? cardColor;
  final bool isDark;
  final bool applySort;

  const ViewerOfficialIndividualListCard({
    super.key,
    required this.groupName,
    required this.matches,
    this.cardColor,
    required this.isDark,
    required this.applySort,
  });

  @override
  Widget build(BuildContext context) {
    List<MatchListProjection> displayMatches = List<MatchListProjection>.from(
      matches,
    );

    if (applySort) {
      displayMatches.sort((a, b) {
        return a.matchOrder.compareTo(b.matchOrder);
      });
    }

    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    String displayGroupName = groupName;
    if (uuidRegex.hasMatch(groupName) ||
        groupName.length > 20 ||
        groupName == '__default__' ||
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
          : m.redName;
      final wName = m.whiteName.contains(':')
          ? m.whiteName.split(':').last.replaceAll(')', '').trim()
          : m.whiteName;

      final isDone = m.status == 'finished' || m.status == 'approved';
      final rScore = m.redScore;
      final wScore = m.whiteScore;
      final isDraw = isDone && rScore == wScore;
      final rWin = isDone && rScore > wScore;
      final wWin = isDone && wScore > rScore;

      final ptsMap = MatchCalculatorHelper.extractPointsFromProjection(m);

      return IndividualMatchItem(
        id: m.id,
        note: m.note,
        redTeam: rTeam,
        whiteTeam: wTeam,
        redName: rName,
        whiteName: wName,
        redScore: rScore,
        whiteScore: wScore,
        isFinished: isDone,
        isSummary: m.note.contains('[SUMMARY]'),
        isDraw: isDraw,
        rWin: rWin,
        wWin: wWin,
        hasOwnTeam: false,
        redPoints: ptsMap['red'] ?? [],
        whitePoints: ptsMap['white'] ?? [],
        onTap: () {},
      );
    }).toList();

    final scenePrefix = matches.isNotEmpty
        ? TeamProgressHelper.getScenePrefixFromDynamic(matches.first)
        : '';

    return InkWell(
      key: Key('viewer_match_card_$groupName'),
      onTap: () {},
      child: IndividualListCard(
        headerTitle: headerTitle,
        scenePrefix: scenePrefix,
        matches: matchItems,
        cardColor: cardColor,
        isDark: isDark,
      ),
    );
  }
}
