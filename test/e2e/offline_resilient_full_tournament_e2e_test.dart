import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_queue.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('🚀 【E2E 1/5】完全オフライン ➔ 体育館Wi-Fi復旧 ➔ クラウド同期 実践E2Eテスト', () {
    test('完全オフラインで10試合消化後、オンライン復帰時に全イベントが論理時計順に整列して同期収束すること', () async {
      final startTime = DateTime(2026, 9, 3, 9, 0, 0);

      // 1. 完全オフライン環境下で10試合を連続実施し、ローカルキューに蓄積
      final localMatches = <MatchModel>[];
      final pendingCommands = <MatchCommandModel>[];

      for (int i = 1; i <= 10; i++) {
        final matchTime = startTime.add(Duration(minutes: i * 5));
        final matchId = 'offline_match_$i';

        final events = [
          ScoreEvent(
            id: 'ev_${i}_1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: matchTime,
            logicalClock: i * 2 - 1,
          ),
          ScoreEvent(
            id: 'ev_${i}_2',
            side: i.isEven ? Side.red : Side.white,
            strikeType: StrikeType.kote,
            isIppon: true,
            timestamp: matchTime.add(const Duration(seconds: 45)),
            logicalClock: i * 2,
          ),
        ];

        final match = MatchModel(
          id: matchId,
          tournamentId: 'tour_offline_e2e',
          category: '一般の部',
          matchType: '個人戦',
          status: 'finished',
          redName: '選手R$i',
          whiteName: '選手W$i',
          redScore: i.isEven ? 2 : 1,
          whiteScore: i.isEven ? 0 : 1,
          events: events,
          order: i.toDouble(),
        );
        localMatches.add(match);

        pendingCommands.add(
          MatchCommandModel(
            id: 'cmd_$i',
            type: CommandType.addScore,
            payload: {'matchId': matchId, 'eventsCount': events.length},
            createdAt: matchTime,
          ),
        );
      }

      expect(localMatches.length, 10);
      expect(pendingCommands.length, 10);

      // 2. 体育館Wi-Fi復旧シミュレーション（全コマンドが未完了から処理キューへ）
      final shuffledCommands = List<MatchCommandModel>.from(pendingCommands)
        ..shuffle();
      for (var cmd in shuffledCommands) {
        expect(cmd.status, CommandStatus.pending);
      }

      // 3. 各試合について、クラウド側の空/既存状態とローカルの蓄積状態をSyncCrdtMergerで決定論的マージ
      for (int i = 0; i < 10; i++) {
        final local = localMatches[i];
        final remote = MatchModel(
          id: local.id,
          tournamentId: local.tournamentId,
          category: local.category,
          matchType: local.matchType,
          status: 'waiting',
          redName: local.redName,
          whiteName: local.whiteName,
          events: [],
        );

        final merged = SyncCrdtMerger.mergeAndRebuild(
          remoteMatch: remote,
          localMatch: local.copyWith(pendingEvents: local.events),
          rule: const MatchRule(),
          rebuilder: RebuildMatchFromEventsUseCase(
            KendoRuleEngine(),
            SystemTimeSource(),
          ),
        );

        expect(merged.events.length, 2);
        expect(
          merged.events[0].logicalClock < merged.events[1].logicalClock,
          isTrue,
        );
        expect(merged.status, 'finished');
      }
    });
  });
}
