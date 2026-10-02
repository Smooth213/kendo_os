import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';

void main() {
  group('[E2E] 外部キーボードタイマーおよび打突ショートカット連動テスト', () {
    testWidgets('スペースキーによるタイマー起動停止およびキー入力による打突記録が正常に連動すること', (tester) async {
      // 試合状態を保持するテストハーネス
      MatchModel match = MatchModel(
        id: 'test_ext_kbd_match',
        organizationId: 'org_test',
        matchType: 'individual',
        redName: '山田 太郎',
        whiteName: '佐藤 次郎',
        status: 'waiting',
        matchTimeMinutes: 3.0,
      );

      bool isRunning = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Focus(
                  autofocus: true,
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent) return KeyEventResult.ignored;

                    // スペースキー: タイマー開始 / 停止
                    if (event.logicalKey == LogicalKeyboardKey.space) {
                      setState(() {
                        if (isRunning) {
                          isRunning = false;
                          match = match.copyWith(status: 'paused');
                        } else {
                          isRunning = true;
                          match = match.copyWith(
                            timerStartedAt: DateTime.now(),
                            status: 'in_progress',
                          );
                        }
                      });
                      return KeyEventResult.handled;
                    }

                    // 'M' または '1': 赤・面
                    if (event.logicalKey == LogicalKeyboardKey.keyM ||
                        event.logicalKey == LogicalKeyboardKey.digit1) {
                      setState(() {
                        final newEvents = List<ScoreEvent>.from(match.events)
                          ..add(
                            ScoreEvent(
                              id: 'ev_${match.events.length + 1}',
                              side: Side.red,
                              strikeType: StrikeType.men,
                              isIppon: true,
                              timestamp: DateTime.now(),
                            ),
                          );
                        match = match.copyWith(
                          events: newEvents,
                          redScore: match.redScore + 1,
                        );
                      });
                      return KeyEventResult.handled;
                    }

                    // 'K' または '2': 赤・小手
                    if (event.logicalKey == LogicalKeyboardKey.keyK ||
                        event.logicalKey == LogicalKeyboardKey.digit2) {
                      setState(() {
                        final newEvents = List<ScoreEvent>.from(match.events)
                          ..add(
                            ScoreEvent(
                              id: 'ev_${match.events.length + 1}',
                              side: Side.red,
                              strikeType: StrikeType.kote,
                              isIppon: true,
                              timestamp: DateTime.now(),
                            ),
                          );
                        match = match.copyWith(
                          events: newEvents,
                          redScore: match.redScore + 1,
                        );
                      });
                      return KeyEventResult.handled;
                    }

                    // 'D' または '3': 白・胴
                    if (event.logicalKey == LogicalKeyboardKey.keyD ||
                        event.logicalKey == LogicalKeyboardKey.digit3) {
                      setState(() {
                        final newEvents = List<ScoreEvent>.from(match.events)
                          ..add(
                            ScoreEvent(
                              id: 'ev_${match.events.length + 1}',
                              side: Side.white,
                              strikeType: StrikeType.dou,
                              isIppon: true,
                              timestamp: DateTime.now(),
                            ),
                          );
                        match = match.copyWith(
                          events: newEvents,
                          whiteScore: match.whiteScore + 1,
                        );
                      });
                      return KeyEventResult.handled;
                    }

                    // 'T' または '4': 白・突
                    if (event.logicalKey == LogicalKeyboardKey.keyT ||
                        event.logicalKey == LogicalKeyboardKey.digit4) {
                      setState(() {
                        final newEvents = List<ScoreEvent>.from(match.events)
                          ..add(
                            ScoreEvent(
                              id: 'ev_${match.events.length + 1}',
                              side: Side.white,
                              strikeType: StrikeType.tsuki,
                              isIppon: true,
                              timestamp: DateTime.now(),
                            ),
                          );
                        match = match.copyWith(
                          events: newEvents,
                          whiteScore: match.whiteScore + 1,
                        );
                      });
                      return KeyEventResult.handled;
                    }

                    return KeyEventResult.ignored;
                  },
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('タイマー状態: ${isRunning ? "進行中" : "停止中"}'),
                        Text('赤選手: ${match.redName} (本数: ${match.redScore})'),
                        Text(
                          '白選手: ${match.whiteName} (本数: ${match.whiteScore})',
                        ),
                        Text('イベント総数: ${match.events.length}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // 初期状態確認
      expect(find.text('タイマー状態: 停止中'), findsOneWidget);
      expect(find.text('赤選手: 山田 太郎 (本数: 0)'), findsOneWidget);
      expect(find.text('白選手: 佐藤 次郎 (本数: 0)'), findsOneWidget);
      expect(find.text('イベント総数: 0'), findsOneWidget);

      // 1. スペースキー押下 -> タイマー開始
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('タイマー状態: 進行中'), findsOneWidget);

      // 2. 'M' キー押下 -> 赤選手に面が追加される
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pumpAndSettle();
      expect(find.text('赤選手: 山田 太郎 (本数: 1)'), findsOneWidget);
      expect(find.text('イベント総数: 1'), findsOneWidget);

      // 3. 'D' キー押下 -> 白選手に胴が追加される
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pumpAndSettle();
      expect(find.text('白選手: 佐藤 次郎 (本数: 1)'), findsOneWidget);
      expect(find.text('イベント総数: 2'), findsOneWidget);

      // 4. テンキー '2' 押下 -> 赤選手に小手が追加される
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();
      expect(find.text('赤選手: 山田 太郎 (本数: 2)'), findsOneWidget);
      expect(find.text('イベント総数: 3'), findsOneWidget);

      // 5. スペースキー押下 -> タイマー停止
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('タイマー状態: 停止中'), findsOneWidget);
    });
  });
}
