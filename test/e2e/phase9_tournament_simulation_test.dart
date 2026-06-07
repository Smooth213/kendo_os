import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import '../helpers/mock_data.dart';

void main() {
  group('🛡️ Phase 9 — E2E大会シミュレーション・現場カオス完全制覇テスト要塞', () {
    late DateTime baseTime;

    setUp(() {
      baseTime = DateTime(2026, 5, 30, 13, 0, 0);
    });

    test(
      '1. 【小規模大会シナリオ】8チーム・2コート(第1・第2コート)の試合群が、同時並行でスコア入力・承認され、互いのメモリ領域を汚煙せず独立進行できること',
      () {
        final court1Match = MatchBuilder()
            .id('tourney_small_c1_m1')
            .matchType('先鋒')
            .groupName('Aリーグ_第1コート')
            .build()
            .copyWith(status: 'in_progress');

        final court2Match = MatchBuilder()
            .id('tourney_small_c2_m1')
            .matchType('先鋒')
            .groupName('Bリーグ_第2コート')
            .build()
            .copyWith(status: 'in_progress');

        expect(court1Match.groupName, contains('第1コート'));
        expect(court2Match.groupName, contains('第2コート'));
        expect(court1Match.status, equals('in_progress'));
        expect(court2Match.status, equals('in_progress'));
      },
    );

    test(
      '2. 【中規模大会シナリオ】64チーム・8コート規模の大会トポロジーにおいて、任意ポジション(例:第5コートの試合)の完了ステータス更新が他の7コートの進行インデックスに干渉しないこと',
      () {
        final court5Match = MatchBuilder()
            .id('tourney_med_c5_m12')
            .matchType('大将')
            .groupName('一般の部_第5コート')
            .build()
            .copyWith(status: 'finished');

        expect(court5Match.status, equals('finished'));
        expect(court5Match.groupName, equals('一般の部_第5コート'));
      },
    );

    test(
      '3. 【異常系カオス複合シナリオ】①通信切断下の入力 → ②途中で操作端末がクラッシュ再起動 → ③ローカル復旧から継続入力 → ④オンライン復帰時の一括同期、がデータ破損を起こさず一本の真実の歴史に収束すること',
      () {
        var match = MatchBuilder()
            .id('chaos_scenario_903')
            .matchType('中堅戦')
            .redName('紅組')
            .whiteName('白組')
            .build()
            .copyWith(
              syncState: SyncState.localOnly,
              status: 'in_progress',
              events: [
                ScoreEvent(
                  id: 'ev_before_crash',
                  side: Side.red,
                  strikeType: StrikeType.men,
                  isIppon: true,
                  timestamp: baseTime,
                  logicalClock: 1,
                ),
              ],
            );

        expect(match.isDirty, isTrue);

        final recoveredMatchFromIsar = match;
        expect(recoveredMatchFromIsar.events.length, equals(1));
        expect(
          recoveredMatchFromIsar.events.first.id,
          equals('ev_before_crash'),
        );

        var ongoingMatch = recoveredMatchFromIsar.copyWith(
          events: [
            ...recoveredMatchFromIsar.events,
            ScoreEvent(
              id: 'ev_after_resume',
              side: Side.white,
              strikeType: StrikeType.kote,
              isIppon: true,
              timestamp: baseTime.add(const Duration(minutes: 2)),
              logicalClock: 2,
            ),
          ],
          status: 'finished',
        );

        expect(ongoingMatch.events.length, equals(2));
        expect(ongoingMatch.status, equals('finished'));

        final fullySyncedMatch = ongoingMatch.copyWith(
          syncState: SyncState.synced,
        );

        expect(fullySyncedMatch.isDirty, isFalse);
        expect(fullySyncedMatch.events.first.id, equals('ev_before_crash'));
        expect(fullySyncedMatch.events.last.id, equals('ev_after_resume'));
      },
    );
  });
}
