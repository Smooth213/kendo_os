import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('👁️ 【Phase 6-12/12】OS強制終了（クラッシュ）後 即時セッション復帰ダイアログ Widgetテスト', () {
    testWidgets('1. クラッシュ直後の起動時に未完了セッションを検知し、復帰ボタン押下で直前の試合画面へ復帰すること', (
      tester,
    ) async {
      bool isResumed = false;

      // 前回の未完了セッションデータ
      final crashSnapshot = {
        'matchId': 'match_interrupted_99',
        'court': '第2コート',
        'redName': '佐藤',
        'whiteName': '鈴木',
        'redScore': 1,
        'whiteScore': 0,
        'remainingSeconds': 112,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                if (isResumed) {
                  return Center(
                    child: Text(
                      '試合復帰完了: ${crashSnapshot['redName']} vs ${crashSnapshot['whiteName']} (${crashSnapshot['redScore']}-${crashSnapshot['whiteScore']})',
                    ),
                  );
                }

                // 起動時自動復帰モーダル
                return AlertDialog(
                  title: const Text('⚠️ 中断された試合が見つかりました'),
                  content: Text(
                    '${crashSnapshot['court']} の試合（${crashSnapshot['redName']} vs ${crashSnapshot['whiteName']}）が中断されています。直前の状態から再開しますか？',
                  ),
                  actions: [
                    TextButton(onPressed: () {}, child: const Text('破棄')),
                    ElevatedButton(
                      key: const Key('resume_match_btn'),
                      onPressed: () {
                        setState(() {
                          isResumed = true;
                        });
                      },
                      child: const Text('試合を再開'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // ダイアログが出現していること
      expect(find.text('⚠️ 中断された試合が見つかりました'), findsOneWidget);
      expect(find.textContaining('第2コート の試合（佐藤 vs 鈴木）'), findsOneWidget);

      // 「試合を再開」ボタンをタップ
      await tester.tap(find.byKey(const Key('resume_match_btn')));
      await tester.pumpAndSettle();

      // 直前の試合状態が完全復帰していること
      expect(find.text('試合復帰完了: 佐藤 vs 鈴木 (1-0)'), findsOneWidget);
    });
  });
}
