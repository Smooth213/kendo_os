import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_backup_helper.dart';
import 'package:kendo_os/shared/utils/payload_compression_helper.dart';

void main() {
  group('📶 【Phase 9: 通信パケット・同期ペイロード極小化】Gzip 圧縮・解凍ガバナンステスト', () {
    late List<Map<String, dynamic>> dummyTournamentMatches;

    setUp(() {
      // 100試合分のリアルな大会JSONデータを生成
      dummyTournamentMatches = List.generate(100, (index) {
        return {
          'id': 'match_perf_$index',
          'tournamentId': 'tournament_all_japan_2026',
          'matchType': 'individual',
          'category': '一般男子の部 決勝トーナメント',
          'courtName': '第${(index % 4) + 1}試合場',
          'courtId': 'court_${(index % 4) + 1}',
          'roundName': index < 64 ? '1回戦' : (index < 96 ? '2回戦' : '準々決勝'),
          'redName': '選手A_${index}_東京都代表',
          'whiteName': '選手B_${index}_大阪府代表',
          'redScore': index % 3,
          'whiteScore': (index + 1) % 3,
          'status': index % 2 == 0 ? 'completed' : 'in_progress',
          'events': [
            {
              'type': 'ippon',
              'point': 'men',
              'player': 'red',
              'timestamp': 1725350000000 + index * 1000,
              'refereeDecision': 'confirmed',
            },
            {
              'type': 'hansoku',
              'player': 'white',
              'timestamp': 1725350060000 + index * 1000,
            },
            {
              'type': 'ippon',
              'point': 'kote',
              'player': 'white',
              'timestamp': 1725350120000 + index * 1000,
              'refereeDecision': 'confirmed',
            },
          ],
          'metadata': {
            'device': 'iPad Pro 12.9 (6th gen)',
            'recordedBy': '審判主任_佐藤',
            'hall': '日本武道館 メインアリーナ',
            'batteryLevel': 0.85,
          },
        };
      });
    });

    test('100試合の大会同期データが Gzip 圧縮により 70% 以上削減されること', () {
      final jsonString = jsonEncode(dummyTournamentMatches);
      final rawBytes = utf8.encode(jsonString);
      final originalSize = rawBytes.length;

      // 圧縮実行
      final stopwatch = Stopwatch()..start();
      final compressedBytes = PayloadCompressionHelper.compressString(
        jsonString,
      );
      stopwatch.stop();

      final compressedSize = compressedBytes.length;
      final savingsPercent = PayloadCompressionHelper.calculateSavingsPercent(
        originalSize: originalSize,
        compressedSize: compressedSize,
      );

      // ignore: avoid_print
      print(
        '📊 [Payload Compression Benchmark]\n'
        '  - 元データサイズ: ${(originalSize / 1024).toStringAsFixed(2)} KB ($originalSize bytes)\n'
        '  - Gzip圧縮サイズ: ${(compressedSize / 1024).toStringAsFixed(2)} KB ($compressedSize bytes)\n'
        '  - 削減率: ${savingsPercent.toStringAsFixed(2)}%\n'
        '  - 圧縮所要時間: ${stopwatch.elapsedMicroseconds} μs (${stopwatch.elapsedMilliseconds} ms)',
      );

      // 検証: サイズが 70% 以上削減されていること
      expect(
        savingsPercent,
        greaterThanOrEqualTo(70.0),
        reason: '大量大会データは70%以上圧縮されなければならない',
      );
      expect(
        compressedSize,
        lessThan(originalSize * 0.30),
        reason: '圧縮後のサイズは元の30%未満であるべき',
      );
    });

    test('Gzip 圧縮・解凍のラウンドトリップでデータが 100% 完全復元されること (Zero Data Loss)', () {
      final jsonString = jsonEncode(dummyTournamentMatches);

      // 文字列の圧縮・解凍
      final compressedBytes = PayloadCompressionHelper.compressString(
        jsonString,
      );
      final decompressedString = PayloadCompressionHelper.decompressToString(
        compressedBytes,
      );

      expect(decompressedString, equals(jsonString));

      // JSONとしてパースしても元構造と完全一致すること
      final List<dynamic> decodedJson = jsonDecode(decompressedString);
      expect(decodedJson.length, equals(dummyTournamentMatches.length));
      expect(decodedJson[0]['id'], equals('match_perf_0'));
      expect(decodedJson[99]['whiteName'], equals('選手B_99_大阪府代表'));
    });

    test('バイト配列レベルの圧縮・解凍が可逆かつマジックバイトを正しく検出すること', () {
      final rawBytes = utf8.encode(
        'Kendo OS Zero Latency Compression Engine 2026',
      );

      expect(PayloadCompressionHelper.isGzip(rawBytes), isFalse);

      final compressed = PayloadCompressionHelper.compressBytes(rawBytes);
      expect(PayloadCompressionHelper.isGzip(compressed), isTrue);

      final decompressed = PayloadCompressionHelper.decompressBytes(compressed);
      expect(decompressed, equals(Uint8List.fromList(rawBytes)));
    });

    test('Base64 シリアライズ / デシリアライズが完全一致すること (Firestore/WebSocket用)', () {
      final jsonString = jsonEncode(dummyTournamentMatches.take(10).toList());

      final base64Gzip = PayloadCompressionHelper.compressToBase64(jsonString);
      expect(base64Gzip.isNotEmpty, isTrue);

      final restored = PayloadCompressionHelper.decompressFromBase64(
        base64Gzip,
      );
      expect(restored, equals(jsonString));
    });

    test('空配列や極小データの安全なエッジケース処理', () {
      expect(PayloadCompressionHelper.compressBytes([]), isEmpty);
      expect(PayloadCompressionHelper.decompressBytes([]), isEmpty);
      expect(PayloadCompressionHelper.compressString(''), isEmpty);
      expect(PayloadCompressionHelper.decompressToString([]), isEmpty);
      expect(PayloadCompressionHelper.compressToBase64(''), isEmpty);
      expect(PayloadCompressionHelper.decompressFromBase64(''), isEmpty);

      // 非Gzip生データを decompressBytes に渡してもクラッシュせずそのまま返却されること
      final nonGzip = [1, 2, 3, 4, 5];
      expect(
        PayloadCompressionHelper.decompressBytes(nonGzip),
        equals(Uint8List.fromList(nonGzip)),
      );
    });

    test('SyncBackupHelper で Gzip 圧縮バックアップを保存・復元できること', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'kendo_backup_test_',
      );
      final gzFile = File('${tempDir.path}/test_backup.json.gz');

      try {
        final rawData = jsonEncode({'matchCount': 50, 'status': 'all_saved'});
        final compressed = PayloadCompressionHelper.compressString(rawData);
        await gzFile.writeAsBytes(compressed);

        final loaded = await SyncBackupHelper.loadCompressedBackup(gzFile);
        expect(loaded, equals(rawData));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
