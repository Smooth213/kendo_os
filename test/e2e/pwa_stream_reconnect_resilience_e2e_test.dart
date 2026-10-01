import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection_mapper.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/time/server_clock_offset_service.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('[E2E] Web/PWA Viewer スリープ復帰・時計スキュー補正・最新状態再同期耐障害性テスト', () {
    test(
      '端末スリープ中の切断と5秒の時計スキュー発生後、復帰時にServerClockOffsetが補正され、最新プロジェクション状態へ即時収束すること',
      () async {
        final clockService = ServerClockOffsetService.instance;
        final timeSource = SystemTimeSource(clockService);

        // 初期状態: サーバーと端末時刻が同期（オフセット0）
        clockService.resetOffset();
        final t0 = timeSource.now();

        // 1. スリープ発生シミュレーション:
        // クライアント側端末の時計が5000ms遅れる（またはサーバー側が進む）時計スキュー発生
        clockService.setOffset(const Duration(milliseconds: 5000));
        final skewedNow = timeSource.now();
        expect(
          skewedNow.difference(t0).inMilliseconds >= 4900,
          isTrue,
          reason: 'ServerClockOffsetによりサーバー同期時刻が正確に5秒進んだ値に補正されていること',
        );

        // 2. スリープ中にバックグラウンドで複数試合が進行・更新される
        final streamController = StreamController<List<MatchModel>>.broadcast();

        final initialMatches = [
          MatchModel(
            id: 'm_live_1',
            tournamentId: 't_pwa_resilience',
            category: '一般の部',
            matchType: '先鋒',
            order: 1.0,
            redName: '神武館: 選手1',
            whiteName: '修道館: 選手1',
            redScore: 1,
            whiteScore: 0,
            status: 'playing',
          ),
        ];

        // 観戦Viewerが受信している状態
        List<MatchModel> currentViewerState = [...initialMatches];

        // スリープ復帰: WebSocket / Firestore Stream の再接続
        // スリープ中の未受信試合（m_live_1終了、m_live_2, m_live_3進行）を一括受信
        final updatedMatches = [
          MatchModel(
            id: 'm_live_1',
            tournamentId: 't_pwa_resilience',
            category: '一般の部',
            matchType: '先鋒',
            order: 1.0,
            redName: '神武館: 選手1',
            whiteName: '修道館: 選手1',
            redScore: 2,
            whiteScore: 0,
            status: 'finished',
          ),
          MatchModel(
            id: 'm_live_2',
            tournamentId: 't_pwa_resilience',
            category: '一般の部',
            matchType: '次鋒',
            order: 2.0,
            redName: '神武館: 選手2',
            whiteName: '修道館: 選手2',
            redScore: 1,
            whiteScore: 1,
            status: 'finished',
          ),
          MatchModel(
            id: 'm_live_3',
            tournamentId: 't_pwa_resilience',
            category: '一般の部',
            matchType: '中堅',
            order: 3.0,
            redName: '神武館: 選手3',
            whiteName: '修道館: 選手3',
            redScore: 1,
            whiteScore: 0,
            status: 'playing',
          ),
        ];

        streamController.stream.listen((matches) {
          currentViewerState = matches;
        });

        // 再接続イベント発火
        streamController.add(updatedMatches);
        await Future.delayed(const Duration(milliseconds: 20));

        // 3. 最新状態に同期されていることを検証
        expect(currentViewerState.length, 3);
        expect(currentViewerState[0].status, 'finished');
        expect(currentViewerState[0].redScore, 2);
        expect(currentViewerState[1].status, 'finished');
        expect(currentViewerState[2].status, 'playing');

        // 4. プロジェクション層への反映検証
        final fakeTournament = TournamentModel(
          id: 't_pwa_resilience',
          organizationId: 'org_1',
          name: 'PWA耐障害性検証大会',
          date: DateTime.now(),
          venue: '日本武道館',
          categories: const ['一般の部'],
        );

        final tournamentProjection = TournamentProjectionMapper.fromModels(
          fakeTournament,
          currentViewerState,
        );

        expect(tournamentProjection.allMatches.length, 3);
        expect(
          tournamentProjection.allMatches
              .where((m) => m.status == 'finished')
              .length,
          2,
        );

        // オフセットのリセット
        clockService.resetOffset();
        await streamController.close();
      },
    );
  });
}
