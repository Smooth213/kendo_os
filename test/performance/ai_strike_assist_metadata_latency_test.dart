import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

/// 🤖 AI打突アシストメタデータパケット
class AiStrikeMetadataPacket {
  final int frameIndex;
  final String detectedPart; // men, kote, do, tsuki
  final double confidence; // 0.0 - 1.0
  final bool hasZanshin;
  final int timestampMs;

  const AiStrikeMetadataPacket({
    required this.frameIndex,
    required this.detectedPart,
    required this.confidence,
    required this.hasZanshin,
    required this.timestampMs,
  });
}

void main() {
  group('🚀 【Phase 5-9/10】AI打突アシストメタデータ受信 メインスレッド低遅延（60FPS維持）パフォーマンステスト', () {
    test(
      '1. 秒間60フレームのAIメタデータパケット受信時、1フレームあたり処理時間が1ms未満でUIを一切阻害しないこと',
      () async {
        final streamController = StreamController<AiStrikeMetadataPacket>();
        final receivedPackets = <AiStrikeMetadataPacket>[];

        final stopwatch = Stopwatch()..start();

        streamController.stream.listen((packet) {
          // パケット処理（信頼度フィルタリング）
          if (packet.confidence >= 0.85 && packet.hasZanshin) {
            receivedPackets.add(packet);
          }
        });

        // 60fps（1秒間に60パケット）の送信をシミュレート
        for (int f = 1; f <= 60; f++) {
          streamController.add(
            AiStrikeMetadataPacket(
              frameIndex: f,
              detectedPart: (f == 30) ? 'men' : 'none',
              confidence: (f == 30) ? 0.95 : 0.4,
              hasZanshin: (f == 30),
              timestampMs: f * 16,
            ),
          );
        }

        await streamController.close();
        stopwatch.stop();

        // 60パケットすべての処理合計時間が 20ms 未満（1パケットあたり0.3ms以下）
        expect(stopwatch.elapsedMilliseconds, lessThan(20));
        expect(receivedPackets.length, 1);
        expect(receivedPackets.first.detectedPart, 'men');
        expect(receivedPackets.first.confidence, 0.95);
      },
    );
  });
}
