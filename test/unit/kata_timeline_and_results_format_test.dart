import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_group_helper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_player_match_classifier.dart';

void main() {
  group('[Unit] 剣道形 タイムライン・公式記録分類テスト', () {
    test(
      'TimelinePlayerMatchClassifier で形競技の試合が個人戦（sortedPlayers）として分類されること',
      () {
        final kataMatch = MatchModel(
          id: 'kata_1',
          tournamentId: 't1',
          order: 1.0,
          matchType: '木刀による剣道基本技稽古法（5本）',
          status: 'pending',
          redName: '道上剣友会:皿田 脩人・塚本 大道',
          whiteName: '対戦相手:選手・選手',
          groupName: '道上剣友会 vs 対戦相手',
          rule: const MatchRule(isKataMatch: true),
        );

        final result = TimelinePlayerMatchClassifier.classifyTeamMatches(
          teamMatchesList: [kataMatch],
          teamName: '道上剣友会',
          sanitizedQuery: '',
          matchedMatchIds: {},
          matchedGroupNames: {},
          ownTeams: ['道上剣友会'],
        );

        // 団体戦グループ（sortedGroups）ではなく、選手（sortedPlayers）に分類される
        expect(result.sortedGroups.isEmpty, isTrue);
        expect(result.sortedPlayers.length, 1);
        expect(result.sortedPlayers.first.key, '皿田 脩人・塚本 大道');
        expect(result.sortedPlayers.first.value.first.id, 'kata_1');
      },
    );

    test(
      'OfficialRecordGroupHelper で形競技の試合が個人戦グループ（__merged_individual__）に統合されること',
      () {
        final kataMatch = MatchModel(
          id: 'kata_2',
          tournamentId: 't1',
          order: 2.0,
          matchType: '日本剣道形',
          status: 'finished',
          redName: '道上剣友会:皿田 脩人・塚本 大道',
          whiteName: '対戦相手:選手・選手',
          groupName: '道上剣友会 vs 対戦相手',
          rule: const MatchRule(isKataMatch: true),
        );

        final groupsMap = {
          '道上剣友会 vs 対戦相手': [kataMatch],
        };

        final merged = OfficialRecordGroupHelper.mergeIndividualGroups(
          groupsMap,
        );

        expect(merged.containsKey('__merged_individual__'), isTrue);
        expect(merged['__merged_individual__']!.first.id, 'kata_2');
      },
    );
  });
}
