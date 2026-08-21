import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
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

    if (applySort) {
      final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];

      int getTeamPriority(MatchModel m) {
        final rTeam = m.redName.contains(':')
            ? m.redName.split(':').first.trim()
            : '';
        final wTeam = m.whiteName.contains(':')
            ? m.whiteName.split(':').first.trim()
            : '';
        final ruleTeamName = m.rule?.teamName;
        bool rOwn =
            ownTeams.contains(rTeam) ||
            m.redName.contains('自チーム') ||
            (ruleTeamName?.isNotEmpty == true && rTeam == ruleTeamName);
        bool wOwn =
            ownTeams.contains(wTeam) ||
            m.whiteName.contains('自チーム') ||
            (ruleTeamName?.isNotEmpty == true && wTeam == ruleTeamName);
        if (rOwn && wOwn) return 1; // 同門
        if (rOwn || wOwn) return 2; // 自チーム vs 他チーム
        return 3; // 他チーム同士
      }

      String getSortName(MatchModel m) {
        final rTeam = m.redName.contains(':')
            ? m.redName.split(':').first.trim()
            : '';
        final wTeam = m.whiteName.contains(':')
            ? m.whiteName.split(':').first.trim()
            : '';
        final rName = m.redName.contains(':')
            ? m.redName.split(':').last.trim()
            : m.redName;
        final wName = m.whiteName.contains(':')
            ? m.whiteName.split(':').last.trim()
            : m.whiteName;
        final ruleTeamName = m.rule?.teamName;

        bool rOwn =
            ownTeams.contains(rTeam) ||
            m.redName.contains('自チーム') ||
            (ruleTeamName?.isNotEmpty == true && rTeam == ruleTeamName);
        bool wOwn =
            ownTeams.contains(wTeam) ||
            m.whiteName.contains('自チーム') ||
            (ruleTeamName?.isNotEmpty == true && wTeam == ruleTeamName);

        if (rOwn && wOwn) return rName; // 同門は赤優先
        if (rOwn) return rName;
        if (wOwn) return wName;
        return rName;
      }

      displayMatches.sort((a, b) {
        int pA = getTeamPriority(a);
        int pB = getTeamPriority(b);
        if (pA != pB) return pA.compareTo(pB);

        String nameA = getSortName(a);
        String nameB = getSortName(b);
        int nameCompare = nameA.compareTo(nameB);
        if (nameCompare != 0) return nameCompare;

        return a.order.compareTo(b.order); // 同じ選手なら試合順
      });
    }

    // ヘッダー名からシステムID（英数字とハイフンの羅列）を隠す処理
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

    final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];

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
      final rScore = (m.redScore as num).toInt();
      final wScore = (m.whiteScore as num).toInt();
      final isDraw = isDone && rScore == wScore;
      final rWin = isDone && rScore > wScore;
      final wWin = isDone && wScore > rScore;

      final ptsMap = MatchCalculatorHelper.extractPointsFromModel(m);

      final ruleTeamName = m.rule?.teamName;
      final bool rOwn =
          ownTeams.contains(rTeam) ||
          m.redName.contains('自チーム') ||
          (ruleTeamName?.isNotEmpty == true && rTeam == ruleTeamName);
      final bool wOwn =
          ownTeams.contains(wTeam) ||
          m.whiteName.contains('自チーム') ||
          (ruleTeamName?.isNotEmpty == true && wTeam == ruleTeamName);
      final bool hasOwnTeam = rOwn || wOwn;

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
        hasOwnTeam: hasOwnTeam,
        redPoints: ptsMap['red'] ?? [],
        whitePoints: ptsMap['white'] ?? [],
      );
    }).toList();

    return IndividualListCard(
      headerTitle: headerTitle,
      matches: matchItems,
      cardColor: cardColor,
      isDark: isDark,
    );
  }
}
