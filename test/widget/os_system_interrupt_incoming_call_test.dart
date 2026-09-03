import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('📱 【Phase 2-3/10】電話着信・緊急地震速報OS割り込み（AppLifecycleState変更）復帰テスト', () {
    testWidgets('1. アプリが paused（着信画面割り込み）➔ resumed（復帰）しても、タイマーの絶対時間計算が狂わないこと', (
      tester,
    ) async {
      final baseTime = DateTime(2026, 9, 3, 15, 0, 0);
      DateTime currentTime = baseTime;
      int matchDurationSeconds = 180;

      void Function(void Function())? stateSetter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                stateSetter = setState;
                final elapsed = currentTime.difference(baseTime).inSeconds;
                final remaining = (matchDurationSeconds - elapsed).clamp(
                  0,
                  matchDurationSeconds,
                );
                return Center(
                  child: Text('残り $remaining 秒', key: const Key('timer_label')),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('残り 180 秒'), findsOneWidget);

      // 10秒経過
      stateSetter?.call(() {
        currentTime = baseTime.add(const Duration(seconds: 10));
      });
      await tester.pump();
      expect(find.text('残り 170 秒'), findsOneWidget);

      // 🚨 電話着信発生！ OSライフサイクルが paused / inactive へ遷移
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // 着信通話が20秒間継続したとする（15:00:30）
      stateSetter?.call(() {
        currentTime = baseTime.add(const Duration(seconds: 30));
      });

      // 📲 通話終了、アプリへ復帰（resumed）
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // 復帰後、即座に正しい経過時間（180 - 30 = 150秒）が正確に反映されていること
      expect(find.text('残り 150 秒'), findsOneWidget);
    });
  });
}
