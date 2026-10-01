import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_projection_entity.dart';
import 'package:kendo_os/shared/infrastructure/repository/isar_projection_store.dart';
import '../helpers/test_isar_helper.dart';

void main() {
  group('[Unit] IsarProjectionStore 単体テスト', () {
    test('isarがnullの場合に例外なく安全にノーオペレーション完了し空リストを返却すること', () async {
      final store = IsarProjectionStore(null);
      const match = MatchModel(
        id: 'null-test-1',
        matchType: 'individual',
        redName: '赤',
        whiteName: '白',
      );

      await expectLater(store.saveMatchProjection(match), completes);
      final list = await store.getTournamentProjections('tour-1');
      expect(list, isEmpty);
    });

    test('MatchModelを保存した際にEntityに変換され既存IDを引き継いでupsertされること', () async {
      final context = await TestIsarHelper.openContext(
        schemas: [MatchProjectionEntitySchema],
        prefix: 'isar_proj_test',
      );

      try {
        final store = IsarProjectionStore(context.isar);

        const match1 = MatchModel(
          id: 'match-101',
          tournamentId: 'tour-100',
          matchType: 'individual',
          redName: '山田',
          whiteName: '佐藤',
          redScore: 1,
          whiteScore: 0,
          status: 'in_progress',
          order: 1,
        );

        await store.saveMatchProjection(match1);

        var list = await store.getTournamentProjections('tour-100');
        expect(list.length, 1);
        expect(list.first.matchId, 'match-101');
        expect(list.first.redName, '山田');
        expect(list.first.redScore, 1);
        final initialEntityId = list.first.id;

        // 同一matchIdでスコア更新保存
        const match1Updated = MatchModel(
          id: 'match-101',
          tournamentId: 'tour-100',
          matchType: 'individual',
          redName: '山田',
          whiteName: '佐藤',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          order: 1,
        );

        await store.saveMatchProjection(match1Updated);

        list = await store.getTournamentProjections('tour-100');
        expect(list.length, 1);
        expect(list.first.id, initialEntityId);
        expect(list.first.redScore, 2);
        expect(list.first.status, 'finished');
      } finally {
        await context.dispose();
      }
    });

    test('getTournamentProjectionsにより大会IDでフィルタされmatchOrder順に復元されること', () async {
      final context = await TestIsarHelper.openContext(
        schemas: [MatchProjectionEntitySchema],
        prefix: 'isar_proj_order_test',
      );

      try {
        final store = IsarProjectionStore(context.isar);

        const matchA = MatchModel(
          id: 'match-order-2',
          tournamentId: 'tour-order',
          matchType: 'individual',
          redName: '赤2',
          whiteName: '白2',
          order: 2,
        );

        const matchB = MatchModel(
          id: 'match-order-1',
          tournamentId: 'tour-order',
          matchType: 'individual',
          redName: '赤1',
          whiteName: '白1',
          order: 1,
        );

        const matchOtherTour = MatchModel(
          id: 'match-other',
          tournamentId: 'other-tour',
          matchType: 'individual',
          redName: '別',
          whiteName: '別',
          order: 1,
        );

        await store.saveMatchProjection(matchA);
        await store.saveMatchProjection(matchB);
        await store.saveMatchProjection(matchOtherTour);

        final list = await store.getTournamentProjections('tour-order');
        expect(list.length, 2);
        expect(list[0].matchId, 'match-order-1');
        expect(list[1].matchId, 'match-order-2');
      } finally {
        await context.dispose();
      }
    });
  });
}
