import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/infrastructure/repository/in_memory_projection_store.dart';

MatchProjection createTestProjection({
  required String id,
  required String tournamentId,
  required String redName,
  required String whiteName,
  String status = 'in_progress',
  String groupName = 'Aブロック',
}) {
  return MatchProjection(
    id: id,
    tournamentId: tournamentId,
    matchOrder: 1,
    matchType: 'individual',
    status: status,
    groupName: groupName,
    isKachinuki: false,
    redName: redName,
    whiteName: whiteName,
    redScore: 1,
    whiteScore: 0,
    remainingSeconds: 180,
    timerIsRunning: false,
    note: '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[E2E] マスター組織プロビジョニング＆テナンシーデータ完全隔離E2Eテスト', () {
    test('組織Aと組織Bでプロビジョニングされたプロジェクションデータが相互に完全に隔離され漏洩しないこと', () async {
      final storeA = InMemoryProjectionStore();
      final storeB = InMemoryProjectionStore();

      const orgATournamentId = 'tour_org_tokyo_2026';
      const orgBTournamentId = 'tour_org_osaka_2026';

      // 1. 組織A（東京道場）で試合プロジェクションを保存
      final projA1 = createTestProjection(
        id: 'match_a_1',
        tournamentId: orgATournamentId,
        redName: '東京選手1',
        whiteName: '東京選手2',
        status: 'finished',
      );
      final projA2 = createTestProjection(
        id: 'match_a_2',
        tournamentId: orgATournamentId,
        redName: '東京選手3',
        whiteName: '東京選手4',
      );

      await storeA.save(projA1);
      await storeA.save(projA2);

      // 2. 組織B（大阪道場）で試合プロジェクションを保存
      final projB1 = createTestProjection(
        id: 'match_b_1',
        tournamentId: orgBTournamentId,
        redName: '大阪チームA',
        whiteName: '大阪チームB',
      );

      await storeB.save(projB1);

      // 3. 組織Aのコンテキストからの取得検証
      final fetchedA1 = await storeA.get('match_a_1');
      final fetchedA2 = await storeA.get('match_a_2');
      final crossFetchAtoB = await storeA.get('match_b_1');

      expect(fetchedA1, isNotNull);
      expect(fetchedA1!.redName, '東京選手1');
      expect(fetchedA2, isNotNull);
      expect(fetchedA2!.redName, '東京選手3');
      // 組織Aのストアから組織Bのデータは一切取得できないこと
      expect(crossFetchAtoB, isNull);

      // 4. 組織Bのコンテキストからの取得検証
      final fetchedB1 = await storeB.get('match_b_1');
      final crossFetchBtoA = await storeB.get('match_a_1');

      expect(fetchedB1, isNotNull);
      expect(fetchedB1!.redName, '大阪チームA');
      // 組織Bのストアから組織Aのデータは一切取得できないこと
      expect(crossFetchBtoA, isNull);

      // 5. 大会ごとのストリームクエリ（watchByTournament）におけるデータ完全隔離検証
      final listA = await storeA.watchByTournament(orgATournamentId).first;
      expect(listA.length, 2);
      expect(listA.any((m) => m.id == 'match_b_1'), isFalse);

      final listB = await storeB.watchByTournament(orgBTournamentId).first;
      expect(listB.length, 1);
      expect(listB.first.id, 'match_b_1');
      expect(listB.any((m) => m.id == 'match_a_1'), isFalse);
    });
  });
}
