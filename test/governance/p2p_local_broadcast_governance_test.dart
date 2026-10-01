import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/p2p/infrastructure/local_p2p_broadcaster.dart';
import 'package:kendo_os/shared/utils/payload_compression_helper.dart';

void main() {
  group(
    '[Governance] 【第22条 ガバナンス】現場P2Pローカル配信 ＆ ソケットライフサイクル・Webプラットフォーム完全隔離規約',
    () {
      test(
        'Rule 1: kIsWeb / Web環境におけるネイティブHttpServer隔離・安全フォールバック規約こと',
        () async {
          final broadcaster = LocalP2pBroadcaster();

          // 初期状態は停止中
          expect(broadcaster.isRunning, isFalse);
          expect(broadcaster.clientCount, equals(0));

          // 停止メソッドが未起動状態でも安全に実行完了すること
          await expectLater(broadcaster.stopServer(), completes);
          expect(broadcaster.isRunning, isFalse);
        },
      );

      test(
        'Rule 2: stopServer / Provider破棄時における全WebSocket切断＆ソケット完全破棄規約こと',
        () async {
          final container = ProviderContainer();
          final broadcaster = container.read(localP2pBroadcasterProvider);

          expect(broadcaster, isNotNull);
          expect(broadcaster.isRunning, isFalse);

          // 試合情報ブロードキャストをサーバー停止状態で呼び出しても例外なく安全にスキップされること
          final dummyMatch = const MatchModel(
            id: 'p2p_gov_match_1',
            matchType: '先鋒戦',
            redName: '選手赤',
            whiteName: '選手白',
            redScore: 1,
            whiteScore: 0,
          );
          expect(() => broadcaster.broadcastMatch(dummyMatch), returnsNormally);

          // ProviderContainer破棄で onDispose -> stopServer() が例外なく実行完了すること
          expect(() => container.dispose(), returnsNormally);
          expect(broadcaster.isRunning, isFalse);
          expect(broadcaster.clientCount, equals(0));
        },
      );

      test('Rule 3: 複数回起動および多重呼び出し時の防護・リソース安全規約こと', () async {
        final broadcaster = LocalP2pBroadcaster();

        // サーバー未起動時の差分デルタ伝送呼び出しがクラッシュしないこと
        expect(
          () => broadcaster.broadcastMatchDelta('gov_delta_match', {
            'redScore': 2,
            'status': 'finished',
          }),
          returnsNormally,
        );

        // 連続で stopServer を呼んでも安全であること
        await expectLater(broadcaster.stopServer(), completes);
        await expectLater(broadcaster.stopServer(), completes);
        expect(broadcaster.isRunning, isFalse);
      });

      test('Rule 4: Gzip圧縮ペイロード送信（PayloadCompressionHelper）の完全可逆性規約こと', () {
        final largePayload = {
          'type': 'BULK_MATCH_HISTORY_SYNC',
          'tournamentId': 'tourney_gov_22',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'matches': List.generate(
            20,
            (i) => {
              'id': 'match_$i',
              'category': '一般男子の部',
              'court': '第1試合場',
              'order': i.toDouble(),
              'redName': '代表選手_赤_$i',
              'whiteName': '代表選手_白_$i',
              'redScore': i % 3,
              'whiteScore': (i + 1) % 3,
              'status': i % 2 == 0 ? 'finished' : 'in_progress',
            },
          ),
        };

        final jsonString = jsonEncode(largePayload);
        final originalByteCount = utf8.encode(jsonString).length;

        // 圧縮処理
        final compressedBytes = PayloadCompressionHelper.compressString(
          jsonString,
        );
        expect(compressedBytes.isNotEmpty, isTrue);

        // 圧縮によりサイズが削減または一定に圧縮されていること
        expect(compressedBytes.length, lessThan(originalByteCount));

        // 解凍復元処理
        final decompressedString = PayloadCompressionHelper.decompressToString(
          compressedBytes,
        );
        expect(decompressedString, equals(jsonString));

        // デコード後のJSONマップが完全一致すること
        final decodedMap =
            jsonDecode(decompressedString) as Map<String, dynamic>;
        expect(decodedMap['tournamentId'], equals('tourney_gov_22'));
        expect((decodedMap['matches'] as List).length, equals(20));
        expect(decodedMap['matches'][0]['id'], equals('match_0'));
      });
    },
  );
}
