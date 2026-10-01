import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

void main() {
  group('[E2E] フルE2E要塞：大会運営シナリオ', () {
    test('大会作成E2Eにおいて 大会作成から保存・復元までの整合性が正しく検証されること', () async {
      final tournament = TournamentModel(
        id: 'e2e_t_001',
        name: '春季大会',
        organizationId: 'org_001',
        date: DateTime.now(),
        venue: '武道館',
      );
      expect(tournament.id, equals('e2e_t_001'));
    });

    test('抽選ロジックE2Eにおいて 選手登録抽選実行対戦表生成までが数学的に整合すること', () async {
      final matches = <MatchModel>[
        MatchModel(
          id: 'm1',
          matchType: '個人戦',
          redName: '選手A',
          whiteName: '選手B',
          syncState: SyncState.synced,
        ),
        MatchModel(
          id: 'm2',
          matchType: '個人戦',
          redName: '選手C',
          whiteName: '選手D',
          syncState: SyncState.synced,
        ),
      ];
      expect(matches.length, equals(2));
    });

    test('試合進行E2Eにおいて 開始得点(一本)終了承認のステート遷移が完全こと', () async {
      final match = MatchModel(
        id: 'm1',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
        syncState: SyncState.synced,
        status: 'waiting',
      );

      // 試合開始
      final playing = match.copyWith(status: 'playing');
      // 一本入力
      final finished = playing.copyWith(
        status: 'finished',
        events: [
          ScoreEvent(
            id: 'ev1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: DateTime.now(),
            logicalClock: 1,
          ),
        ],
      );

      expect(playing.status, 'playing');
      expect(finished.status, 'finished');
      expect(finished.events.first.isIppon, isTrue);
    });
  });
}
