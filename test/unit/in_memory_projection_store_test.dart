import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/infrastructure/repository/in_memory_projection_store.dart';

void main() {
  late InMemoryProjectionStore store;

  setUp(() {
    store = InMemoryProjectionStore();
  });

  group('[Unit] InMemoryProjectionStore 単体テスト', () {
    test('saveにより詳細プロジェクションが保存されgetで復元できること', () async {
      const projection = MatchProjection(
        id: 'match-101',
        tournamentId: 'tour-1',
        matchOrder: 1,
        matchType: 'individual',
        status: 'in_progress',
        groupName: 'Aブロック',
        isKachinuki: false,
        redName: '選手A',
        whiteName: '選手B',
        redScore: 1,
        whiteScore: 0,
        remainingSeconds: 180,
        timerIsRunning: false,
        note: '第1試合',
      );

      await store.save(projection);
      final retrieved = await store.get('match-101');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'match-101');
      expect(retrieved.redName, '選手A');
      expect(retrieved.redScore, 1);
    });

    test('watchにより保存時にプロジェクションがストリーム配信されること', () async {
      const projection1 = MatchProjection(
        id: 'match-stream-1',
        tournamentId: 'tour-1',
        matchOrder: 1,
        matchType: 'individual',
        status: 'in_progress',
        groupName: 'A',
        isKachinuki: false,
        redName: '選手1',
        whiteName: '選手2',
        redScore: 1,
        whiteScore: 0,
        remainingSeconds: 180,
        timerIsRunning: false,
        note: '',
      );

      final futureFirst = store.watch('match-stream-1').first;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await store.save(projection1);

      final result = await futureFirst;
      expect(result.id, 'match-stream-1');
      expect(result.redScore, 1);
    });

    test('watchByTournamentにより該当大会IDの軽量リストプロジェクションが取得できること', () async {
      const projTour1 = MatchProjection(
        id: 'match-t1',
        tournamentId: 'target-tour',
        matchOrder: 1,
        matchType: 'individual',
        status: 'waiting',
        groupName: 'A',
        isKachinuki: false,
        redName: '赤1',
        whiteName: '白1',
        redScore: 0,
        whiteScore: 0,
        remainingSeconds: 180,
        timerIsRunning: false,
        note: '',
      );

      const projOtherTour = MatchProjection(
        id: 'match-t2',
        tournamentId: 'other-tour',
        matchOrder: 1,
        matchType: 'individual',
        status: 'waiting',
        groupName: 'B',
        isKachinuki: false,
        redName: '別赤',
        whiteName: '別白',
        redScore: 0,
        whiteScore: 0,
        remainingSeconds: 180,
        timerIsRunning: false,
        note: '',
      );

      await store.save(projTour1);
      await store.save(projOtherTour);

      // 保存済みの場合、初期キャッシュとして直ちに該当大会のリストが返却されること
      final list = await store.watchByTournament('target-tour').first;
      expect(list.length, 1);
      expect(list.first.id, 'match-t1');
    });
  });
}
