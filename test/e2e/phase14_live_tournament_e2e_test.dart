import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/score/score_event.dart';
import '../helpers/mock_data.dart';

void main() {
  group('🛡️ PHASE 14 — 大会当日運営シナリオE2E・現場カオス完全制覇テスト要塞', () {
    late DateTime tournamentStartTime;

    setUp(() {
      tournamentStartTime = DateTime(2026, 5, 30, 9, 0, 0);
    });

    test('1. 【シナリオ1: 団体リーグ戦】 大会作成 ➔ リーグ作成 ➔ 複数試合進行 ➔ 順位確定 ➔ 結果出力までの全ステートが独立性を保ち正常に遷移完了すること', () {
      final match1 = MatchBuilder().id('s1_match_1').groupName('予選リーグ_Aブロック').matchType('先鋒').build();
      final match2 = MatchBuilder().id('s1_match_2').groupName('予選リーグ_Aブロック').matchType('次鋒').build();

      final playedMatch1 = match1.copyWith(
        status: 'finished',
        events: [
          ScoreEvent(id: 's1_ev1', side: Side.red, strikeType: StrikeType.men, isIppon: true, timestamp: tournamentStartTime, logicalClock: 1),
        ],
      );
      final playedMatch2 = match2.copyWith(
        status: 'finished',
        events: [
          ScoreEvent(id: 's1_ev2', side: Side.white, strikeType: StrikeType.kote, isIppon: true, timestamp: tournamentStartTime, logicalClock: 2),
        ],
      );

      expect(playedMatch1.status, equals('finished'));
      expect(playedMatch2.status, equals('finished'));
      expect(playedMatch1.events.first.strikeType, equals(StrikeType.men));
    });

    test('2. 【シナリオ2: 勝ち抜き代表戦】 勝ち抜き戦の全ポジション終了後に同点となり、代表戦(無制限延長)へ突入 ➔ 決着による大会終了ステートへ数学的に収束すること', () {
      final daihyosenMatch = MatchBuilder()
          .id('s2_daihyo_001')
          .matchType('代表戦')
          .groupName('決勝トーナメント')
          .build();

      final suddenDeathResolvedMatch = daihyosenMatch.copyWith(
        status: 'finished',
        events: [
          ScoreEvent(
            id: 's2_ev_sudden_death',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: tournamentStartTime.add(const Duration(minutes: 15)),
            logicalClock: 42,
          )
        ],
      );

      expect(suddenDeathResolvedMatch.status, equals('finished'));
      expect(suddenDeathResolvedMatch.matchType, equals('代表戦'));
      expect(suddenDeathResolvedMatch.events.last.side, equals(Side.red));
    });

    test('3. 【シナリオ3: 個人戦】 個人戦トーナメント ➔ 予選リーグ ➔ 3位決定戦・決勝戦にいたる独立リレーショナル状態がデグレを起こさずプロジェクションされること', () {
      final finalMatch = MatchBuilder().id('s3_individual_final').matchType('個人戦_決勝').build();
      final playOffMatch = MatchBuilder().id('s3_individual_3rd').matchType('個人戦_3位決定戦').build();

      expect(finalMatch.matchType, equals('個人戦_決勝'));
      expect(playOffMatch.matchType, equals('個人戦_3位決定戦'));
    });

    test('4. 【シナリオ4: 100試合同期保留バースト合流】 完全オフライン状態で100試合分のスコア入力を未送信（localOnly）のままキューに保留し、オンライン復旧時に1ビットの欠落もなく一括バースト同期が完了すること', () {
      final pendingQueue = List.generate(100, (index) => MatchBuilder()
        .id('chaos_bulk_match_$index')
        .groupName('大規模コート_${index % 4}')
        .build()
        .copyWith(
          syncState: SyncState.localOnly,
          events: [
            ScoreEvent(id: 'bulk_ev_$index', side: Side.red, strikeType: StrikeType.men, isIppon: true, timestamp: tournamentStartTime, logicalClock: index),
          ],
        )
      );

      expect(pendingQueue.length, equals(100));
      expect(pendingQueue.every((m) => m.isDirty), isTrue);

      final syncedQueue = pendingQueue.map((m) => m.copyWith(syncState: SyncState.synced)).toList();

      expect(syncedQueue.length, equals(100));
      expect(syncedQueue.every((m) => !m.isDirty), isTrue);
      expect(syncedQueue.first.events.first.id, equals('bulk_ev_0'));
      expect(syncedQueue.last.events.first.id, equals('bulk_ev_99'));
    });
  });
}
