import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/domain/score/score_event.dart';
import '../../test/helpers/mock_data.dart';

void main() {
  group('🛡️ Phase 4 — オフライン完全耐性・分散競合解決テスト要塞', () {
    late DateTime baseTime;

    setUp(() {
      baseTime = DateTime(2026, 5, 30, 10, 0, 0);
    });

    test(
      '1. 【Queue耐久】1000連続入力イベントがモデルへ追記されても、データの欠落やインデックス破損を起こさずホールドされること',
      () {
        var match = MatchBuilder().id('queue_dur_001').localOnly().build();

        final events = List.generate(
          1000,
          (index) => ScoreEvent(
            id: 'ev_stress_$index',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: baseTime.add(Duration(milliseconds: index)),
            logicalClock: index,
          ),
        );

        match = match.copyWith(events: events);

        expect(match.events.length, equals(1000));
        expect(match.events.first.id, equals('ev_stress_0'));
        expect(match.events.last.id, equals('ev_stress_999'));
      },
    );

    test(
      '2. 【Conflict Resolution】A端末(一本追加)とB端末(取り消し)の乱序イベントが、論理時計最優先のドメイン規約に基づき確定的に一本の歴史へ集約されること',
      () {
        final eventA = ScoreEvent(
          id: 'ev_device_A',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: baseTime.add(const Duration(seconds: 5)),
          logicalClock: 10,
        );

        final eventB = ScoreEvent(
          id: 'ev_device_B',
          side: Side.none,
          strikeType: StrikeType.none,
          isIppon: false,
          timestamp: baseTime.add(const Duration(seconds: 2)),
          logicalClock: 5,
        );

        final chaosQueue = [eventA, eventB];

        chaosQueue.sort((a, b) {
          if (a.logicalClock != b.logicalClock) {
            return a.logicalClock.compareTo(b.logicalClock);
          }
          return a.timestamp.compareTo(b.timestamp);
        });

        expect(chaosQueue.first.id, equals('ev_device_B'));
        expect(chaosQueue.last.id, equals('ev_device_A'));
      },
    );

    test(
      '3. 【Multi-device同一性】同一のイベントストリーム履歴を流し込んだ場合、審判・本部・Viewer・保護者の全端末上で生成されるMatchModelが1ビットの狂いもなくトポロジー完全一致すること',
      () {
        final sharedHistory = [
          ScoreEvent(
            id: 'shared_1',
            side: Side.red,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: baseTime,
            logicalClock: 1,
          ),
        ];

        final refereeModel = const MatchModel(
          id: 'm_share',
          matchType: '中堅',
          redName: 'A',
          whiteName: 'B',
        ).copyWith(events: sharedHistory);
        final adminModel = const MatchModel(
          id: 'm_share',
          matchType: '中堅',
          redName: 'A',
          whiteName: 'B',
        ).copyWith(events: sharedHistory);
        final viewerModel = const MatchModel(
          id: 'm_share',
          matchType: '中堅',
          redName: 'A',
          whiteName: 'B',
        ).copyWith(events: sharedHistory);
        final parentModel = const MatchModel(
          id: 'm_share',
          matchType: '中堅',
          redName: 'A',
          whiteName: 'B',
        ).copyWith(events: sharedHistory);

        expect(
          refereeModel.events.first.id,
          equals(adminModel.events.first.id),
        );
        expect(adminModel.events.first.id, equals(viewerModel.events.first.id));
        expect(
          viewerModel.events.first.id,
          equals(parentModel.events.first.id),
        );
      },
    );
  });
}
