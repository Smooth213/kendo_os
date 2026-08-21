import 'package:kendo_os/features/match/domain/match_model.dart';

/// 観客席画面用 リーグ戦グループタイトル生成ヘルパー
class ViewerLeagueTitleHelper {
  /// リーグ戦の試合リストからわかりやすいタイトル文字列を生成
  static String generateDescriptiveLeagueTitle(
    List<MatchModel> matches,
    List<String> ownTeams,
  ) {
    final participantsSet = <String>{};
    for (var m in matches) {
      participantsSet.add(m.redName.split(':').first.trim());
      participantsSet.add(m.whiteName.split(':').first.trim());
    }
    final int n = participantsSet.length;
    final int mCount = n * (n - 1) ~/ 2;

    final ruleTeamName = matches.firstOrNull?.rule?.teamName;
    final hasRuleTeam = ruleTeamName?.isNotEmpty == true;

    final bool isIndiv = matches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦'),
    );

    String selfInfo = "";
    if (isIndiv) {
      final myMatch = matches.firstWhere(
        (m) =>
            ownTeams.any(
              (ot) => m.redName.contains(ot) || m.whiteName.contains(ot),
            ) ||
            (hasRuleTeam &&
                (m.redName.contains(ruleTeamName!) ||
                    m.whiteName.contains(ruleTeamName))),
        orElse: () => matches.first,
      );
      final isRedOwn =
          ownTeams.any((ot) => myMatch.redName.contains(ot)) ||
          (hasRuleTeam && myMatch.redName.contains(ruleTeamName!));
      final rawName = isRedOwn ? myMatch.redName : myMatch.whiteName;
      final team = rawName.split(':').first.trim();
      final name = rawName.contains(':')
          ? rawName.split(':').last.replaceAll(')', '').trim()
          : rawName;
      selfInfo = "$name（$team）";
    } else {
      selfInfo = participantsSet.firstWhere(
        (p) => ownTeams.contains(p) || (hasRuleTeam && p == ruleTeamName),
        orElse: () => participantsSet.first,
      );
    }

    final suffix = isIndiv ? "$n人リーグ" : "$nチームリーグ";
    return "$selfInfo : $suffix（全$mCount試合）";
  }
}
