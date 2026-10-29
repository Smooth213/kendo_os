import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/domain/entities/organization_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_aggregate.dart';

void main() {
  group('[Unit] 大会集約エンティティおよび組織モデル単体テスト', () {
    test('TournamentAggregateにおいて指定IDの試合検索および全試合終了判定が正確に行われること', () {
      final match1 = MatchModel(
        id: 'm-1',
        tournamentId: 't-100',
        matchType: '個人戦',
        redName: '選手1',
        whiteName: '選手2',
        status: 'finished',
      );
      final match2 = MatchModel(
        id: 'm-2',
        tournamentId: 't-100',
        matchType: '個人戦',
        redName: '選手3',
        whiteName: '選手4',
        status: 'approved',
      );
      final match3 = MatchModel(
        id: 'm-3',
        tournamentId: 't-100',
        matchType: '個人戦',
        redName: '選手5',
        whiteName: '選手6',
        status: 'ongoing',
      );

      final aggregateFinished = TournamentAggregate(
        id: 't-100',
        matches: [match1, match2],
        format: TournamentFormat.knockout,
      );

      expect(aggregateFinished.getMatch('m-1'), equals(match1));
      expect(aggregateFinished.getMatch('m-non-existent'), isNull);
      expect(aggregateFinished.isAllMatchesFinished, isTrue);

      final aggregateOngoing = TournamentAggregate(
        id: 't-100',
        matches: [match1, match2, match3],
        format: TournamentFormat.knockout,
      );
      expect(aggregateOngoing.isAllMatchesFinished, isFalse);

      final aggregateEmpty = TournamentAggregate(
        id: 't-empty',
        matches: const [],
        format: TournamentFormat.league,
      );
      expect(aggregateEmpty.isAllMatchesFinished, isFalse);
    });

    test('OrganizationModelにおいてメンバーリストを含むJSONシリアライズとデシリアライズの可逆性が保たれること', () {
      const org = OrganizationModel(
        id: 'org-kendo-01',
        name: '東京剣道倶楽部',
        memberNames: ['範士八段', '教士七段', '錬士六段'],
      );

      final json = org.toJson();
      expect(json['id'], 'org-kendo-01');
      expect(json['name'], '東京剣道倶楽部');
      expect(json['memberNames'], ['範士八段', '教士七段', '錬士六段']);

      final restored = OrganizationModel.fromJson(json);
      expect(restored.id, org.id);
      expect(restored.name, org.name);
      expect(restored.memberNames, org.memberNames);
    });
  });
}
