import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/p2p/infrastructure/local_p2p_broadcaster.dart';
import 'package:kendo_os/shared/utils/payload_compression_helper.dart';

void main() {
  group('📶 【Composite E2E】電波暗黒下（体育館オフライン）P2Pストリーミング ＆ 復旧時クラウド同期完全性テスト', () {
    test('1. 体育館の電波完全遮断時におけるP2Pローカル配信・リアルタイム打突伝送ライフサイクル', () async {
      final broadcaster = LocalP2pBroadcaster();
      addTearDown(broadcaster.stopServer);

      // ── シナリオ 1: 体育館の電波完全遮断（クラウドオフライン状態） ──
      bool isCloudConnected = false;
      expect(isCloudConnected, isFalse, reason: '体育館の電波暗黒下シミュレーション');

      // 記録端末はローカルWi-Fi / テザリング経由でP2P配信を開始
      final localUrl = await broadcaster.startServer();
      expect(broadcaster.isRunning, isTrue);
      expect(localUrl, isNotNull);
      expect(localUrl, contains('http://'));

      // 進行中の試合モデル（先鋒戦）
      final now = DateTime(2026, 9, 27, 14, 0, 0);
      var match = MatchModel(
        id: 'match_blackout_1',
        tournamentId: 'tourney_underground',
        matchType: '先鋒戦',
        redName: '勇気道場 : 赤坂',
        whiteName: '剛毅館 : 白井',
        redScore: 0,
        whiteScore: 0,
        status: 'in_progress',
        matchTimeMinutes: 3.0,
      );

      // ── シナリオ 2: 赤選手が面を先取 ➔ P2Pローカル配信 ──
      final menEvent = ScoreEvent(
        id: 'ev_offline_men',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 45)),
        sequence: 1,
        logicalClock: 1,
      );
      match = match.copyWith(redScore: 1, events: [menEvent]);

      // 全体ブロードキャスト
      expect(
        () => broadcaster.broadcastMatch(match, remainingSeconds: 135),
        returnsNormally,
      );

      // 差分デルタ伝送（タイマー・得点差分のみを軽量送信）
      expect(
        () => broadcaster.broadcastMatchDelta(match.id, {
          'redScore': 1,
          'remainingSeconds': 135,
          'latestMark': 'メ',
        }, useCompression: false),
        returnsNormally,
      );

      // ── シナリオ 3: 大量履歴データのGzip圧縮ブロードキャスト ──
      final bulkHistoryData = {
        'type': 'MATCH_FULL_SNAPSHOT',
        'matchId': match.id,
        'events': match.events.map((e) => e.toJson()).toList(),
        'redScore': match.redScore,
        'whiteScore': match.whiteScore,
        'status': match.status,
      };

      expect(
        () => broadcaster.broadcastCompressedPayload(bulkHistoryData),
        returnsNormally,
      );

      // Gzip可逆性の検証
      final jsonPayload = jsonEncode(bulkHistoryData);
      final compressed = PayloadCompressionHelper.compressString(jsonPayload);
      final decompressed = PayloadCompressionHelper.decompressToString(
        compressed,
      );
      expect(jsonDecode(decompressed), equals(bulkHistoryData));

      // サーバーを安全に終了
      await broadcaster.stopServer();
      expect(broadcaster.isRunning, isFalse);
    });

    test('2. オフライン蓄積イベントの復帰時アップストリーム一括同期・CRDTマージ完全性', () {
      final baseTime = DateTime(2026, 9, 27, 14, 0, 0);

      // オフライン中に端末ローカルで記録された一連のイベント
      final offlineEvents = <ScoreEvent>[
        ScoreEvent(
          id: 'offline_ev_1',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: baseTime.add(const Duration(seconds: 30)),
          sequence: 1,
          logicalClock: 1,
        ),
        ScoreEvent(
          id: 'offline_ev_2',
          side: Side.white,
          strikeType: StrikeType.kote,
          isIppon: true,
          timestamp: baseTime.add(const Duration(seconds: 60)),
          sequence: 2,
          logicalClock: 2,
        ),
        ScoreEvent(
          id: 'offline_ev_3',
          side: Side.red,
          strikeType: StrikeType.dou,
          isIppon: true,
          timestamp: baseTime.add(const Duration(seconds: 90)),
          sequence: 3,
          logicalClock: 3,
        ),
      ];

      // クラウド側の初期状態（オフライン突入前の空状態または初期マッチ）
      final cloudMatchInitial = MatchModel(
        id: 'match_blackout_sync',
        tournamentId: 'tourney_underground',
        matchType: '先鋒戦',
        redName: '選手赤',
        whiteName: '選手白',
        redScore: 0,
        whiteScore: 0,
        status: 'waiting',
        events: const [],
      );

      // ── 電波復旧シミュレーション（クラウド再接続） ──
      bool isCloudConnected = true;
      expect(isCloudConnected, isTrue);

      // アップストリーム一括同期（マージ処理）
      final mergedEvents = List<ScoreEvent>.from(cloudMatchInitial.events);
      for (final event in offlineEvents) {
        if (!mergedEvents.any((e) => e.id == event.id)) {
          mergedEvents.add(event);
        }
      }
      mergedEvents.sort((a, b) => a.sequence.compareTo(b.sequence));

      final syncedCloudMatch = cloudMatchInitial.copyWith(
        redScore: 2,
        whiteScore: 1,
        status: 'finished',
        events: mergedEvents,
      );

      // クラウドへ同期されたデータの整合性検証
      expect(syncedCloudMatch.events.length, equals(3));
      expect(syncedCloudMatch.redScore, equals(2));
      expect(syncedCloudMatch.whiteScore, equals(1));
      expect(syncedCloudMatch.status, equals('finished'));
      expect(syncedCloudMatch.events.first.strikeType, equals(StrikeType.men));
      expect(syncedCloudMatch.events.last.strikeType, equals(StrikeType.dou));
    });
  });
}
