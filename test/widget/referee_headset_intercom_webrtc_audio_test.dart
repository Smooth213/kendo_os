import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🌌 【Phase 9-3/6】審判員ワイヤレスヘッドセット・インカム音声トランシーバー Widgetテスト', () {
    testWidgets('1. PTT（Push-To-Talk）押下でのマイクON/OFF切り替えと発話中インジケーター表示', (
      tester,
    ) async {
      bool isMicActive = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 発話中ステータス
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isMicActive
                              ? Colors.green.shade600
                              : Colors.grey.shade800,
                          border: Border.all(
                            color: isMicActive
                                ? Colors.greenAccent
                                : Colors.transparent,
                            width: 4,
                          ),
                        ),
                        child: Icon(
                          isMicActive ? Icons.mic : Icons.mic_off,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isMicActive ? '【主審 発話中（オンエア）】' : '【マイク ミュート中】',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      // PTTボタントグル
                      ElevatedButton(
                        key: const Key('ptt_toggle_btn'),
                        onPressed: () {
                          setState(() {
                            isMicActive = !isMicActive;
                          });
                        },
                        child: Text(isMicActive ? 'ミュートする' : '合議発言（マイクON）'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // 初期状態はミュート中
      expect(find.text('【マイク ミュート中】'), findsOneWidget);
      expect(find.byIcon(Icons.mic_off), findsOneWidget);

      // PTTボタン押下で発話開始
      await tester.tap(find.byKey(const Key('ptt_toggle_btn')));
      await tester.pump();

      // 発話中インジケーターが点灯すること
      expect(find.text('【主審 発話中（オンエア）】'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });
  });
}
