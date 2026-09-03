import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 📺 HDMIデュアルディスプレイ・プレゼンテーション画面セレクター
class DualDisplayRouter extends StatelessWidget {
  final bool isExternalDisplay;
  final String redName;
  final String whiteName;
  final int redScore;
  final int whiteScore;
  final int remainingSeconds;
  final VoidCallback onScoreRed;

  const DualDisplayRouter({
    super.key,
    required this.isExternalDisplay,
    required this.redName,
    required this.whiteName,
    required this.redScore,
    required this.whiteScore,
    required this.remainingSeconds,
    required this.onScoreRed,
  });

  @override
  Widget build(BuildContext context) {
    if (isExternalDisplay) {
      // 外部HDMIプロジェクター用：巨大スコアボードのみ（操作ボタン一切なし）
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$redName $redScore - $whiteScore $whiteName',
                style: const TextStyle(fontSize: 48, color: Colors.white),
              ),
              Text(
                '残り $remainingSeconds 秒',
                style: const TextStyle(fontSize: 32, color: Colors.amber),
              ),
            ],
          ),
        ),
      );
    }

    // 審判長・手元端末用：フル操作UI（ボタン群あり）
    return Scaffold(
      appBar: AppBar(title: const Text('審判操作パネル')),
      body: Column(
        children: [
          Text('$redName $redScore - $whiteScore $whiteName'),
          ElevatedButton(
            key: const Key('referee_score_red_btn'),
            onPressed: onScoreRed,
            child: const Text('赤 面'),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('📱 【Phase 2-6/10】HDMIデュアルディスプレイ（外部電光掲示板＆手元操作）完全分離テスト', () {
    testWidgets('1. 外部HDMIモニター（isExternalDisplay: true）には操作ボタンが一切描画されないこと', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DualDisplayRouter(
            isExternalDisplay: true,
            redName: '佐藤',
            whiteName: '鈴木',
            redScore: 1,
            whiteScore: 0,
            remainingSeconds: 120,
            onScoreRed: () {},
          ),
        ),
      );

      // スコアとタイマーは表示される
      expect(find.text('佐藤 1 - 0 鈴木'), findsOneWidget);
      expect(find.text('残り 120 秒'), findsOneWidget);

      // 操作ボタンは一切存在しないこと！
      expect(find.byKey(const Key('referee_score_red_btn')), findsNothing);
      expect(find.text('審判操作パネル'), findsNothing);
    });

    testWidgets('2. 手元端末（isExternalDisplay: false）には操作UIが表示されタップ操作可能なこと', (
      tester,
    ) async {
      bool scoreTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DualDisplayRouter(
            isExternalDisplay: false,
            redName: '佐藤',
            whiteName: '鈴木',
            redScore: 1,
            whiteScore: 0,
            remainingSeconds: 120,
            onScoreRed: () => scoreTapped = true,
          ),
        ),
      );

      expect(find.text('審判操作パネル'), findsOneWidget);
      expect(find.byKey(const Key('referee_score_red_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('referee_score_red_btn')));
      await tester.pump();
      expect(scoreTapped, isTrue);
    });
  });
}
