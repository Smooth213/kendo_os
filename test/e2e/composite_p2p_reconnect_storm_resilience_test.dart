import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/p2p/infrastructure/local_p2p_broadcaster.dart';

void main() {
  group('[E2E] P2Pローカル配信 大量観客Web PWA再接続ストーム負荷耐障害性テスト', () {
    test(
      '複数クライアントによる同時切断・再接続の嵐（ストーム）下でもP2Pサーバーが枯渇せず最新試合状態が正常配信されること',
      () async {
        final broadcaster = LocalP2pBroadcaster();
        addTearDown(broadcaster.stopServer);

        // P2Pローカルサーバーの起動
        final localUrl = await broadcaster.startServer();
        expect(broadcaster.isRunning, isTrue);
        expect(localUrl, isNotNull);

        final now = DateTime(2026, 10, 15, 11, 0, 0);

        final match = MatchModel(
          id: 'storm_test_match_01',
          tournamentId: 't_storm',
          matchType: '個人戦',
          groupName: '第3コート',
          redName: '選手赤',
          whiteName: '選手白',
          redScore: 1,
          whiteScore: 0,
          status: 'in_progress',
          events: [
            ScoreEvent(
              id: 'ev_storm_men',
              side: Side.red,
              strikeType: StrikeType.men,
              isIppon: true,
              timestamp: now,
              sequence: 1,
              logicalClock: 1,
            ),
          ],
        );

        // ── シナリオ 1: 50クライアント相当の急激な接続・切断ストームをシミュレーション ──
        const stormClientCount = 50;
        final controllers = <StreamController<String>>[];

        for (var i = 0; i < stormClientCount; i++) {
          final ctrl = StreamController<String>.broadcast();
          controllers.add(ctrl);
        }

        // 順次配信と高速切断を繰り返す
        for (var round = 0; round < 3; round++) {
          // 全クライアントへブロードキャスト実行
          expect(
            () => broadcaster.broadcastMatch(
              match,
              remainingSeconds: 120 - round * 10,
            ),
            returnsNormally,
          );

          // 差分デルタ伝送
          expect(
            () => broadcaster.broadcastMatchDelta(match.id, {
              'redScore': 1,
              'remainingSeconds': 120 - round * 10,
            }),
            returnsNormally,
          );

          // 一部のクライアントがランダムに切断（Close）
          for (var i = 0; i < 10; i++) {
            final targetIdx = (round * 10 + i) % stormClientCount;
            if (!controllers[targetIdx].isClosed) {
              await controllers[targetIdx].close();
            }
          }
        }

        // ── シナリオ 2: ストーム沈静化後の正常配信と健全性確認 ──
        // サーバーがクラッシュせず稼働し続けていること
        expect(broadcaster.isRunning, isTrue);

        // 試合終了モデルの送信
        final finishedMatch = match.copyWith(
          status: 'finished',
          whiteScore: 0,
          lastUpdatedAt: now.add(const Duration(minutes: 3)),
        );

        expect(
          () => broadcaster.broadcastMatch(finishedMatch, remainingSeconds: 0),
          returnsNormally,
        );

        // 残りのコントローラーを安全にクローズ
        for (final ctrl in controllers) {
          if (!ctrl.isClosed) {
            await ctrl.close();
          }
        }

        // サーバーの正常停止確認
        await broadcaster.stopServer();
        expect(broadcaster.isRunning, isFalse);
      },
    );
  });
}
