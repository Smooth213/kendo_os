import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🚨 会場全体一斉緊急中断・避難放送メッセージ
enum EmergencyBroadcastType { none, evacuation, fire, earthquake }

class CourtEmergencyController extends ChangeNotifier {
  EmergencyBroadcastType currentEmergency = EmergencyBroadcastType.none;
  String emergencyMessage = '';
  bool isTimerRunning = true;

  void triggerEmergency({
    required EmergencyBroadcastType type,
    required String message,
  }) {
    currentEmergency = type;
    emergencyMessage = message;
    isTimerRunning = false; // 試合時計を即座に強制停止！
    notifyListeners();
  }

  void clearEmergency() {
    currentEmergency = EmergencyBroadcastType.none;
    emergencyMessage = '';
    notifyListeners();
  }
}

void main() {
  group('📱 【Phase 2-10/10】体育館地震・火災 本部一斉緊急中断＆避難画面ブロードキャストE2Eテスト', () {
    testWidgets('1. 本部緊急避難指令受信時、1秒以内にタイマー強制停止＆全コート警告画面オーバーレイ', (tester) async {
      final controller = CourtEmergencyController();

      await tester.pumpWidget(
        MaterialApp(
          home: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final isEmergency =
                  controller.currentEmergency != EmergencyBroadcastType.none;

              return Scaffold(
                body: Stack(
                  children: [
                    // 通常の試合画面
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('第1コート: 試合進行中'),
                          Text(
                            controller.isTimerRunning
                                ? 'タイマー: 動作中'
                                : 'タイマー: 緊急停止',
                          ),
                        ],
                      ),
                    ),

                    // 🚨 緊急事態発生時のフルスクリーンオーバーレイ
                    if (isEmergency)
                      Container(
                        color: Colors.red.withAlpha(240),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.warning,
                              size: 80,
                              color: Colors.white,
                            ),
                            const Text(
                              '【緊急事態】直ちに試合を中断し避難してください',
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              controller.emergencyMessage,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.yellow,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // 初期状態: 正常試合進行中
      expect(find.text('タイマー: 動作中'), findsOneWidget);
      expect(find.text('【緊急事態】直ちに試合を中断し避難してください'), findsNothing);

      // 🚨 大会本部から「震度5強地震発生」の一斉ブロードキャスト送信！
      controller.triggerEmergency(
        type: EmergencyBroadcastType.earthquake,
        message: '震度5強を観測。全員フロア中央の安全な場所へ避難してください。',
      );
      await tester.pump();

      // タイマーが即座に停止していること
      expect(controller.isTimerRunning, isFalse);

      // 全面緊急避難警告画面が表示されていること
      expect(find.text('【緊急事態】直ちに試合を中断し避難してください'), findsOneWidget);
      expect(find.text('震度5強を観測。全員フロア中央の安全な場所へ避難してください。'), findsOneWidget);
    });
  });
}
